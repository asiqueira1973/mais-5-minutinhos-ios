# CLAUDE.md — Mais 5 Minutinhos

Despertador de cabeceira para iPhone: à noite, relógio grande e escuro; de manhã, alarme do sistema (AlarmKit) com Soneca e Parar gigantes. 100% local, sem rede, sem conta.

## Fontes de verdade
- `SDD-mais-5-minutinhos.md`: spec. Referencie sempre pelo número ("regra 11.3"). A seção 0 é a regra de desempate.
- `modelo-mais-5-minutinhos.dbml`: modelo de dados (espelho da seção 7).
- `cabeceira-design-system/`: referência definitiva de UI. O spec cita `mais5-design-system/`; a pasta real tem este nome.
- `docs/spike-alarmkit.md`: resultado do spike 8.1 e decisões tomadas durante ele.
- `docs/mudancas-pendentes-spec.md`: pedidos que ainda não entraram no spec. Não implemente nada daí sem o texto aprovado.
- `DOCUMENTACAO-TECNICA.md`: modelo, regras fora da UI, mapa de telas, ações e **divergências do spec** (seção 19). Atualize no mesmo commit de toda mudança.
- `docs/validacao.md`: o que cada épico já verificou (iPhone, simulador, testes) e o que falta em aparelho antes do envio.

## Estado
MVP completo (épicos 8.1–8.8 + tela 10.10). Falta o roteiro em aparelho antes do envio (`docs/validacao.md`) e a publicação (skill `app-store-dablab`).

## Decisões já tomadas (não reabrir)
- Deployment target iOS 26.0, usando `#available(iOS 26.1, *)` onde o SDK 26.1 mudou o AlarmKit.
- Telas escolhidas no design: 4C "Coluna" (modo cabeceira) e 5A "Blocos" (alarme tocando). Ícone A (LED "05").
- Telas de configuração sempre em modo escuro (`.preferredColorScheme(.dark)`). Telas noturnas em preto puro.
- Nome sob o ícone: "5 Minutinhos". Grátis: tema `led_classico`, cores `vermelho` e `ambar` (regra 11.7).
- `customSoundsEnabled = true`: som próprio funciona no AlarmKit (spike 8.1, iOS 26.6.2).
- `brilho_cabeceira` default 0,30. LED do modo cabeceira sempre com a cor cheia (o brilho da tela controla a luz).
- Modo cabeceira automático (11.4): de lado na horizontal **ou** deitado de costas (tela para cima). Posição detectada pelo acelerômetro, porque funciona com o bloqueio de rotação ligado.
- Dica de volume na tela 10.2: "O alarme toca no volume de toque do iPhone."
- Sons próprios: os 7 são **sintetizados por código** (`scripts/make-sounds.py`) e foram aprovados como sons do app pela direção vintage (resposta da 25.2).
- Tema/cor pagos sem compra válida (ex.: reembolso) caem para LED clássico/vermelho **sem alterar** `preferencias`, igual à regra 11.6 dos sons.
- Mudar a cor nos Ajustes reagenda os alarmes em `scheduled`, porque a cor da apresentação do sistema é gravada no agendamento.
- "Restaurar compra" sem nada a restaurar não mostra mensagem (não há copy na seção 15); o botão só volta ao normal.
- Som pago sem compra na 10.3: toca a prévia **e** abre o paywall, sem escolher o som.
- Erro genérico do AlarmKit (a seção 15 não define): título "Erro no alarme", texto "Não foi possível salvar. Tente de novo.", botão "OK".
- Permissão negada ao salvar: o alarme é gravado **inativo** e abre a 10.8. `maximumLimitReached`: gravado inativo + copy 15.6. Outro erro: nada é gravado e a sheet continua aberta.

## Convenções (seção 18)
- **Idioma:** modelos SwiftData em português, com propriedades no snake_case exato do spec (`dias_repeticao`, `soneca_minutos`). Enums do banco: `SomAlarme`, `TemaRelogio`, `CorRelogio`, com raw value snake_case. Todo o resto do código, variáveis e arquivos em inglês.
- **Comentários obrigatórios:** toda função, tipo e extensão tem cabeçalho em português com o que faz, entradas, saídas e a regra do spec (com número). Lógica não óbvia leva comentário inline.
- **Copy:** literal da seção 15. Não invente texto; pergunte.
- **Perguntas abertas (seção 25):** pergunte em vez de assumir.
- **Swift 6** com concorrência estrita. O build tem que sair sem nenhum warning.

