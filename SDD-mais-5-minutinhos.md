# SDD — Mais 5 Minutinhos (despertador de cabeceira para iPhone)

| Campo | Valor |
|---|---|
| Versão do documento | 1.1 — nome do app definido |
| Produto | **Mais 5 Minutinhos** — nome na App Store: "Mais 5 Minutinhos – Despertador"; nome sob o ícone: "5 Minutinhos" (ver 24.2) |
| Responsável de produto | Alexandre Siqueira — Dab Lab |
| Status | pronto para revisão |
| Data | 26/09/2026 (v1.0 em 23/09/2026) |
| Agente consumidor | Claude Code |
| Arquivos irmãos | `modelo-mais-5-minutinhos.dbml`, `prompt-design-mais-5-minutinhos.md`, `prompt-implementacao-mais-5-minutinhos.md` |

## Como usar este documento

Este é a fonte única de verdade do app. O Claude Code implementa a partir dele; o Claude Design desenha as telas a partir do `prompt-design-mais-5-minutinhos.md`, e o material exportado do Claude Design vira a referência definitiva de UI (pasta `mais5-design-system/` no repositório).

Ordem recomendada:
1. Revisar a seção 24 (Assunções) e responder a seção 25 (Perguntas abertas). **Assunção não revisada vira verdade no minuto em que o agente começa a codar.**
2. Rodar o Claude Design com o prompt de design e escolher uma opção por tela.
3. Colar o prompt de implementação no Claude Code. O épico 8.1 (spike técnico) é um portão: se ele falhar, o spec é revisado antes de seguir.

Numeração das seções é estável — referencie sempre por número ("regra 11.3").

---

## 0. Princípios não-negociáveis

1. **Um toque para parar, um toque para soneca.** Quando o alarme toca, a pessoa sonolenta resolve com um único toque em um alvo enorme. Nenhum desafio, captcha, puzzle ou confirmação.
2. **O alarme é do sistema, não do app.** Todo alarme é agendado pelo AlarmKit e toca com o app fechado, no modo silencioso e com Foco ativo. O app nunca depende de ficar aberto ou de áudio em background para acordar ninguém.
3. **A noite é escura e calma.** O modo cabeceira nunca acende a tela acima do brilho escolhido, nunca mostra notificação própria, cor clara de fundo ou animação chamativa durante a noite.
4. **Sem conta, sem nuvem, sem rede.** 100% local, funciona em modo avião. Nenhum dado sai do aparelho.
5. **Simplicidade antes de recurso.** Na dúvida entre adicionar uma opção ou decidir por padrão, decide-se por padrão.

## 1. Visão e problema

Mais 5 Minutinhos transforma o iPhone num despertador de mesa: à noite mostra um relógio grande e escuro, e de manhã o alarme toca com o mesmo comportamento do despertador nativo (inclusive no silencioso), com dois botões gigantes — Soneca e Parar. Público: qualquer pessoa que dorme com o iPhone carregando ao lado da cama, com atenção especial a quem tem dificuldade com telas pequenas (idosos, pessoas sem óculos à noite).

Os apps de referência da loja (Alarm Clock for Me, Clock+) resolvem isso, mas carregam anúncios, assinaturas, clima, lanterna, sons de dormir e dezenas de opções. O Mais 5 Minutinhos faz só o relógio e o alarme. O nome aponta para o diferencial: o botão gigante de soneca.

**Anti-escopo:** não é app de sono (sem rastreamento, sem sons para dormir, sem ciclos de sono), não é timer de cozinha, não mostra clima, não tem lanterna, não tem alarme com desafio para desligar, não sincroniza com o app Relógio da Apple.

## 2. Personas e cenário de uso

- **Pessoa que acorda cedo para trabalhar:** coloca o iPhone deitado no carregador, quer ver a hora sem pegar o aparelho e confiar que o alarme toca.
- **Pessoa idosa:** enxerga mal à noite, se atrapalha com o slider do alarme nativo; precisa de alvo de toque grande e texto enorme.

**Momento mais difícil:** 6h58, quarto escuro, pessoa sem óculos e meio dormindo, alarme tocando. É ele que define a tela 10.5 e a regra 11.5.

## 3. Escopo do MVP

### Dentro
- Criar, editar, ativar/desativar e excluir alarmes (até 10).
- Repetição por dias da semana ou toque único.
- Soneca configurável por alarme (liga/desliga + duração).
- Escolha de som por alarme: som padrão de alarme do iPhone ou um dos 7 sons próprios do app (ver 11.3).
- Modo cabeceira: relógio em tela cheia, paisagem, escuro, com brilho reduzido e tela sem apagar.
- Tela de alarme tocando dentro do app com botões gigantes de Soneca e Parar, quando o app está aberto.
- Apresentação do sistema (tela bloqueada, Dynamic Island) com botões Parar e Soneca configurados, e Live Activity de contagem da soneca.
- 4 temas de relógio × 5 cores, formato 24h/12h, mostrar segundos.
- Compra única que libera temas e sons extras.

