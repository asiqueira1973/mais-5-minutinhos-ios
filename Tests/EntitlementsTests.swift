import Testing
@testable import MaisCincoMinutinhos

// O que a compra libera (regra 11.7).
struct EntitlementsTests {
    @Test func freeItemsMatchSpec() {
        #expect(TemaRelogio.allCases.filter(Entitlements.isFree) == [.ledClassico])
        #expect(CorRelogio.allCases.filter(Entitlements.isFree) == [.vermelho, .ambar])
    }

    // Pago sem compra válida cai para o grátis; com compra, vale o escolhido.
    @Test func effectiveFallsBackWithoutPurchase() {
        #expect(Entitlements.effective(TemaRelogio.flip, unlocked: false) == .ledClassico)
        #expect(Entitlements.effective(TemaRelogio.flip, unlocked: true) == .flip)
        #expect(Entitlements.effective(CorRelogio.azul, unlocked: false) == .vermelho)
        #expect(Entitlements.effective(CorRelogio.ambar, unlocked: false) == .ambar)
    }
}
