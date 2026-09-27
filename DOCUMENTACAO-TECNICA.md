# Documentação técnica — Mais 5 Minutinhos

Entregável da seção 19 do SDD (v1.2), gerado a partir do código implementado em 26/09/2026. Atualize este arquivo no mesmo commit de qualquer mudança (seção 29).

- App: iOS 26.0+, só iPhone, Swift 6 + SwiftUI, SwiftData local, AlarmKit, StoreKit 2, Widget extension com a Live Activity da soneca.
- Projeto: `project.yml` (XcodeGen). Testes: 37 testes em Swift Testing (`Tests/`).
- Mapa de pastas e pegadinhas: `CLAUDE.md`. Status de validação por épico: `docs/validacao.md`.

---

## 1. Modelo de dados

Há duas tabelas SwiftData, no schema versionado `SchemaV1` (`Core/Persistence/SchemaV1.swift`) com `MigrationPlan`, que existe desde a v1 ainda sem etapas. As classes e as propriedades estão em português, com os nomes snake_case exatos do spec. Como o SwiftData não exige camelCase, o nome da propriedade já é o nome armazenado, e as colunas no SQLite ficam `ZDIAS_REPETICAO`, `ZSONECA_MINUTOS` e assim por diante (conferido no banco copiado do iPhone).

### `alarme` (0 a 10 linhas)
| Campo | Tipo | Observação |
|---|---|---|
| `id` | UUID, único | **O mesmo UUID é o `Alarm.ID` no AlarmKit.** |
| `hora`, `minuto` | Int | 0–23, 0–59 |
| `dias_repeticao` | [Int] | 1 = domingo … 7 = sábado; vazio = toca uma vez. Gravado em ordem crescente. |
| `rotulo` | String? | nulo sem nome (exibe "Alarme"); máx. 30 caracteres (corte na edição); espaços em branco viram nulo |
| `som` | `SomAlarme` | enum com raw value snake_case (`padrao_iphone`, `bipe_digital`, …) |
| `soneca_ativa` | Bool | default true |
| `soneca_minutos` | Int | 5, 9, 10 ou 15; default 9 |
| `ativo` | Bool | só muda depois do sucesso no AlarmKit |
| `criado_em`, `atualizado_em` | Date | `atualizado_em` muda em toda edição e em todo toggle |

A exclusão é hard delete: primeiro `cancel(id:)` no AlarmKit; se falhar, a linha não é apagada.

### `preferencias` (exatamente 1 linha)
| Campo | Tipo | Default |
|---|---|---|
| `tema_relogio` | `TemaRelogio` | `led_classico` |
| `cor_relogio` | `CorRelogio` | `vermelho` |
| `formato_24h` | Bool | true |
| `mostrar_segundos` | Bool | false |
| `brilho_cabeceira` | Double (0,05–1,0) | **0,30** (era 0,15; mudou no spike) |
| `entrar_automatico` | Bool | true |

`Persistence.ensurePreferences` cria a linha no primeiro launch e, se houver duplicata, mantém a primeira.

**Fora do SwiftData:**
- **Compra:** vem sempre de `Transaction.currentEntitlements` (`PurchaseStore`).
- **Brilho pendente:** chave `bedside.pendingBrightness` no `UserDefaults`. Guarda o brilho da pessoa enquanto o modo cabeceira está aberto, para ser devolvido se o app for fechado à força. É preferência de aparelho, não dado da pessoa.

## 2. Relacionamentos

**Não há relacionamentos.** `alarme` e `preferencias` são independentes:
- a cor e o tema valem para todos os alarmes, lidos na hora de agendar ou exibir;
- nenhum alarme aponta para as preferências;
- não existe histórico de toques.

A única "ligação" é externa: `alarme.id` é também o id do alarme no AlarmKit, e a regra 11.6 mantém os dois lados coerentes.

## 3. Regras que vivem fora da UI

### Agendamento (`Core/Alarm/AlarmScheduler.swift`, regras 11.1 e 11.2)
- É a única porta para o AlarmKit. Contrato da seção 13: `requestAuthorization`, `schedule`, `cancel`, `reconcile` e `observe`, mais `stop`, `snooze` e `systemStates`.
- **Agenda:** sem dias usa `.relative(time, repeats: .never)`, e a próxima ocorrência cai amanhã se a hora já passou. Com dias usa `.weekly([Locale.Weekday])`, com conversão de 1–7 para `Locale.Weekday`.
- **Soneca ativa:**
  - botão secundário "Soneca" com `.countdown`;
  - `countdownDuration.postAlert = soneca_minutos × 60`;
  - apresentação de contagem com título "Soneca".