### Fora
| Item | Destino | Motivo |
|---|---|---|
| Usar a lista de toques do sistema (Radar, Apex etc.) | Descartado | Não existe API pública; os arquivos são da Apple e não podem ser copiados para o app (ver 11.3). |
| Importar som próprio do usuário (arquivo/música) | v2 (seção 28) | Depende de o `Library/Sounds` funcionar de forma confiável com AlarmKit — relatos de bug no iOS 26.0 (ver 23). |
| Tocar música do Spotify/Apple Music | Descartado | AlarmKit só toca arquivo local; exigiria o app aberto a noite toda. |
| Apple Watch | v2 | Depende de medir adoção do iPhone. |
| iPad | Descartado no MVP | Padrão do portfólio: iPhone só. |
| Clima, lanterna, sons para dormir, timer | Descartado | Anti-escopo (seção 1). |
| Alarme gradual de volume (fade-in) | v2 | AlarmKit não expõe controle de volume; só via arquivo de som com crescendo embutido (o som "Despertar suave" já faz isso). |

## 4. Arquitetura

| Decisão | Escolha | Por quê | Alternativa descartada |
|---|---|---|---|
| Plataforma | iOS nativo, iPhone só | Padrão do portfólio; AlarmKit é Swift-only | React Native com binding de AlarmKit — camada extra sem ganho |
| Linguagem/UI | Swift 6 + SwiftUI | Mesmo stack dos apps standalone (Estante, Hora do Remédio) | UIKit |
| Persistência | SwiftData, local | Sem backend, sem custo fixo | Core Data; UserDefaults (não escala para lista de alarmes) |
| Alarmes | **AlarmKit** (`AlarmManager`) | Toca com app fechado, no silencioso e com Foco; UI de sistema na tela bloqueada | `UNUserNotificationCenter` (não fura o silencioso, some com Foco); áudio em background com app aberto (frágil, bateria, rejeição na revisão) |
| Soneca com contagem | Widget extension com `ActivityConfiguration(for: AlarmAttributes<Mais5Metadata>.self)` | Obrigatória para exibir a contagem da soneca na tela bloqueada/Dynamic Island | Sem Live Activity — o sistema exige para countdown |
| Compra | StoreKit 2, IAP não-consumível | Padrão do portfólio | Assinatura (contraria o posicionamento) |
| Projeto | XcodeGen (`project.yml` versionado, `.xcodeproj` não) | Padrão do portfólio | — |
| Deployment target | **iOS 26.0** | AlarmKit não existe antes | iOS 18 com fallback de notificação — dois caminhos de alarme, dobra os testes e entrega alarme pior |
| Identidade de conta | Mesmo bundle ID prefix e Apple Developer Team dos apps já publicados | Padrão do portfólio | — |

**Premissas a validar (épico 8.1):**
- P1. `AlertConfiguration.AlertSound.named(_:)` toca o arquivo do bundle no iOS atual. Há relatos no fórum da Apple de que no iOS 26.0 o som próprio era trocado por um bipe de erro; é preciso confirmar em aparelho físico na versão corrente do iOS.
- P2. Com o app em primeiro plano, `AlarmManager.shared.alarmUpdates` entrega o estado `alerting` a tempo de o app mostrar a tela 10.5.
- P3. Chamar `stop(id:)` e `countdown(id:)` a partir da tela do app para o som do sistema imediatamente.
- P4. Assinaturas exatas das APIs (`AlarmPresentation.Alert`, `AlarmButton`, `Alarm.Schedule.relative`, `AlarmConfiguration`) contra o SDK instalado — a API mudou entre betas; o agente confere na documentação do Xcode, não de memória.

**Onde o código vive:** repositório GitHub privado `mais-5-minutinhos-ios`. Deploy: TestFlight → App Store.

## 5. Perfis e permissões

Um único perfil (dono do aparelho). Sem matriz de permissões.

Permissões do sistema:
| Permissão | Chave Info.plist | Quando pedir | Se negada |
|---|---|---|---|
| AlarmKit | `NSAlarmKitUsageDescription` | Ao salvar o primeiro alarme (não na abertura) | Alarme não é salvo como ativo; tela 10.8 explica e leva aos Ajustes do iPhone |

Não há notificações, localização, microfone nem fotos.

## 6. Autenticação

Não há login. Seção não se aplica.

## 7. Modelo de dados

SwiftData local. **Convenção:** as classes `@Model` e suas propriedades espelham o banco e ficam em português (`Alarme`, `Preferencias`). Se o SwiftData exigir camelCase na propriedade (`diasRepeticao`), usar `@Attribute(originalName: "dias_repeticao")` para o armazenamento ficar em português `snake_case`. Todo o resto do código em inglês.

