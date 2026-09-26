# Mais 5 Minutinhos

Despertador de cabeceira para iPhone (iOS 26+). À noite, um relógio grande e escuro no carregador; de manhã, o alarme toca pelo AlarmKit, mesmo no silencioso, com dois botões gigantes: Soneca e Parar.

- Nome na App Store: "Mais 5 Minutinhos – Despertador"
- Nome sob o ícone: "5 Minutinhos"
- Spec: [`SDD-mais-5-minutinhos.md`](SDD-mais-5-minutinhos.md) · convenções para agentes: [`CLAUDE.md`](CLAUDE.md)

## Setup

Requisitos: Xcode 26.1+, [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`).

```bash
xcodegen generate
open MaisCincoMinutinhos.xcodeproj
```

O `.xcodeproj` é gerado a partir do `project.yml` e não é versionado.

Os alarmes (AlarmKit) só funcionam de verdade em **iPhone físico**. O simulador serve para layout e testes unitários.

## Identificadores

| Item | Valor |
|---|---|
| Bundle ID do app | `com.dablab.mais5minutinhos` |
| Bundle ID da Live Activity | `com.dablab.mais5minutinhos.widget` |
| Team | `XGZW6Y6K25` |
| Produto IAP (não consumível) | `com.dablab.mais5minutinhos.completo`: R$ 19,90 (épico 8.8) |

Sem variáveis de ambiente, segredos ou backend. Nenhum dado sai do aparelho.

## Testes

```bash
xcodebuild test -project MaisCincoMinutinhos.xcodeproj -scheme MaisCincoMinutinhos -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

O roteiro manual em aparelho está em [`docs/spike-alarmkit.md`](docs/spike-alarmkit.md) e deve ser repetido antes de cada envio à revisão.
