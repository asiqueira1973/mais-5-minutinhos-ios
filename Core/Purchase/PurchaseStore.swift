import Observation
import StoreKit

// Compra única por StoreKit 2 (contrato da seção 13, épico 8.8). Produto não
// consumível que libera temas, cores e sons pagos (regra 11.7). O estado vem
// sempre de `Transaction.currentEntitlements`; nada fica salvo no SwiftData
// (seção 7.2). Preço exibido vem de `displayPrice` (design system, tela 7).
@MainActor
@Observable
final class PurchaseStore {
    // Identificador do produto na App Store (spec 8.8, README).
    static let productID = "com.dablab.mais5minutinhos.completo"

    // true com compra válida (não reembolsada). Observável: libera tudo na hora,
    // sem reiniciar (critério de 8.8).
    private(set) var isUnlocked = false
    // Produto carregado da App Store; nil sem rede ou enquanto carrega.
    private(set) var product: Product?
    // true quando o produto não pôde ser carregado (sem rede): paywall mostra 15.7.
    private(set) var isOffline = false
    // true durante compra ou restauração, para desabilitar os botões.
    private(set) var isBusy = false

    private var updatesTask: Task<Void, Never>?

    // Começa a escutar transações que chegam fora do fluxo de compra (compra em
    // outro aparelho, aprovação do responsável, reembolso) e lê o estado atual.
    // Entradas: nenhuma. Saída: nenhuma.
    func start() {
        guard updatesTask == nil else { return }
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                await self?.handle(result)
            }
        }
        Task { await refreshEntitlement() }
    }

    // Carrega o produto para mostrar o preço (tela 10.7). Sem rede, marca
    // `isOffline` e não trava (critério de 8.8).
    // Entradas: nenhuma. Saída: nenhuma.
    func loadProduct() async {
        do {
            product = try await Product.products(for: [Self.productID]).first
            isOffline = product == nil
        } catch {
            product = nil
            isOffline = true
        }
    }

    // Compra o produto (contrato `purchase()`, seção 13).
    // Entradas: nenhuma. Saída: true se a compra foi concluída e validada.
    // Cancelamento ou pendência voltam sem alerta; falha de rede marca `isOffline`.
    @discardableResult
    func purchase() async -> Bool {
        if product == nil { await loadProduct() }
        guard let product else { return false }
        isBusy = true
        defer { isBusy = false }
        do {
            switch try await product.purchase() {
            case .success(let result):
                await handle(result)
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            isOffline = true
        }
        return isUnlocked
    }

    // Restaura a compra no mesmo Apple ID, inclusive em aparelho novo (contrato
    // `restore()`, critério de 8.8). Entradas: nenhuma. Saída: true se liberou.
    @discardableResult
    func restore() async -> Bool {
        isBusy = true
        defer { isBusy = false }
        try? await AppStore.sync()
        await refreshEntitlement()
        return isUnlocked
    }

    // Relê o direito atual: válido se existe transação verificada do produto e sem
    // `revocationDate` (reembolso retira o acesso, critério de 8.8).
    // Entradas: nenhuma. Saída: nenhuma.
    func refreshEntitlement() async {
        var unlocked = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.productID,
               transaction.revocationDate == nil {
                unlocked = true
            }
        }
        #if DEBUG
        // SÓ DEPURAÇÃO: `-debugUnlocked YES` libera tudo para os prints da App Store.
        if UserDefaults.standard.bool(forKey: "debugUnlocked") { unlocked = true }
        #endif
        isUnlocked = unlocked
    }

    // Trata uma transação: conclui (`finish`) para não ser reentregue e relê o
    // direito (cobre compra, restauração e reembolso).
    // Entradas: resultado verificado ou não. Saída: nenhuma.
    private func handle(_ result: VerificationResult<Transaction>) async {
        if case .verified(let transaction) = result {
            await transaction.finish()
        }
        await refreshEntitlement()
    }
}