```
Preferencias (1 linha)        Alarme (0..10 linhas)
```
Não há relação entre as entidades.

### 7.1 `alarme`
| Campo | Tipo | Nulo | Default | Regra |
|---|---|---|---|---|
| `id` | UUID | não | gerado | PK. **O mesmo UUID é o `Alarm.ID` no AlarmKit.** |
| `hora` | Int | não | — | 0–23 |
| `minuto` | Int | não | — | 0–59 |
| `dias_repeticao` | [Int] | não | `[]` | Valores 1–7 (1 = domingo, padrão `Calendar.weekday`). Vazio = toca uma vez. |
| `rotulo` | String | sim | nulo | Nulo quando a pessoa não deu nome; sistema exibe "Alarme". Máx. 30 caracteres. |
| `som` | `som_alarme` | não | `padrao_iphone` | Ver 11.3 |
| `soneca_ativa` | Bool | não | `true` | |
| `soneca_minutos` | Int | não | 9 | Só 5, 9, 10 ou 15 |
| `ativo` | Bool | não | `true` | |
| `criado_em` | Date | não | agora | |
| `atualizado_em` | Date | não | agora | Atualizado a cada edição |

Enum `som_alarme`: `padrao_iphone`, `bipe_digital`, `campainha_classica`, `sino`, `despertar_suave`, `passaros`, `piano_manha`, `radio_relogio`.

Exclusão: **hard delete** (não há histórico referenciando). Excluir remove do SwiftData e cancela no AlarmKit (`cancel(id:)`), nesta ordem: AlarmKit primeiro; se falhar, não apaga localmente e mostra erro.

### 7.2 `preferencias` (singleton)
| Campo | Tipo | Nulo | Default | Regra |
|---|---|---|---|---|
| `id` | UUID | não | gerado | Uma única linha, criada no primeiro launch |
| `tema_relogio` | `tema_relogio` | não | `led_classico` | |
| `cor_relogio` | `cor_relogio` | não | `vermelho` | |
| `formato_24h` | Bool | não | `true` | |
| `mostrar_segundos` | Bool | não | `false` | |
| `brilho_cabeceira` | Double | não | 0.15 | 0.05–1.0 |
| `entrar_automatico` | Bool | não | `true` | Ver 11.4 |

Enum `tema_relogio`: `led_classico`, `digital_fino`, `grande_negrito`, `flip`.
Enum `cor_relogio`: `vermelho`, `ambar`, `verde`, `azul`, `branco`.

A compra **não** é armazenada no SwiftData: o estado vem sempre de `Transaction.currentEntitlements`.

Migrations: `VersionedSchema` + `SchemaMigrationPlan` desde a v1, mesmo com um único schema.

## 8. Épicos e critérios de aceite

### 8.1 Spike técnico AlarmKit (portão)
Objetivo: provar P1–P4 em iPhone físico antes de construir telas.
Fluxo: app mínimo com um botão que agenda alarme para 1 minuto depois, com som próprio `bipe_digital.caf`, botão Parar e Soneca (5 min).
Critérios:
- [ ] Com app fechado e iPhone no silencioso, o alarme toca e aparece na tela bloqueada com os botões "Parar" e "Soneca".
- [ ] O som ouvido é o arquivo do bundle, não o padrão nem um bipe de erro. Se falhar: registrar a versão do iOS, usar só `padrao_iphone` e marcar os sons próprios como bloqueados (flag `customSoundsEnabled = false`) — o resto do MVP segue.
- [ ] Com app aberto, o app recebe `alerting` e mostra uma tela de teste em até 1 s.
- [ ] Tocar em Parar na tela do app silencia o som em até 1 s.
- [ ] Tocar em Soneca inicia contagem visível na Dynamic Island/tela bloqueada e o alarme volta a tocar após 5 min.
- [ ] Resultado registrado em `docs/spike-alarmkit.md` (versão do iOS, aparelho, o que funcionou).

### 8.2 Fundação
Projeto XcodeGen, SwiftData com schema versionado, singleton de `preferencias`, `CLAUDE.md`, estrutura de pastas (seção 18), Widget extension vazia. `CFBundleDisplayName` = "5 Minutinhos".
Critérios:
- [ ] `xcodegen generate` + build limpo sem warnings de concorrência.
- [ ] Primeiro launch cria exatamente 1 linha de `preferencias`.
- [ ] Nome sob o ícone aparece como "5 Minutinhos", sem corte.

