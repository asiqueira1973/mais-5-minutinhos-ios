# Mais 5 Minutinhos

Despertador de cabeceira para iPhone (iOS 26+). À noite, um relógio grande e escuro no carregador; de manhã, o alarme toca pelo AlarmKit, mesmo no silencioso, com dois botões gigantes: Soneca e Parar.

- Nome na App Store: "Mais 5 Minutinhos – Despertador"
- Nome sob o ícone: "5 Minutinhos"
- Spec: [`SDD-mais-5-minutinhos.md`](SDD-mais-5-minutinhos.md) (v1.2) · convenções para agentes: [`CLAUDE.md`](CLAUDE.md)
- Documentação técnica: [`DOCUMENTACAO-TECNICA.md`](DOCUMENTACAO-TECNICA.md) · validação: [`docs/validacao.md`](docs/validacao.md)

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

## Compra no simulador

O scheme usa [`MaisCincoMinutinhos.storekit`](MaisCincoMinutinhos.storekit) (loja BRA, R$ 19,90) ao rodar pelo Xcode. Os testes da compra usam o mesmo arquivo pelo StoreKitTest.

## Sons e ícone

Os 7 sons são sintetizados por [`scripts/make-sounds.py`](scripts/make-sounds.py) (licenças em [`Resources/Sounds/LICENSES.md`](Resources/Sounds/LICENSES.md)). O ícone é gerado por [`scripts/make-app-icon.swift`](scripts/make-app-icon.swift).

## Testes

```bash
xcodebuild test -project MaisCincoMinutinhos.xcodeproj -scheme MaisCincoMinutinhos -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

37 testes (Swift Testing): persistência, texto de dias, próximo alarme, reconciliação 11.6, regra 11.4, catálogo de sons, regra 11.7 e compra (StoreKitTest).

AlarmKit só se valida em aparelho. O roteiro está em [`docs/spike-alarmkit.md`](docs/spike-alarmkit.md) e as pendências em [`docs/validacao.md`](docs/validacao.md); repita antes de cada envio à revisão (seção 22).

Para ver as telas sem tocar alarme (só em Debug): `xcrun simctl launch booted com.dablab.mais5minutinhos -debugRinging YES` (tela 10.5) ou `-debugSnooze YES` (cabeceira em soneca).

## Build para o TestFlight

```bash
xcodegen generate
xcodebuild archive -project MaisCincoMinutinhos.xcodeproj -scheme MaisCincoMinutinhos -configuration Release -destination 'generic/platform=iOS' -archivePath build/MaisCincoMinutinhos.xcarchive -allowProvisioningUpdates
xcodebuild -exportArchive -archivePath build/MaisCincoMinutinhos.xcarchive -exportPath build/export -exportOptionsPlist ExportOptions.plist -allowProvisioningUpdates
```

O `ExportOptions.plist` envia direto para o App Store Connect (`destination: upload`) com a conta logada no Xcode. **Antes de cada novo envio, aumente `CURRENT_PROJECT_VERSION` no `project.yml`**, porque a Apple recusa um número de build repetido. Histórico: 1.0.0 (1) em 26/09/2026 (saiu com suporte a iPad por engano); 1.0.0 (2) só iPhone; 1.0.0 (3) em 27/09/2026: correção do alarme que podia não tocar + sons mais altos.