## Mapa da arquitetura
```
App/                    entrada (MaisCincoMinutinhosApp), AppDelegate (trava de orientação), Info.plist gerado
Core/Alarm/             Mais5Metadata (AlarmMetadata), StopAlarmIntent (Parar da Live Activity)
Core/Persistence/       DatabaseEnums, SchemaV1 (Alarme, Preferencias), Persistence (container + singleton), MigrationPlan
Core/Sound/, Core/Purchase/          épicos 8.4 e 8.8
Features/Bedside/       ClockView (4 temas: LED em Canvas, flip em placas, texto medido e ampliado), LEDClockView, BedsideController (brilho/idle/orientação que segue o aparelho), BedsideView (4C), BedsideAutoEntry (regra 11.4 pura + DevicePositionMonitor com acelerômetro)
Core/Alarm/             + AlarmScheduler (única porta para o AlarmKit), Reconciliation (plano puro da 11.6), NextAlarm/ClockFormat, Weekdays
Core/Sound/             SoundCatalog (sons, grátis/pagos, customSoundsEnabled, som efetivo), SoundPreviewPlayer (prévia ≤ 5 s, .playback)
App/RootView            lista + cabeceira por cima + 10.5 + 10.8; observa `alarmUpdates` e reconcilia ao voltar ao primeiro plano
Features/Alarms/        AlarmListView (10.1), AlarmEditView (10.2), PermissionDeniedView (10.8), AlarmController (ordem AlarmKit → SwiftData)
Features/Ringing/       RingingView (10.5, opção 5A): proporções do design em pontos (retrato 100/430/197, paisagem 44/200/97), relógio no tema
Features/Settings/      ClockPalette (cores do relógio), SettingsView (10.6)
Core/Purchase/          Entitlements (regra 11.7: grátis/pago, tema e cor efetivos sem compra), PurchaseStore (StoreKit 2, no ambiente via `.environment(store)`)
Features/SoundPicker/   SoundPickerView (10.3)
Features/Paywall/       PaywallView (10.7): preço do StoreKit, sem rede → 15.7, fecha sozinho ao liberar
Features/Settings/HowToUseView  Como usar (10.10, copy 15.11)
MaisCincoMinutinhos.storekit    StoreKit local (loja BRA) do scheme e dos testes (StoreKitTest)
Resources/Sounds/       .caf (Linear PCM 44,1 kHz mono ≤ 30 s) + LICENSES.md
Widget/                 extension com a Live Activity da soneca (AlarmAttributes<Mais5Metadata>)
Tests/                  Swift Testing (seção 22)
docs/                   spike 8.1, validação por épico, mudanças pedidas fora do spec
scripts/                make-app-icon.swift (ícone A), make-sounds.py (7 sons sintéticos)
```

## Comandos
```bash
xcodegen generate                      # o .xcodeproj não é versionado
xcodebuild -project MaisCincoMinutinhos.xcodeproj -scheme MaisCincoMinutinhos -destination 'generic/platform=iOS' -derivedDataPath build/DerivedData -allowProvisioningUpdates build
xcodebuild test -project MaisCincoMinutinhos.xcodeproj -scheme MaisCincoMinutinhos -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath build/DerivedData
xcrun devicectl device install app --device <id> build/DerivedData/Build/Products/Debug-iphoneos/MaisCincoMinutinhos.app
```

## Pegadinhas
- **AlarmKit só se valida em aparelho físico.** Critérios que dependem dele pedem teste do Alexandre no iPhone.
- **O UUID do alarme é compartilhado:** `alarme.id` no SwiftData == `Alarm.ID` no AlarmKit. Editar = `cancel` + `schedule` com o mesmo id.
- **`AlarmManager` não é `Sendable`:** chame os métodos `async` dele (`schedule`, `requestAuthorization`) de funções `nonisolated`. `stop`/`countdown`/`cancel` são síncronos e `alarms` lança erro.
- **iOS 26.1+:** o botão de parar da tela bloqueada é do sistema ("deslizar para parar") e o app não controla. O botão secundário usa `tintColor` como fundo, então o texto dele precisa ser preto.
- **Dias da semana:** o AlarmKit usa `Locale.Weekday`, e o banco usa 1–7 (1 = domingo).
- **Brilho precisa ser restaurado:** o iOS mantém o brilho definido pelo app mesmo fora dele. O `BedsideController` devolve o brilho ao sair do primeiro plano e guarda um valor pendente em `UserDefaults` para o caso de o app ser fechado à força. **Não instale uma build nova com o modo cabeceira aberto no aparelho.**
- **SF Symbols:** `alarm.slash` não existe; a 10.8 compõe `alarm` + `line.diagonal`. Confira símbolos novos em `/System/Library/CoreServices/CoreGlyphs.bundle/Contents/Resources/name_availability.plist`.
- **Toggle na linha da lista:** não ponha `onTapGesture` na linha inteira, porque ele captura o toque do toggle. Só a área de hora e texto é botão de edição.
- **Closure no `set` de `Binding`:** passar uma função `@MainActor` fez o compilador (Xcode 26.1.1) travar. Capture só valores `Sendable` (controlador `@MainActor` + UUID).
- **Ganchos de depuração** (só em DEBUG): `xcrun simctl launch <sim> com.dablab.mais5minutinhos -debugRinging YES` abre a 10.5; `-debugSnooze YES` abre a cabeceira em soneca. Sem tocar alarme de verdade.
- **"Soneca até":** o AlarmKit não informa quando a soneca termina. A `RootView` calcula a hora quando o alarme entra em `countdown` (agora + `soneca_minutos`); se o app for reaberto no meio da soneca, a hora não aparece.
- **Simulador:** o toque sintético curto não liga `Toggle`. Use `duration: 0.15`.
- **Abertura do app:** o `UILaunchScreen` usa a cor `LaunchBackground` (preta), para não haver clarão branco à noite.
- **Data em pt-BR:** use `Locale(identifier: "pt_BR")` nos textos de data. O aparelho de teste está em inglês.