### 8.3 Lista e edição de alarmes
Fluxo: Lista (10.1) → "+" → Editar (10.2) → Salvar → alarme aparece na lista ativo e agendado. Estado vazio na lista. Erro de permissão leva à 10.8.
Critérios:
- [ ] Salvar alarme cria linha no SwiftData **e** alarme no AlarmKit com o mesmo UUID.
- [ ] Desligar o toggle chama `cancel(id:)`; ligar reagenda. O toggle só muda de estado depois do sucesso no AlarmKit.
- [ ] Editar hora/dias/som/soneca reagenda (cancel + schedule) com o mesmo UUID.
- [ ] Com 10 alarmes, o botão "+" fica desabilitado e mostra a copy 15.6.
- [ ] Lista ordenada por hora, depois minuto; subtítulo mostra dias ("Todos os dias", "Dias úteis", "Fins de semana", "Seg, Qua, Sex" ou "Uma vez").
- [ ] Reconciliação da regra 11.6 roda a cada vez que o app volta ao primeiro plano.

### 8.4 Seletor de som
Tela 10.3. Tocar num som toca prévia de até 5 s (AVAudioPlayer, categoria `.playback`, toca mesmo no silencioso). Sons pagos mostram cadeado se não houver compra; tocar no cadeado ainda permite ouvir a prévia, mas "Usar" abre o paywall.
Critérios:
- [ ] A prévia para ao sair da tela ou ao tocar em outro som.
- [ ] `padrao_iphone` toca uma prévia do som do sistema (se não houver como reproduzir o som padrão do sistema fora do AlarmKit, mostrar legenda "Som de alarme do iPhone" sem prévia — decisão do spike).
- [ ] Se `customSoundsEnabled == false`, só `padrao_iphone` aparece.

### 8.5 Modo cabeceira
Tela 10.4. Entrada manual (botão "Dormir" na lista) ou automática (regra 11.4).
Critérios:
- [ ] Ao entrar: `isIdleTimerDisabled = true`, brilho vai para `brilho_cabeceira`, orientação paisagem, barra de status escondida.
- [ ] Ao sair: idle timer e brilho voltam ao valor anterior à entrada.
- [ ] Mostra hora no tema/cor escolhidos, dia da semana, e o próximo alarme ativo ("07:00 amanhã"); sem alarme ativo mostra copy 15.4.
- [ ] Toque na tela sobe o brilho para 60% por 5 s e mostra o botão "Sair" nesse intervalo.
- [ ] Anti-marcação de tela: o bloco do relógio desloca até 6 pt em posição aleatória a cada minuto.
- [ ] Se o carregador for desconectado no modo cabeceira, mostra aviso discreto (15.5) por 10 s; não sai do modo.

### 8.6 Alarme tocando
Duas apresentações:
- **App fechado/bloqueado:** apresentação do sistema (AlarmKit) com título = `rotulo` ou "Alarme", botão Parar (`stop`), botão secundário Soneca (`secondaryButtonBehavior = .countdown`, `postAlert = soneca_minutos × 60`), cor = `cor_relogio`. Sem soneca ativa, sem botão secundário.
- **App em primeiro plano (inclusive no modo cabeceira):** tela 10.5 do app, em cima de tudo.
Critérios:
- [ ] Tela 10.5 aparece em até 1 s do início do alarme com o app aberto.
- [ ] Botão Soneca ocupa no mínimo 55% da altura útil; Parar no mínimo 25%; ambos com área de toque ≥ 88 pt.
- [ ] Um toque em Soneca chama `countdown(id:)`, fecha a tela e volta ao modo cabeceira mostrando "Soneca até 07:09".
- [ ] Um toque em Parar chama `stop(id:)` e fecha a tela.
- [ ] Alarme de toque único, depois de parado, fica com `ativo = false` na lista.
- [ ] Live Activity de soneca mostra contagem regressiva e botão Parar.

### 8.7 Ajustes e temas
Tela 10.6. Prévia ao vivo do relógio no topo.
Critérios:
- [ ] Mudar tema/cor/formato reflete na prévia imediatamente e no modo cabeceira.
- [ ] Temas e cores bloqueados (regra 11.7) mostram cadeado e abrem o paywall.

### 8.8 Compra única
Tela 10.7. StoreKit 2, produto não-consumível `<prefixo>.mais5minutinhos.completo`.
Critérios:
- [ ] Compra libera temas, cores e sons imediatamente, sem reiniciar.
- [ ] "Restaurar compra" funciona em aparelho novo.
- [ ] Sem rede, o paywall mostra erro 15.7 e não trava.
- [ ] Se a compra for reembolsada, alarmes com som pago continuam tocando com `padrao_iphone` (reagendados na reconciliação).

## 9. Fluxo principal ponta a ponta

1. Primeira abertura → Lista vazia (10.1) com copy 15.1.
2. "+" → Editar (10.2) → escolhe 07:00, dias úteis → Salvar.
3. Sistema pede permissão de alarme → aceita → alarme agendado. (Exceção: nega → 10.8.)
4. À noite, coloca o iPhone deitado no carregador → entra no modo cabeceira (10.4).
5. 07:00 → se a tela ainda está no app: tela 10.5; se bloqueou: apresentação do sistema.
6. Soneca → contagem → 07:09 toca de novo → Parar.
7. Exceção: iPhone reiniciado durante a noite — o AlarmKit mantém o alarme; o app não precisa estar aberto.

