import Foundation
import Observation
import SwiftData

// Ações da lista e da edição de alarmes (épico 8.3). Aplica a ordem exigida
// pelo spec: primeiro o AlarmKit, depois o SwiftData, para o estado da UI só
// mudar depois do sucesso no sistema (critérios de 8.3, seção 7.1).
@MainActor
@Observable
final class AlarmController {
    // Alerta exibido na lista ou na edição.
    enum AlertKind: Identifiable {
        // Copy 15.6 (limite de 10 ou `maximumLimitReached`).
        case limit
        // Falha genérica do AlarmKit (copy decidida em 26/09/2026, ver CLAUDE.md).
        case error

        var id: Self { self }
    }

    // Máximo de alarmes (regra 11.1).
    static let maxAlarms = 10

    var alert: AlertKind?
    // Abre a tela 10.8 (permissão negada, seção 5).
    var showsPermissionDenied = false

    // Compra válida (espelho de `PurchaseStore.isUnlocked`, atualizado pela
    // `RootView`). Define o som efetivo (regra 11.6) e a cor efetiva (11.7).
    var premiumUnlocked = false

    private let scheduler = AlarmScheduler.shared

    // Contexto do SwiftData da tela; definido pela `RootView` ao aparecer. Usado
    // pelo toggle da lista, que só pode capturar valores `Sendable`.
    var context: ModelContext?

    // Salva um alarme novo ou editado (fluxo de 8.3).
    // Entradas: rascunho, linha em edição (nil = novo) e contexto do SwiftData.
    // Saída: true quando a sheet de edição pode fechar.
    // Regras: novo nasce ativo; edição mantém o `ativo` atual. Se ativo, agenda
    // antes de gravar (cancel + schedule com o mesmo UUID). Permissão negada →
    // grava inativo e abre a 10.8 (seção 5). `maximumLimitReached` → grava inativo
    // e mostra a 15.6 (regra 11.1). Outro erro → não grava e mostra o erro.
    func save(_ draft: AlarmDraft, editing: Alarme?, in context: ModelContext) async -> Bool {
        if editing == nil, (try? context.fetchCount(FetchDescriptor<Alarme>())) ?? 0 >= Self.maxAlarms {
            alert = .limit
            return false
        }
        let wantsActive = editing?.ativo ?? true
        var active = wantsActive
        if wantsActive {
            if await scheduler.requestAuthorization() {
                do {
                    try await scheduler.schedule(draft, cor: clockColor(in: context), premiumUnlocked: premiumUnlocked)
                } catch AlarmSchedulerError.limitReached {
                    active = false
                    alert = .limit
                } catch {
                    alert = .error
                    return false
                }
            } else {
                active = false
                showsPermissionDenied = true
            }
        }
        persist(draft, active: active, editing: editing, in: context)
        return true
    }

    // Liga ou desliga o alarme pelo toggle da lista (critério de 8.3: o toggle só
    // muda depois do sucesso no AlarmKit).
    // Entradas: alarme, novo estado e contexto. Saída: nenhuma.
    func setActive(_ alarme: Alarme, _ on: Bool, in context: ModelContext) async {
        if on {
            guard await scheduler.requestAuthorization() else {
                showsPermissionDenied = true
                return
            }
            do {
                try await scheduler.schedule(alarme, cor: clockColor(in: context), premiumUnlocked: premiumUnlocked)
            } catch AlarmSchedulerError.limitReached {
                alert = .limit
                return
            } catch {
                alert = .error
                return
            }
        } else {
            do {
                try await scheduler.cancel(id: alarme.id)
            } catch {
                alert = .error
                return
            }
        }
        alarme.ativo = on
        alarme.atualizado_em = .now
        try? context.save()
    }

    // Liga/desliga pelo id (usado pelo toggle da lista).
    // Entradas: id do alarme e novo estado. Saída: nenhuma.
    func setActive(id: UUID, _ on: Bool) async {
        guard let context else { return }
        let descriptor = FetchDescriptor<Alarme>(predicate: #Predicate { $0.id == id })
        guard let alarme = try? context.fetch(descriptor).first else { return }
        await setActive(alarme, on, in: context)
    }

    // Exclui o alarme (seção 7.1, hard delete): cancela no AlarmKit primeiro; se
    // falhar, não apaga localmente e mostra erro.
    // Entradas: alarme e contexto. Saída: true se excluiu.
    @discardableResult
    func delete(_ alarme: Alarme, in context: ModelContext) async -> Bool {
        do {
            try await scheduler.cancel(id: alarme.id)
        } catch {
            alert = .error
            return false
        }
        context.delete(alarme)
        try? context.save()
        return true
    }

    // Reconciliação da regra 11.6, chamada a cada volta ao primeiro plano (8.3).
    // Entradas: contexto. Saída: nenhuma.
    func reconcile(in context: ModelContext) async {
        guard scheduler.authorizationState == .authorized else { return }
        let alarmes = (try? context.fetch(FetchDescriptor<Alarme>())) ?? []
        await scheduler.reconcile(alarmes, cor: clockColor(in: context), premiumUnlocked: premiumUnlocked)
        try? context.save()
    }

    // Reagenda os alarmes ativos que estão só agendados, para a apresentação do
    // sistema usar a cor nova (spec 8.6: cor = `cor_relogio`). Não mexe em alarme
    // tocando ou em soneca. Entradas: contexto. Saída: nenhuma.
    func refreshPresentation(in context: ModelContext) async {
        guard scheduler.authorizationState == .authorized else { return }
        let states = scheduler.systemStates()
        let cor = clockColor(in: context)
        let alarmes = (try? context.fetch(FetchDescriptor<Alarme>())) ?? []
        for alarme in alarmes where alarme.ativo && states[alarme.id] == .scheduled {
            try? await scheduler.schedule(alarme, cor: cor, premiumUnlocked: premiumUnlocked)
        }
    }

    // Grava o rascunho na linha existente ou cria uma nova com o mesmo UUID.
    // Entradas: rascunho, estado ativo final, linha em edição e contexto. Saída: nenhuma.
    private func persist(_ draft: AlarmDraft, active: Bool, editing: Alarme?, in context: ModelContext) {
        if let alarme = editing {
            alarme.hora = draft.hora
            alarme.minuto = draft.minuto
            alarme.dias_repeticao = draft.dias_repeticao.sorted()
            alarme.rotulo = draft.rotulo
            alarme.som = draft.som
            alarme.soneca_ativa = draft.soneca_ativa
            alarme.soneca_minutos = draft.soneca_minutos
            alarme.ativo = active
            alarme.atualizado_em = .now
        } else {
            context.insert(Alarme(
                id: draft.id, hora: draft.hora, minuto: draft.minuto,
                dias_repeticao: draft.dias_repeticao.sorted(), rotulo: draft.rotulo, som: draft.som,
                soneca_ativa: draft.soneca_ativa, soneca_minutos: draft.soneca_minutos, ativo: active
            ))
        }
        try? context.save()
    }

    // Cor do relógio atual (preferências, seção 7.2), usada na apresentação do sistema.
    // Entradas: contexto. Saída: cor; `vermelho` se as preferências não puderem ser lidas.
    // Pago sem compra válida cai para a cor grátis (regra 11.7, `Entitlements`).
    private func clockColor(in context: ModelContext) -> CorRelogio {
        let saved = (try? Persistence.ensurePreferences(in: context))?.cor_relogio ?? .vermelho
        return Entitlements.effective(saved, unlocked: premiumUnlocked)
    }
}