- **Sem soneca:** nenhum botão secundário.
- **Apresentação:** título = rótulo ou "Alarme"; `tintColor` = cor efetiva do relógio. O texto do botão Soneca é **preto**, porque o sistema pinta o fundo dele com a cor.
- **Botão de parar:** no iOS 26.1+ é do sistema ("deslizar para parar"). No 26.0 o app ainda informa "Parar" (`#available`).
- **Editar:** `schedule` cancela antes quando o id já existe no AlarmKit (cancel + schedule com o mesmo UUID).
- **Chamadas assíncronas:** `AlarmManager` não é `Sendable`, então as chamadas `async` dele ficam em funções `nonisolated static`.

### Ordem das ações (`Features/Alarms/AlarmController.swift`)
- **Salvar:**
  1. Alarme novo com 10 já existentes → copy 15.6.
  2. Se o alarme deve ficar ativo: pede a permissão (só aqui, nunca na abertura) e agenda.
  3. Permissão negada → grava inativo e abre a 10.8.
  4. `maximumLimitReached` → grava inativo e mostra a 15.6.
  5. Outro erro → não grava nada e mostra o erro genérico.
- **Toggle:** agenda ou cancela primeiro e só depois grava `ativo`.
- **Excluir:** cancela e depois apaga.
- **Mudar a cor nos Ajustes:** reagenda os alarmes em `scheduled` para a apresentação usar a cor nova.

### Reconciliação (`Core/Alarm/Reconciliation.swift`, regra 11.6)
Uma função pura, `Reconciliation.plan(rows:system:)`, devolve as ações, e o `AlarmScheduler.reconcile` aplica.

**Quando roda:**
- a cada volta ao primeiro plano;
- quando algum alarme some do AlarmKit enquanto o app está aberto;
- quando a compra muda.

| Situação | Ação |
|---|---|
| ativo, sem repetição, ausente no AlarmKit | `ativo = false` (já tocou) |
| ativo, com repetição, ausente | reagenda |
| inativo, presente | cancela |
| presente sem linha | cancela |
| som pago, estado `scheduled` | reagenda (o som efetivo acompanha a compra; nunca mexe em alarme tocando ou em soneca) |

### Desbloqueio pela compra (`Core/Purchase`, regra 11.7, épico 8.8)
- `PurchaseStore` usa StoreKit 2 para o produto `com.dablab.mais5minutinhos.completo`:
  - direito válido = transação verificada sem `revocationDate`;
  - escuta `Transaction.updates` (compra em outro aparelho, reembolso);
  - `restore()` chama `AppStore.sync()`.
- **O que é grátis (`Entitlements`):** tema LED clássico, cores vermelho e âmbar. Os sons grátis (padrão do iPhone e bipe digital) estão no `SoundCatalog`.
- **Pago sem compra válida:** som, tema e cor caem para os grátis **sem alterar** os campos salvos. Se a compra for restaurada, o que a pessoa escolheu volta.
- **Quando a compra muda:** a `RootView` sincroniza `premiumUnlocked`, reconcilia e reagenda a apresentação.

### Sons (`Core/Sound`, regra 11.3)
- `SoundCatalog.customSoundsEnabled = true`: o spike confirmou que o som do bundle toca no AlarmKit no iOS 26.6.2.
- **Som efetivo:** o padrão do iPhone quando:
  - o som escolhido é o padrão;
  - os sons próprios estão desligados;
  - é um som pago sem compra;
  - o arquivo não está no bundle.
- Os 7 `.caf` foram **sintetizados por código** (`scripts/make-sounds.py`) e aprovados pela direção vintage.
- A prévia usa `AVAudioPlayer` com categoria `.playback`, dura até 5 s e para ao trocar de som ou sair da tela.

### Modo cabeceira (`Features/Bedside`, épico 8.5, regra 11.4)
- **Entrada automática** (`BedsideAutoEntry.shouldEnter`, função pura). Entra quando tudo abaixo é verdade:
  - `entrar_automatico` ligado;
  - app em primeiro plano;
  - aparelho de lado **ou** deitado de costas com a tela para cima, há 2 s;
  - bateria `charging` ou `full`;
  - alarme ativo nas próximas 14 h;
  - nenhuma saída manual nos últimos 10 min.
- A posição vem do acelerômetro (`DevicePositionMonitor`), então funciona com o bloqueio de rotação ligado.
- **`BedsideController`:**
  - guarda e devolve o brilho e o idle timer, inclusive ao sair do primeiro plano;
  - guarda o brilho pendente para o caso de fechamento à força;
  - força a paisagem e segue o lado do aparelho;
  - no toque, brilho de 60% com o botão "Sair" por 5 s;
  - com o alarme tocando por cima, brilho de 60%;
  - aviso de carregador desconectado por 10 s.
- **Anti-marcação:** deslocamento aleatório de até 6 pt a cada minuto.
- **"Soneca até HH:mm":** o AlarmKit não informa quando a soneca termina. A `RootView` calcula o fim quando o alarme entra em `countdown` (agora + `soneca_minutos`).