## 10. Inventário de telas

Perfil único. Tabela lida/escrita entre colchetes.

- **10.1 Alarmes (tela inicial)** — lista de alarmes com hora grande, subtítulo de dias/rótulo e toggle; botão "+" (topo), botão "Dormir" (base, fixo), acesso a Ajustes (topo). Estado vazio. Swipe para excluir. [lê/escreve `alarme`]
- **10.2 Editar alarme** (sheet) — seletor de hora (roda nativa grande), dias da semana (7 botões redondos + atalhos Dias úteis/Todos), rótulo, som (abre 10.3), soneca (toggle + 5/9/10/15), botão Excluir (só na edição). [escreve `alarme`]
- **10.3 Escolher som** — lista com prévia; itens pagos com cadeado. [escreve `alarme.som`]
- **10.4 Modo cabeceira** — relógio tela cheia paisagem; linha inferior com dia da semana e próximo alarme; botão Sair que aparece ao toque. [lê `alarme`, `preferencias`]
- **10.5 Alarme tocando** — hora atual, rótulo, botão Soneca gigante e Parar grande. [escreve `alarme.ativo` em toque único]
- **10.6 Ajustes** — prévia do relógio; tema; cor; 24h; segundos; brilho da cabeceira (slider com prévia); entrar automaticamente; compra/restaurar; sobre/privacidade. [lê/escreve `preferencias`]
- **10.7 Paywall** (sheet) — o que libera, preço, comprar, restaurar. [não lê tabelas]
- **10.8 Permissão de alarme negada** (sheet) — explicação e botão para Ajustes do iPhone.
- **10.9 Apresentação do sistema** (não é tela do app; o design escolhe só textos, ícones SF Symbols e cor) — tela bloqueada/Dynamic Island tocando e em soneca.

## 11. Regras de negócio

### 11.1 Agendamento
| Regra | Valor | Onde |
|---|---|---|
| Máximo de alarmes | 10 | App (lista) |
| `dias_repeticao` vazio | `Alarm.Schedule.relative` com `repeats: .never` (próxima ocorrência da hora) | App → AlarmKit |
| `dias_repeticao` preenchido | `repeats: .weekly([dias])` | App → AlarmKit |
| Alarme criado para hora já passada hoje, sem repetição | toca amanhã | AlarmKit (comportamento de `.relative`) |
| AlarmKit retorna `maximumLimitReached` | mostra copy 15.6, não salva ativo | App |

### 11.2 Soneca
| Regra | Valor |
|---|---|
| Durações permitidas | 5, 9, 10, 15 min |
| Default | 9 min |
| Limite de sonecas seguidas | Sem limite (igual ao nativo) |
| `soneca_ativa = false` | Apresentação sem botão secundário; tela 10.5 mostra só Parar (ocupando 60%) |

### 11.3 Sons — como a questão dos toques foi resolvida
| Situação | Decisão |
|---|---|
| Toques do sistema (Radar, Apex, Sinos…) | **Não disponíveis.** Não há API pública para listar nem tocar os toques do iOS, e copiar os arquivos da Apple para o app viola direitos autorais e as regras da loja. |
| "Toque nativo" | O item **"Padrão do iPhone"** usa `AlertSound.default` — é o som de alarme do próprio sistema. É o default de todo alarme novo. |
| Variedade | 7 sons próprios do app, originais, criados para o Mais 5 Minutinhos (não imitam toques da Apple). |
| Formato | `.caf`, Linear PCM, 44,1 kHz, mono, ≤ 30 s, desenhados para repetir sem emenda audível. |
| Origem dos arquivos | Produzidos para o app (GarageBand, ou gerador de efeitos sonoros com licença comercial) ou biblioteca CC0. Licença de cada arquivo registrada em `Resources/Sounds/LICENSES.md`. |
| Grátis | `padrao_iphone`, `bipe_digital` |
| Pagos | `campainha_classica`, `sino`, `despertar_suave` (crescente em 20 s), `passaros`, `piano_manha`, `radio_relogio` |
| Nomes exibidos | Padrão do iPhone, Bipe digital, Campainha clássica, Sino, Despertar suave, Pássaros, Piano da manhã, Rádio-relógio |
| Som próprio falhou no spike (8.1) | `customSoundsEnabled = false`; todos os alarmes usam `padrao_iphone`; sons pagos saem da oferta do paywall |

### 11.4 Entrada automática no modo cabeceira
Entra quando **todas** forem verdadeiras: `entrar_automatico = true`, app em primeiro plano, aparelho em paisagem, bateria `charging` ou `full`, e há ao menos 1 alarme ativo nas próximas 14 h. Não entra automaticamente se a pessoa saiu manualmente do modo nos últimos 10 min.

