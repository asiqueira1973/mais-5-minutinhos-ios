import Foundation
import Testing
@testable import MaisCincoMinutinhos

// Catálogo de sons (regras 11.3, 11.6 e 11.7).
struct SoundCatalogTests {
    // Nomes e ordem da regra 11.3; grátis só `padrao_iphone` e `bipe_digital` (11.7).
    @Test func catalogMatchesSpec() {
        #expect(SoundCatalog.all.map(\.name) == [
            "Padrão do iPhone", "Bipe digital", "Campainha clássica", "Sino",
            "Despertar suave", "Pássaros", "Piano da manhã", "Rádio-relógio",
        ])
        #expect(SoundCatalog.all.filter { !$0.isPremium }.map(\.id) == [.padraoIphone, .bipeDigital])
    }

    // Os 7 arquivos próprios estão no bundle do app.
    @Test func allSoundFilesAreBundled() {
        for option in SoundCatalog.all {
            guard let file = option.fileName else { continue }
            #expect(Bundle.main.url(forResource: file, withExtension: nil) != nil, "faltando \(file)")
        }
    }

    // Som efetivo: padrão usa o sistema; pago sem compra cai para o padrão (11.6).
    @Test func effectiveSoundFollowsPurchase() {
        #expect(SoundCatalog.effectiveFileName(for: .padraoIphone, premiumUnlocked: true) == nil)
        #expect(SoundCatalog.effectiveFileName(for: .bipeDigital, premiumUnlocked: false) == "bipe_digital.caf")
        #expect(SoundCatalog.effectiveFileName(for: .sino, premiumUnlocked: false) == nil)
        #expect(SoundCatalog.effectiveFileName(for: .sino, premiumUnlocked: true) == "sino.caf")
    }
}
