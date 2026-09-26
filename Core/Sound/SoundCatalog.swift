import ActivityKit
import Foundation

// Um som do catálogo (regra 11.3).
nonisolated struct SoundOption: Identifiable, Sendable, Equatable {
    let id: SomAlarme
    // Nome exibido (regra 11.3).
    let name: String
    // Arquivo `.caf` no bundle; nil para `padrao_iphone`, que usa o som do sistema.
    let fileName: String?
    // true para os 6 sons pagos (regra 11.7).
    let isPremium: Bool
}

// Catálogo dos sons do app (seção 13, regra 11.3).
nonisolated enum SoundCatalog {
    // Sons próprios ligados: o spike 8.1 confirmou que o AlarmKit toca o arquivo do
    // bundle (iOS 26.6.2, docs/spike-alarmkit.md). Se isso mudar, false faz todos
    // os alarmes usarem `padrao_iphone` e tira os sons pagos da oferta (regra 11.3).
    static let customSoundsEnabled = true

    // Os 8 sons na ordem da tela 10.3, com nomes e gratuidade da regra 11.3/11.7.
    static let all: [SoundOption] = [
        .init(id: .padraoIphone, name: "Padrão do iPhone", fileName: nil, isPremium: false),
        .init(id: .bipeDigital, name: "Bipe digital", fileName: "bipe_digital.caf", isPremium: false),
        .init(id: .campainhaClassica, name: "Campainha clássica", fileName: "campainha_classica.caf", isPremium: true),
        .init(id: .sino, name: "Sino", fileName: "sino.caf", isPremium: true),
        .init(id: .despertarSuave, name: "Despertar suave", fileName: "despertar_suave.caf", isPremium: true),
        .init(id: .passaros, name: "Pássaros", fileName: "passaros.caf", isPremium: true),
        .init(id: .pianoManha, name: "Piano da manhã", fileName: "piano_manha.caf", isPremium: true),
        .init(id: .radioRelogio, name: "Rádio-relógio", fileName: "radio_relogio.caf", isPremium: true),
    ]

    // Dados de um som. Entradas: id. Saída: opção do catálogo.
    static func option(_ id: SomAlarme) -> SoundOption {
        all.first { $0.id == id } ?? all[0]
    }

    // Arquivo que o alarme deve tocar de fato (regras 11.3 e 11.6).
    // Entradas: som escolhido e se a compra está válida.
    // Saída: nome do arquivo, ou nil para o som do sistema (`padrao_iphone`)
    // quando: é o padrão, os sons próprios estão desligados, o som é pago sem
    // compra válida, ou o arquivo não está no bundle (evita o bipe de erro).
    static func effectiveFileName(for id: SomAlarme, premiumUnlocked: Bool) -> String? {
        let option = option(id)
        guard customSoundsEnabled, let file = option.fileName else { return nil }
        if option.isPremium && !premiumUnlocked { return nil }
        guard Bundle.main.url(forResource: file, withExtension: nil) != nil else { return nil }
        return file
    }

    // Som do AlarmKit para o alarme (contrato da seção 13).
    // Entradas: som escolhido e se a compra está válida. Saída: `AlertSound`.
    static func alertSound(for id: SomAlarme, premiumUnlocked: Bool) -> AlertConfiguration.AlertSound {
        guard let file = effectiveFileName(for: id, premiumUnlocked: premiumUnlocked) else { return .default }
        return .named(file)
    }
}