### 11.5 Tela de alarme tocando
Um toque, sem confirmação, sem "segurar para parar". Soneca é o botão maior e fica em cima; Parar embaixo. Nenhuma outra ação na tela.

### 11.6 Reconciliação SwiftData × AlarmKit (a cada volta ao primeiro plano)
| Estado encontrado | Ação |
|---|---|
| `ativo = true`, sem repetição, ausente no AlarmKit | Já tocou → `ativo = false` |
| `ativo = true`, com repetição, ausente no AlarmKit | Reagenda |
| `ativo = false`, presente no AlarmKit | Cancela no AlarmKit |
| Presente no AlarmKit sem linha no SwiftData | Cancela no AlarmKit |
| Som pago sem compra válida | Reagenda com `padrao_iphone` (sem alterar o campo `som`, para voltar se a compra for restaurada) |

### 11.7 O que a compra libera
| Grátis | Pago |
|---|---|
| Tema `led_classico`, cores `vermelho` e `ambar` | Todos os 4 temas e 5 cores |
| Sons `padrao_iphone` e `bipe_digital` | Os 6 sons restantes |
| Alarmes, soneca, modo cabeceira — **sem limite** | — |

Preço: R$ 19,90, compra única (ver assunção 24.3).

### 11.8 Hora e fuso
Relógio usa `Date()` e o fuso atual do sistema; mudança de fuso ou horário de verão é tratada pelo AlarmKit (hora local). Formato 12h mostra "AM/PM" pequeno ao lado.

## 12. Máquina de estado do alarme (espelho do AlarmKit)

`agendado → tocando → (soneca → tocando)* → parado`. De `agendado` pode ir para `cancelado` (toggle ou exclusão). O app não guarda o estado; lê de `alarmUpdates`. Único efeito persistido: `ativo = false` para toque único parado.

## 13. Contratos de módulos internos

- `AlarmScheduler` — `requestAuthorization() async -> Bool`, `schedule(_ alarme: Alarme) async throws`, `cancel(id: UUID) async throws`, `reconcile(_ alarmes: [Alarme]) async`, `observe() -> AsyncStream<AlarmEvent>`.
- `SoundCatalog` — lista de sons com `id`, nome exibido, arquivo, `isPremium`; `alertSound(for:) -> AlertConfiguration.AlertSound`.
- `PurchaseStore` — `isUnlocked: Bool` (observável), `purchase()`, `restore()`.
- `BedsideController` — entra/sai do modo, guarda e restaura brilho/idle timer.
- `Mais5Metadata: AlarmMetadata` — carrega `rotulo` e `cor` para a Live Activity.

## 15. Copy (final)

- 15.1 Lista vazia: título "Nenhum alarme" / texto "Toque em + para criar o primeiro."
- 15.2 Botões do alarme: **"Soneca"** e **"Parar"**. Sistema: título = rótulo ou "Alarme".
- 15.3 Botão da lista: "Dormir".
- 15.4 Modo cabeceira sem alarme: "Nenhum alarme ativo".
- 15.5 Carregador desconectado: "O iPhone não está carregando".
- 15.6 Limite: "Você chegou a 10 alarmes. Apague um para criar outro."
- 15.7 Paywall sem rede: "Sem conexão. Tente de novo quando estiver online."
- 15.8 Permissão negada: título "Alarmes desligados" / texto "Para o Mais 5 Minutinhos tocar mesmo no silencioso, permita alarmes nos Ajustes do iPhone." / botão "Abrir Ajustes".
- 15.9 `NSAlarmKitUsageDescription`: "O Mais 5 Minutinhos usa alarmes para tocar na hora certa, mesmo com o iPhone no silencioso."
- 15.10 Paywall: título "Mais 5 Minutinhos completo" / "Todos os temas, cores e sons. Pague uma vez, use para sempre." / "Restaurar compra".

## 16. Direção visual