## 4. Mapa tela → entidades

| Tela | Arquivo | Lê | Escreve |
|---|---|---|---|
| 10.1 Alarmes | `Features/Alarms/AlarmListView.swift` | `alarme`, `preferencias` | `alarme.ativo`, exclusão |
| 10.2 Editar alarme | `Features/Alarms/AlarmEditView.swift` | `alarme` | `alarme` (todos os campos) |
| 10.3 Escolher som | `Features/SoundPicker/SoundPickerView.swift` | — (compra) | `alarme.som` (pelo rascunho da 10.2) |
| 10.4 Modo cabeceira | `Features/Bedside/BedsideView.swift` | `alarme` (próximo ativo), `preferencias` | — |
| 10.5 Alarme tocando | `Features/Ringing/RingingView.swift` | `alarme` (rótulo, soneca), `preferencias` | `alarme.ativo` (toque único parado, pela reconciliação) |
| 10.6 Ajustes | `Features/Settings/SettingsView.swift` | `preferencias`, compra | `preferencias` |
| 10.7 Paywall | `Features/Paywall/PaywallView.swift` | compra (StoreKit) | — |
| 10.8 Permissão negada | `Features/Alarms/PermissionDeniedView.swift` | — | — |
| 10.9 Sistema | AlarmKit + `Widget/SnoozeLiveActivity.swift` | metadata (`rotulo`, `cor`) | — |
| 10.10 Como usar | `Features/Settings/HowToUseView.swift` | — | — |

A raiz é `App/RootView.swift`. Ela observa o AlarmKit, reconcilia, avalia a entrada automática, sincroniza a compra e apresenta a 10.4, a 10.5 e a 10.8.

## 5. Lógica das ações principais por tela

- **10.1:**
  - "+" abre a 10.2 vazia, com a hora atual; fica desabilitado com 10 alarmes, com a copy 15.6 no rodapé.
  - Tocar na hora ou no texto de uma linha abre a edição.
  - O toggle chama `setActive`; o estado só muda depois do sucesso no AlarmKit.
  - Deslizar a linha exclui (cancela e depois apaga).
  - "Dormir" abre a 10.4.
  - A engrenagem abre a 10.6.
- **10.2:**
  - Salvar segue a ordem da seção 3; permissão negada grava inativo e abre a 10.8.
  - "Dias úteis" e "Todos os dias" preenchem os dias.
  - A duração da soneca fica desabilitada com a soneca desligada.
  - "Excluir alarme" só aparece na edição.
  - Rodapé: "O alarme toca no volume de toque do iPhone."
- **10.3:**
  - Tocar num som toca a prévia e escolhe o som.
  - Som pago sem compra: toca a prévia **e** abre o paywall, sem escolher.
  - O padrão do iPhone não tem prévia; mostra a legenda.
- **10.4:**
  - Relógio no tema, cor, formato e segundos das preferências.
  - Coluna com o dia, o próximo alarme ("07:00 amanhã") ou "Soneca até" / "Nenhum alarme ativo" / aviso de carregador.
  - Toque: brilho de 60% e "Sair" por 5 s.
  - "Sair" registra a saída manual, para a regra dos 10 min.
- **10.5:**
  - Soneca chama `countdown(id:)` e fecha; volta à 10.4 com "Soneca até".
  - Parar chama `stop(id:)` e fecha; um alarme de toque único fica inativo pela reconciliação.
  - Um toque, com haptic.
- **10.6:**
  - Tema ou cor paga sem compra abre o paywall.
  - O slider de brilho mostra a prévia na tela enquanto arrasta.
  - Mudar a cor reagenda os alarmes.
  - "Comprar" abre o paywall; "Restaurar compra" chama `PurchaseStore.restore()`; com compra, aparece "Comprado".
  - "Privacidade" abre a Política de Privacidade da Dab Lab (`AppLinks.privacyPolicy`), exigida dentro do app pela Guideline 5.1.1.
- **10.7:**
  - "Comprar por R$ 19,90" usa o `displayPrice`.
  - Sem rede: botão desabilitado e copy 15.7.
  - Fecha sozinho quando a compra é liberada.
- **Live Activity:** `zzz` + rótulo, contagem regressiva e "Parar" (`StopAlarmIntent`, roda no processo do app).

## 6. Divergências em relação ao spec (inclusive o spike 8.1)

