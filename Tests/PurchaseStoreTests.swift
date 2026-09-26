import StoreKitTest
import Testing
@testable import MaisCincoMinutinhos

// Compra única com StoreKit local (épico 8.8), usando o arquivo
// `MaisCincoMinutinhos.storekit` numa sessão de teste (sem rede, sem conta).
@MainActor
@Suite(.serialized)
struct PurchaseStoreTests {
    // Sessão de teste limpa, sem diálogos. Saída: sessão pronta.
    func makeSession() throws -> SKTestSession {
        let session = try SKTestSession(configurationFileNamed: "MaisCincoMinutinhos")
        session.disableDialogs = true
        session.clearTransactions()
        return session
    }

    // O produto carrega com o preço da configuração (tela 10.7 usa `displayPrice`).
    @Test func loadsProductWithPrice() async throws {
        _ = try makeSession()
        let store = PurchaseStore()
        await store.loadProduct()
        #expect(store.product?.id == PurchaseStore.productID)
        #expect(!store.isOffline)
    }

    // Comprar libera na hora, sem reiniciar (critério de 8.8).
    @Test func purchaseUnlocksImmediately() async throws {
        _ = try makeSession()
        let store = PurchaseStore()
        #expect(await store.purchase())
        #expect(store.isUnlocked)
    }

    // Reembolso retira o acesso (critério de 8.8: som pago volta ao padrão na
    // reconciliação, tema e cor caem para os grátis).
    @Test func refundRevokesAccess() async throws {
        let session = try makeSession()
        let store = PurchaseStore()
        store.start()
        await store.purchase()
        let transaction = try #require(session.allTransactions().first)
        try session.refundTransaction(identifier: UInt(transaction.identifier))
        // O reembolso chega de forma assíncrona (no app, por `Transaction.updates`).
        for _ in 0..<40 where store.isUnlocked {
            try await Task.sleep(for: .milliseconds(100))
            await store.refreshEntitlement()
        }
        #expect(!store.isUnlocked)
    }

    // Sem compra, restaurar não libera nada e não trava.
    @Test func restoreWithoutPurchaseStaysLocked() async throws {
        _ = try makeSession()
        let store = PurchaseStore()
        #expect(await store.restore() == false)
        #expect(!store.isUnlocked)
    }
}