Definida pelo Claude Design a partir do `prompt-design-mais-5-minutinhos.md` (ele propõe opções e Alexandre escolhe). Restrições fixas:
- Telas de configuração (10.1–10.3, 10.6–10.8) usam componentes nativos do iOS: List inset grouped, Section, estilos tipográficos semânticos, SF Symbols, Dynamic Type. Modo escuro e claro.
- Telas noturnas (10.4, 10.5) sempre em fundo preto puro (#000, economia em OLED), independente do modo do sistema.
- Cor de destaque do app = cor do relógio escolhida; cores semânticas (vermelho de excluir) são as do sistema.
- Dígitos de 7 segmentos do tema `led_classico` desenhados em SwiftUI (Shape) ou fonte com licença para app — nunca imagem rasterizada.
- O nome tem humor; o tom do app pode acompanhar isso em detalhes pequenos (ícone, paywall), mas as telas noturnas continuam sóbrias.

Livre para o agente: animações de transição, ícone do app (vem do Claude Design).

## 17. Requisitos não-funcionais

| Item | Alvo |
|---|---|
| Abertura a frio | < 1 s em iPhone 12 |
| Modo cabeceira, 8 h, brilho 15% | Não deve impedir a carga de subir (medir no spike com carregador de 20 W) |
| Tamanho do binário | < 25 MB (sons inclusos) |
| Acessibilidade | Dynamic Type até AX5 nas telas de configuração; VoiceOver lê hora e estado de cada alarme; alvos ≥ 44 pt (≥ 88 pt na 10.5) |
| Idiomas | pt-BR no MVP; strings em String Catalog prontas para en |
| Offline | 100% |
| Compatibilidade | iOS 26.0+, iPhone |

## 18. Convenções de código e repositório

- **Idioma:** modelos SwiftData (o "banco") em português; código, variáveis e arquivos em inglês.
- **Comentários obrigatórios:** toda função, tipo e extensão tem cabeçalho em português explicando o que faz, entradas, saídas e a regra do spec que implementa (ex.: `// Reconcilia SwiftData com AlarmKit (regra 11.6)`). Lógica não óbvia leva comentário inline.
- **Pastas:**
```
App/  Features/Alarms  Features/SoundPicker  Features/Bedside  Features/Ringing  Features/Settings  Features/Paywall
Core/Alarm (AlarmScheduler, Mais5Metadata)  Core/Sound  Core/Purchase  Core/Persistence
Resources/Sounds (+ LICENSES.md)  Widget/ (Live Activity)  docs/
```
- `CLAUDE.md` na raiz com convenções, mapa da arquitetura, comando de build e pegadinhas (AlarmKit só em aparelho físico; o UUID do alarme é compartilhado; brilho precisa ser restaurado).
- README com setup (`xcodegen generate`), bundle ID e produto IAP.
- Sem variáveis de ambiente/segredos.

## 19. Documentação técnica (entregável final)

Ao terminar, gerar `DOCUMENTACAO-TECNICA.md` em português com: (1) modelo de dados explicado; (2) relacionamentos (aqui: nenhum, explicar); (3) regras que vivem fora da UI — reconciliação, agendamento, desbloqueio por compra; (4) mapa tela → entidades; (5) lógica de cada ação principal por tela; (6) divergências em relação ao spec (inclusive resultado do spike 8.1). Atualizado no mesmo commit de toda mudança.

## 20. Privacidade

Nenhum dado coletado, nenhum SDK de terceiros, nenhuma rede além da App Store (compra). Rótulo da App Store: "Dados não coletados". Dados ficam no SwiftData do aparelho e somem ao apagar o app.

## 22. Testes

- Unitários: cálculo de "próximo alarme" (virada de semana, toque único, fuso), texto de dias (8.3), reconciliação 11.6 com `AlarmScheduler` falso, regra 11.4.
- Manual em aparelho físico (obrigatório, AlarmKit não é confiável no simulador): roteiro do spike repetido antes do envio à revisão, incluindo silencioso, Foco Dormir ativo, app fechado, reinício do aparelho e soneca 2×.

## 23. Riscos

| Risco | Impacto | Prob. | Mitigação |
|---|---|---|---|
| Som próprio no AlarmKit toca bipe de erro (relatado no iOS 26.0) | Alto — metade do valor pago | Média | Spike 8.1 como portão; fallback `customSoundsEnabled = false` e paywall só com temas |
| Pessoa espera os toques do iPhone e se frustra | Médio | Alta | "Padrão do iPhone" como default e primeiro da lista; descrição da loja clara |
| StandBy do iOS já faz relógio de cabeceira | Médio | Alta | Diferencial é alarme com botões gigantes + simplicidade; mensagem da loja foca nisso |
| Alarme não mostra UI com o app em primeiro plano (relatos de fórum) | Alto | Média | Tela 10.5 própria via `alarmUpdates` (P2) |
| Revisão da Apple questiona uso de AlarmKit | Baixo | Baixa | Uso é exatamente o caso previsto pela Apple (despertador) |
| Marcação de tela OLED | Baixo | Baixa | Deslocamento por minuto, brilho baixo |
| Nome já usado por outro app na loja | Médio | Baixa | Buscar "Mais 5 Minutinhos" na App Store e reservar o nome no App Store Connect antes da implementação |

## 24. Assunções declaradas

- 24.1 **Deployment target iOS 26.** Quem está em iOS 18 não instala. Se quiser atender iOS 18, avisa — exige um segundo caminho com notificações, mais fraco.
- 24.2 **Nome sob o ícone "5 Minutinhos"** (`CFBundleDisplayName`). "Mais 5 Minutinhos" tem 17 caracteres e seria cortado na tela de início ("Mais 5 Minu…"). Se preferir o nome completo mesmo cortado, é só trocar. Nome de loja: "Mais 5 Minutinhos – Despertador".
- 24.3 **Compra única de R$ 19,90** liberando temas, cores e sons — alarmes e modo cabeceira sempre grátis e ilimitados. Alternativa: 100% grátis como o Hora do Remédio.
- 24.4 **Máximo de 10 alarmes.**
- 24.5 **Soneca e Parar com um toque, sem "segurar".** Se preferir proteger o Parar contra toque acidental, dá para exigir segurar 1 s.
- 24.6 **Só iPhone, pt-BR.**
- 24.7 **Entrada automática no modo cabeceira ligada por padrão.**
- 24.8 **Soneca padrão de 9 min** (igual ao despertador nativo), mesmo o nome dizendo 5. A pessoa pode escolher 5 min no alarme. Se quiser alinhar com o nome, o default vira 5.

## 25. Perguntas abertas (o agente pergunta em vez de assumir)

- 25.1 ~~Nome de loja~~ — **resolvido na v1.1:** "Mais 5 Minutinhos – Despertador". Falta só o subtítulo da loja (até 30 caracteres), que sai na ficha da App Store.
- 25.2 Origem dos 7 sons próprios (produzir vs. biblioteca CC0) e quem produz. Decide: Alexandre, antes do épico 8.4. Até lá o agente usa arquivos-placeholder marcados.
- 25.3 O volume do alarme do AlarmKit segue o volume de toque ou o de mídia? Descobrir no spike; se seguir o de toque, a tela 10.2 ganha uma dica.

## 26. Definition of Done

- [ ] Todos os critérios de 8.1–8.8 verificados em iPhone físico.
- [ ] Modelos SwiftData em português conforme seção 7; nada fora do padrão.
- [ ] Todas as funções e tipos com comentário de cabeçalho em português.
- [ ] `DOCUMENTACAO-TECNICA.md` gerado e conferido contra o app.
- [ ] `CLAUDE.md` e README atualizados.
- [ ] `Resources/Sounds/LICENSES.md` com a licença de cada som.
- [ ] Rótulo de privacidade "Dados não coletados".
- [ ] UI conforme a pasta `mais5-design-system/`.

## 27. Próximos passos

1. Revisar seções 24 e 25.
2. Buscar o nome na App Store e reservá-lo no App Store Connect.
3. Rodar `prompt-design-mais-5-minutinhos.md` no Claude Design; escolher uma opção por tela; exportar para `mais5-design-system/`.
4. Criar repositório `mais-5-minutinhos-ios`.
5. Colar `prompt-implementacao-mais-5-minutinhos.md` no Claude Code — ele começa pelo spike 8.1 e para para você validar no aparelho.

## 28. Roadmap

- **v2 — Som importado pelo usuário:** importar arquivo de áudio (Arquivos/gravação), converter para `.caf` ≤ 30 s e salvar em `Library/Sounds`; depende de confirmar que o AlarmKit toca sons dessa pasta na versão corrente do iOS.
- **v2 — Apple Watch:** parar/soneca pelo pulso.
- **v2 — Rádio-relógio com fade-in de volume:** exige alternativa ao AlarmKit para controle de volume; reavaliar.

## 29. Protocolo de mudanças incrementais

1. Commit de checkpoint antes de qualquer mudança.
2. Colar só o trecho novo ou um spec adicional da feature.
3. Escrever como diff: "o app já existe e funciona".
4. Listar o que **não** pode mudar.
5. Pedir a lista de arquivos a criar/alterar antes do código e aprovar.
6. Revisar o `git diff` contra o plano; reverter o que passou do escopo.
7. Atualizar `DOCUMENTACAO-TECNICA.md` e `CLAUDE.md` no mesmo commit.

Modelo:
```
O app Mais 5 Minutinhos já existe e funciona (ver CLAUDE.md e DOCUMENTACAO-TECNICA.md).
Mudança: [descrever]. Seções do spec afetadas: [x.y].
Não altere: AlarmScheduler, reconciliação 11.6, telas [..].
Antes de codar, liste os arquivos que vai criar/alterar e espere minha aprovação.
Atualize DOCUMENTACAO-TECNICA.md e CLAUDE.md no mesmo commit.
```

## Anexo — Fontes (consultadas em 23/09/2026)

- Apple — WWDC25 "Wake up to the AlarmKit API": https://developer.apple.com/videos/play/wwdc2025/230/
- Apple — `AlertConfiguration.AlertSound.named(_:)`: https://developer.apple.com/documentation/activitykit/alertconfiguration/alertsound/named(_:)
- Apple — `UNNotificationSound` (formatos e limite de 30 s): https://developer.apple.com/documentation/usernotifications/unnotificationsound
- Fórum Apple — sons próprios no AlarmKit (iOS 26.0): https://developer.apple.com/forums/thread/802620 e https://developer.apple.com/forums/thread/788836