| # | Spec | Implementado | Por quê / quem decidiu |
|---|---|---|---|
| 1 | Botão "Parar" configurado na apresentação do sistema (15.2, 10.9); princípio 0.1 "um toque" | No iOS 26.1+ o sistema mostra "deslizar para parar", sem texto nem cor do app | `stopButton` foi descontinuado no SDK 26.1. Alexandre aceitou em 26/09/2026. Dentro do app e na Live Activity continua um toque. |
| 2 | Soneca do sistema com fundo a 22% e texto na cor (design) | Fundo na cor, texto preto | O `AlarmButton` só define a cor do texto; o fundo é o `tintColor`. |
| 3 | `brilho_cabeceira` default 0,15 | 0,30 | Teste no quarto escuro (Alexandre). SDD v1.2 e `.dbml` atualizados. |
| 4 | Opacidade do relógio 0,42/0,85/1,0 (design) | Sempre 1,0; só o brilho da tela controla a luz | Ler a hora sem tocar (Alexandre). |
| 5 | 11.4 "aparelho em paisagem" | De lado **ou** deitado de costas (tela para cima), pelo acelerômetro, depois de 2 s parado | Decisão de Alexandre; o bloqueio de rotação impede o `UIDevice.orientation`. SDD v1.2 atualizado. |
| 6 | Tela 10.5 no brilho da noite | Com o modo cabeceira aberto, o brilho sobe para 60% enquanto toca | A tela ficava escura demais no teste. O spec não define o valor. |
| 7 | Pergunta 25.3 (volume) | Segue o volume de toque → dica na 10.2: "O alarme toca no volume de toque do iPhone." | Resposta do spike; copy aprovada por Alexandre. |
| 8 | Pergunta 25.2 (origem dos sons) | 7 sons sintetizados por código (`scripts/make-sounds.py`), originais | Aprovados por Alexandre (direção vintage). |
| 9 | Copy de erro do AlarmKit (não existe na seção 15) | "Erro no alarme" / "Não foi possível salvar. Tente de novo." / "OK" | Escolhida por Alexandre. |
| 10 | 10.3: tocar no cadeado toca a prévia; "Usar" abre o paywall (spec) × tocar abre o paywall (design) | Toca a prévia **e** abre o paywall | Escolha de Alexandre. |
| 11 | Símbolo `alarm.slash` na 10.8 (design) | `alarm` + `line.diagonal` | `alarm.slash` não existe no SF Symbols. |
| 12 | Tela "Como usar" não existia | Tela 10.10 + copy 15.11 | Pedido de Alexandre; SDD v1.2. |
| 13 | Pasta de design `mais5-design-system/` | `cabeceira-design-system/` | Nome da pasta entregue. |
| 14 | Comportamento com reembolso para tema/cor não definido | Tema/cor pagos caem para LED/vermelho sem alterar `preferencias` | Mesmo tratamento dos sons (11.6), princípio 0.5. |
| 15 | — | Abertura do app (`UILaunchScreen`) em preto | Evita clarão branco à noite (princípio 0.3). |
| 16 | — | "Restaurar compra" sem nada a restaurar não mostra mensagem | A seção 15 não tem copy para isso. |
| 19 | 11.6: "som pago sem compra válida → reagenda com padrão" a cada reconciliação | O som efetivo é reaplicado **só quando a compra muda** (último estado aplicado guardado em `UserDefaults`); todas as operações no AlarmKit passam por uma fila (uma de cada vez) | Bug do build 2 (27/09/2026): reagendar a cada abertura + reconciliação disparada pelo sumiço momentâneo do alarme criavam operações concorrentes no mesmo id; o alarme podia terminar sem agendamento e não tocar. |
| 18 | — | `ITSAppUsesNonExemptEncryption = NO` no Info.plist | Só frameworks da Apple; evita o "Missing Compliance" a cada build. |
| 17 | — | Botão de volume durante o toque interrompe o alarme | Comportamento do sistema observado no spike; o app não controla. |

### Resultado do spike 8.1 (resumo; completo em `docs/spike-alarmkit.md`)
Testado num iPhone 13 mini com iOS 26.6.2, Xcode 26.1.1 / SDK 26.1.

| Item | Resultado |
|---|---|
| Som próprio do bundle, com o app fechado, no silencioso (P1) | ✅ `customSoundsEnabled = true` |
| `alerting` com o app aberto → tela em ≤ 1 s (P2) | ✅ 82 ms |
| `stop`/`countdown` pela tela do app cortam o som (P3) | ✅ na hora |
| Assinaturas conferidas no SDK (P4) | ✅ com as divergências 1 e 2 |
| Contagem da soneca na tela bloqueada e volta a tocar após 5 min | ✅ |

### Ainda a verificar em aparelho antes do envio (seção 22)
Veja `docs/validacao.md`:
- itens do 8.3 que Alexandre optou por pular;
- entrada automática e aviso de carregador (8.5);
- toque único parado → inativo e alarme sem soneca (8.6);
- compra em sandbox/TestFlight, restauração em aparelho novo e paywall em modo avião (8.8);
- o roteiro completo com Foco Dormir, reinício do aparelho e soneca 2×.
