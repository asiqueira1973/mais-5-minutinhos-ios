# Spike técnico AlarmKit (épico 8.1)

Status: **aguardando teste em aparelho físico**

| Campo | Valor |
|---|---|
| Aparelho | iPhone 13 mini (iPhone14,4) |
| Versão do iOS | 26.6.2 |
| Xcode / SDK | Xcode 26.1.1 (17B100) / iOS SDK 26.1 |
| Data do teste | 26/09/2026 |

## Premissa P4: assinaturas conferidas no SDK instalado (26/09/2026)

Fonte: `AlarmKit.swiftmodule/arm64e-apple-ios.swiftinterface` do iOS SDK 26.1.

| API | Assinatura no SDK | Diferença em relação ao spec |
|---|---|---|
| `AlarmPresentation.Alert` | `init(title:secondaryButton:secondaryButtonBehavior:)` (iOS 26.1+) e `init(title:stopButton:secondaryButton:secondaryButtonBehavior:)`, **descontinuado no 26.1** | No iOS 26.1+ o botão de parar é desenhado pelo sistema: o app não define texto nem cor dele. O app usa `#available(iOS 26.1, *)` e, no 26.0, ainda informa "Parar". |
| `AlarmButton` | `init(text:textColor:systemImageName:)` | Só define a cor do texto; não há cor de fundo por botão. |
| `Alarm.Schedule.relative` | `.relative(.init(time: .init(hour:minute:), repeats: .never / .weekly([Locale.Weekday])))` | Os dias são `Locale.Weekday`, não `Int`. O app converte 1 = domingo → `.sunday`. |
| Duração da soneca | `Alarm.CountdownDuration(preAlert:postAlert:)` no `AlarmConfiguration` | Confere com o spec (`postAlert = soneca_minutos × 60`). |
| `AlarmConfiguration` | `init(countdownDuration:schedule:attributes:stopIntent:secondaryIntent:sound:)` | Confere. |
| `stop` / `countdown` / `cancel(id:)` | síncronos, `throws` | O spec não dizia; só `schedule` e `requestAuthorization` são `async`. |
| `alarms` | propriedade que **lança** erro (`throws`) | — |
| `AlarmManager` | classe **não `Sendable`** | Com Swift 6, as chamadas `async` ficam em funções `nonisolated`. |
| Erros | `AlarmManager.AlarmError.maximumLimitReached` | Confere com a regra 11.1. |

## Roteiro de teste

No app, os horários do log aparecem com milissegundos, para medir os limites de 1 s.

1. Abrir o app e tocar em **Pedir permissão** → **Permitir**.
2. **P1 (som próprio) + app fechado + silencioso:** tocar em **Agendar com som próprio**, fechar o app (deslizar para cima no alternador), ligar o modo silencioso e bloquear a tela. Na hora marcada:
   - [ ] tocou mesmo no silencioso;
   - [ ] a tela bloqueada mostra título, botão de parar e **Soneca**;
   - [ ] o som é o **bipe provisório** (4 bipes agudos rápidos), e não o som padrão nem um bipe de erro.
3. **Soneca:** tocar em **Soneca** na tela bloqueada:
   - [ ] a contagem regressiva aparece na tela bloqueada e na Dynamic Island (o 13 mini não tem Dynamic Island: conferir só a tela bloqueada);
   - [ ] o botão **Parar** da Live Activity funciona, ou deixar a contagem acabar e confirmar que o alarme volta a tocar depois de 5 min.
4. **Comparação:** repetir o passo 2 com **Agendar com som padrão do iPhone** para ter referência do som do sistema.
5. **P2 + P3 (app aberto):** agendar e deixar o app aberto na tela:
   - [ ] a tela de teste (Soneca/Parar) aparece sozinha em até 1 s. No log, comparar `estado …: alerting` com `tela de teste exibida`;
   - [ ] **Parar** silencia em até 1 s;
   - [ ] em outro teste, **Soneca** na tela do app inicia a contagem.
6. **Pergunta 25.3:** durante um toque, mexer nos botões de volume. O volume do alarme segue o volume de **toque** (Ajustes › Sons) ou o de **mídia**?
7. **Opcional (NFR 17):** deixar no carregador de 20 W e ver se a carga sobe com o app aberto.

## Resultado

Teste parcial em 26/09/2026, 12:38–12:40, com o app aberto:

