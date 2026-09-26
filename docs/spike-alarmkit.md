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
- A contagem da soneca apareceu (Live Activity).
- 999664D2 (bipe_digital.caf, agendado às 12:38:29 para 12:40) tocou em seguida, como esperado.

| Critério 8.1 | Resultado |
|---|---|
| Toca com app fechado, no silencioso, com botões na tela bloqueada | |
| Som é o arquivo do bundle (P1) | ✅ com o app aberto (iOS 26.6.2); falta confirmar com o app fechado |
| App recebe `alerting` e mostra a tela em ≤ 1 s (P2) | ✅ 82 ms |
| Parar na tela do app silencia em ≤ 1 s (P3) | |
| Soneca mostra contagem e volta a tocar depois de 5 min | ✅ contagem apareceu; falta confirmar se volta a tocar depois de 5 min |
| Volume segue toque ou mídia (25.3) | |

Decisão: `customSoundsEnabled` = _preencher_
