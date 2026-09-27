import AlarmKit
import Foundation

// Recorte de uma linha de `alarme` com o que a reconciliação precisa (regra 11.6).
// `Sendable` para ser montado a partir do modelo SwiftData e testado sem banco.
nonisolated struct AlarmRowState: Sendable, Equatable {
    let id: UUID
    let ativo: Bool
    // true quando `dias_repeticao` não está vazio.
    let repeats: Bool
}

// Ação que a reconciliação manda aplicar (regra 11.6).
nonisolated enum ReconciliationAction: Sendable, Equatable {
    // Toque único que já tocou: grava `ativo = false`.
    case deactivate(UUID)
    // Agenda de novo no AlarmKit com a configuração atual da linha.
    case reschedule(UUID)
    // Cancela no AlarmKit.
    case cancel(UUID)
}

// Plano da reconciliação SwiftData × AlarmKit (regra 11.6), sem efeitos colaterais.
nonisolated enum Reconciliation {
    // Compara as linhas do banco com os alarmes do AlarmKit e devolve as ações.
    // Entradas: linhas do SwiftData e estado de cada alarme no AlarmKit por id.
    // Saída: ações na ordem das linhas; cancelamentos de órfãos no fim.
    //
    // Regras (tabela 11.6):
    // - ativo, sem repetição, ausente no AlarmKit → já tocou → `deactivate`;
    // - ativo, com repetição, ausente → `reschedule`;
    // - inativo, presente → `cancel`;
    // - presente no AlarmKit sem linha → `cancel`.
    //
    // O som pago sem compra (último item da 11.6) NÃO é tratado aqui: reagendar
    // a cada reconciliação criava disputas com o próprio AlarmKit (bug do build 2).
    // O som efetivo é reaplicado só quando a compra muda (`refreshScheduled`).
    static func plan(rows: [AlarmRowState], system: [UUID: Alarm.State]) -> [ReconciliationAction] {
        var actions: [ReconciliationAction] = []
        for row in rows {
            let state = system[row.id]
            if row.ativo {
                if state == nil {
                    actions.append(row.repeats ? .reschedule(row.id) : .deactivate(row.id))
                }
            } else if state != nil {
                actions.append(.cancel(row.id))
            }
        }
        let known = Set(rows.map(\.id))
        for id in system.keys.sorted(by: { $0.uuidString < $1.uuidString }) where !known.contains(id) {
            actions.append(.cancel(id))
        }
        return actions
    }
}