- FA23CD52: `alerting` às 12:39:00,047; tela de teste exibida às 12:39:00,129 (**82 ms**).
- `countdown(id:)` chamado às 12:39:10,757; estado `countdown` às 12:39:10,777 (**20 ms**).
- O som ouvido foi o **bipe provisório** do bundle, e não o som padrão nem um bipe de erro.
- A Live Activity da soneca aparece na tela bloqueada (print às 12:40): `zzz` + rótulo na cor, contagem regressiva grande (3:13) e botão "Parar" vermelho com texto preto, conforme o design (tela 9). Com mais de um alarme, o sistema empilha as atividades sob o nome "5 Minutinhos" (12:42: duas sonecas simultâneas, som próprio e som padrão).
- O botão **Parar** da Live Activity (`StopAlarmIntent`) encerrou a soneca e a atividade sumiu da tela bloqueada.
- 12:45: alarme com `bipe_digital.caf`, app fechado e chave do silencioso ligada → tocou com o bipe do bundle. Apertar o botão de volume para cima interrompeu o toque.
- `cancel(id:)` em todos os alarmes ("Cancelar todos") também remove as Live Activities de soneca em andamento. A exclusão e o toggle da seção 8.3 não deixam contagem órfã.
- 999664D2 (bipe_digital.caf, agendado às 12:38:29 para 12:40) tocou em seguida, como esperado.

| Critério 8.1 | Resultado |
|---|---|
| Toca com app fechado, no silencioso, com botões na tela bloqueada | ✅ tocou às 12:45 com o app fechado e no silencioso. Tela bloqueada às 12:49: título + "5 Minutinhos", botão secundário grande na cor e **"slide to stop" do sistema** (ver divergências) |
| Som é o arquivo do bundle (P1) | ✅ com o app aberto e com o app fechado no silencioso (iOS 26.6.2) |
| App recebe `alerting` e mostra a tela em ≤ 1 s (P2) | ✅ 82 ms |
| Parar na tela do app silencia em ≤ 1 s (P3) | ✅ parcial: **Soneca** na tela do app (sobre o modo cabeceira) cortou o som na hora; falta repetir com **Parar** |
| Soneca mostra contagem e volta a tocar depois de 5 min | ✅ contagem apareceu; falta confirmar se volta a tocar depois de 5 min |
| Volume segue toque ou mídia (25.3) | ✅ segue o **volume de toque** (12:49: toque baixo e mídia alta → tocou baixo). Apertar o botão de volume durante o toque interrompe o alarme (comportamento do sistema) |

Decisão: `customSoundsEnabled` = **true** (som próprio funciona no iOS 26.6.2).

## Divergências e achados para o spec

1. **Parar na tela bloqueada é "deslizar para parar" (slide to stop)**, desenhado pelo sistema a partir do iOS 26.1 (`stopButton` descontinuado). Contraria o princípio 0.1 só na apresentação do sistema. Na tela 10.5 do app e na Live Activity, Parar continua sendo um toque. Não há como o app mudar isso. **Aceito por Alexandre em 26/09/2026.**
2. **O botão secundário (Soneca) usa `tintColor` como fundo.** Com `textColor` igual à cor, o texto ficou invisível (bug do spike, corrigido para `.black`). O design previa Soneca com fundo a 22% e texto na cor; na apresentação do sistema o resultado é fundo na cor e texto preto.
3. **Volume segue o de toque (25.3).** Pelo spec, a tela 10.2 ganha uma dica, e o texto dela não existe na seção 15. **Copy definida por Alexandre (26/09/2026):** "O alarme toca no volume de toque do iPhone."
4. Os textos do sistema ("slide to stop", "Show less") seguem o idioma do aparelho (o de teste está em inglês).

## Decisões para o épico 8.5 tomadas durante o spike

- **Regra 11.4, "aparelho em paisagem":** vale **de lado na horizontal (com suporte)** ou **deitado de costas na mesa (tela para cima)**. Decisão de Alexandre em 26/09/2026.
- **Detecção da posição:** a maioria das pessoas usa o bloqueio de rotação, e com ele ligado `UIDevice.orientation` não informa a paisagem. A detecção usa o acelerômetro (CoreMotion, sem permissão). A interface do modo cabeceira é sempre forçada para paisagem (`requestGeometryUpdate`).
- A prévia do modo cabeceira (layout 4C, tema LED) foi aprovada visualmente no iPhone às 12:57.
- **Brilho com o alarme tocando no modo cabeceira:** o teste de 12:59 mostrou que a tela 10.5 ficava a 15%, escura demais. Enquanto o alarme toca, o brilho sobe para 60% (mesmo valor do toque, regra 8.5) e volta ao `brilho_cabeceira` depois de Soneca ou Parar. O spec não define esse valor; a decisão segue os princípios 0.1 e 0.3.
- **O brilho não era devolvido ao sair do app:** o iOS mantém o brilho definido pelo app mesmo depois que ele vai para segundo plano. O `BedsideController` agora devolve brilho e idle timer ao sair do primeiro plano e reaplica o brilho da noite na volta. Fechar o app à força ou reinstalar com o modo aberto ainda deixa o brilho baixo, e não há API para evitar isso.
- Teste combinado (sobre o modo cabeceira): tela 10.5 clara (60%), Soneca cortou o som na hora, volta ao relógio escurecido, toque clareia por 5 s e minimizar o app devolveu o brilho normal. ✅
