import ActivityKit
import AlarmKit
import OSLog
import SwiftUI

// Registro de diagnóstico do agendamento (categoria "alarm"). Só ids curtos,
// horas e estados; nenhum dado pessoal. Em DEBUG também vai para o console.
nonisolated enum AlarmLog {
    static let logger = Logger(subsystem: "com.dablab.mais5minutinhos", category: "alarm")

    // Registra uma linha. Entradas: texto. Saída: nenhuma.
    static func log(_ message: String) {
        logger.notice("\(message, privacy: .public)")
        #if DEBUG
        print("[alarm] \(Date.now.formatted(date: .omitted, time: .standard)) \(message)")
        #endif
    }

    // Id curto para o registro. Entradas: UUID. Saída: 8 primeiros caracteres.
    static func short(_ id: UUID) -> String { String(id.uuidString.prefix(8)) }
}

// Valores de um alarme usados para agendar (seção 7.1). Existe separado do
// modelo SwiftData para: (1) agendar uma edição antes de gravá-la (critério de
// 8.3, o estado só muda depois do sucesso no AlarmKit); (2) atravessar para
// contexto não isolado, porque `AlarmManager` não é `Sendable` (premissa P4).
nonisolated struct AlarmDraft: Sendable, Equatable {
    var id: UUID
    var hora: Int
    var minuto: Int
    var dias_repeticao: [Int]
    var rotulo: String?
    var som: SomAlarme
    var soneca_ativa: Bool
    var soneca_minutos: Int

    // Rascunho de alarme novo com os defaults da seção 7.1.
    // Entradas: hora e minuto iniciais. Saída: rascunho.
    init(hora: Int, minuto: Int) {
        id = UUID()
        self.hora = hora
        self.minuto = minuto
        dias_repeticao = []
        rotulo = nil
        som = .padraoIphone
        soneca_ativa = true
        soneca_minutos = 9
    }

    // Rascunho a partir de uma linha existente (mesmo UUID, seção 7.1).
    // Entradas: alarme do SwiftData. Saída: rascunho com os mesmos valores.
    @MainActor
    init(_ alarme: Alarme) {
        id = alarme.id
        hora = alarme.hora
        minuto = alarme.minuto
        dias_repeticao = alarme.dias_repeticao
        rotulo = alarme.rotulo
        som = alarme.som
        soneca_ativa = alarme.soneca_ativa
        soneca_minutos = alarme.soneca_minutos
    }
}

// Erros do agendamento que a UI trata de forma diferente (regra 11.1, seção 5).
nonisolated enum AlarmSchedulerError: Error {
    // O AlarmKit devolveu `maximumLimitReached` (copy 15.6).
    case limitReached
}

// Única porta do app para o AlarmKit (contrato da seção 13). O id do alarme no
// AlarmKit é sempre o `alarme.id` do SwiftData (seção 7.1).
@MainActor
final class AlarmScheduler {
    static let shared = AlarmScheduler()

    private var manager: AlarmManager { .shared }

    // Fila de operações: agendar, cancelar e reconciliar rodam uma de cada vez.
    // Sem isso, o "cancela e agenda de novo" de um reagendamento abria uma janela
    // em que o alarme sumia do AlarmKit; o app percebia o sumiço, disparava uma
    // reconciliação que reagendava o mesmo id em paralelo, e a disputa podia
    // deixar o alarme sem agendamento (bug do build 2, 27/09/2026).
    private var isBusy = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    // Espera a vez na fila. Entradas: nenhuma. Saída: nenhuma.
    private func acquire() async {
        if isBusy {
            await withCheckedContinuation { waiters.append($0) }
        } else {
            isBusy = true
        }
    }

    // Libera a fila para a próxima operação. Entradas: nenhuma. Saída: nenhuma.
    private func release() {
        if waiters.isEmpty {
            isBusy = false
        } else {
            waiters.removeFirst().resume()
        }
    }

    // Roda a operação com exclusividade na fila.
    // Entradas: operação. Saída: o resultado dela; repassa o erro.
    private func exclusive<T>(_ operation: () async throws -> T) async rethrows -> T {
        await acquire()
        defer { release() }
        return try await operation()
    }

    // Estado atual da permissão (seção 5).
    var authorizationState: AlarmManager.AuthorizationState { manager.authorizationState }

    // Pede a permissão do AlarmKit se ainda não foi decidida (seção 5: só ao
    // salvar o primeiro alarme, nunca na abertura).
    // Entradas: nenhuma. Saída: true se autorizado.
    func requestAuthorization() async -> Bool {
        switch authorizationState {
        case .authorized: return true
        case .denied: return false
        case .notDetermined:
            let state = try? await Self.requestAuthorizationOffMain()
            return state == .authorized
        @unknown default: return false
        }
    }

    // Agenda (ou reagenda) o alarme com o mesmo UUID: se já existir no AlarmKit,
    // cancela antes (critério de 8.3: editar = cancel + schedule).
    // Entradas: valores do alarme, cor do relógio e se a compra está válida.
    // Saída: nenhuma. Lança `AlarmSchedulerError.limitReached` (regra 11.1) ou o
    // erro do AlarmKit.
    func schedule(_ draft: AlarmDraft, cor: CorRelogio, premiumUnlocked: Bool) async throws {
        try await exclusive {
            try await scheduleNow(draft, cor: cor, premiumUnlocked: premiumUnlocked)
        }
    }

    // Agendamento em si, sem passar pela fila (quem chama já está com a vez).
    // Entradas e saída: como `schedule(_:cor:premiumUnlocked:)`.
    private func scheduleNow(_ draft: AlarmDraft, cor: CorRelogio, premiumUnlocked: Bool) async throws {
        let tag = "\(AlarmLog.short(draft.id)) \(String(format: "%02d:%02d", draft.hora, draft.minuto)) dias=\(draft.dias_repeticao)"
        if systemStates()[draft.id] != nil {
            AlarmLog.log("schedule: cancela antes \(tag)")
            try manager.cancel(id: draft.id)
        }
        let soundFile = SoundCatalog.effectiveFileName(for: draft.som, premiumUnlocked: premiumUnlocked)
        do {
            try await Self.scheduleOffMain(draft, cor: cor, soundFile: soundFile)
            AlarmLog.log("schedule: OK \(tag) som=\(soundFile ?? "padrao") estado=\(systemStates()[draft.id].map { "\($0)" } ?? "AUSENTE")")
        } catch let error as AlarmManager.AlarmError where error == .maximumLimitReached {
            AlarmLog.log("schedule: LIMITE \(tag)")
            throw AlarmSchedulerError.limitReached
        } catch {
            AlarmLog.log("schedule: ERRO \(tag) \(error)")
            throw error
        }
    }

    // Atalho do contrato da seção 13: agenda a partir da linha do SwiftData.
    // Entradas: alarme, cor e compra. Saída: nenhuma; lança como `schedule(_:cor:premiumUnlocked:)`.
    func schedule(_ alarme: Alarme, cor: CorRelogio, premiumUnlocked: Bool) async throws {
        try await schedule(AlarmDraft(alarme), cor: cor, premiumUnlocked: premiumUnlocked)
    }

    // Cancela no AlarmKit (toggle desligado, exclusão, regra 11.6). Se o alarme
    // não existe no AlarmKit (já tocou ou estava inativo), não há o que cancelar.
    // Entradas: id. Saída: nenhuma. Lança o erro do AlarmKit.
    func cancel(id: UUID) async throws {
        try await exclusive {
            guard systemStates()[id] != nil else { return }
            AlarmLog.log("cancel: \(AlarmLog.short(id))")
            try manager.cancel(id: id)
        }
    }

    // Para o alarme que está tocando (tela 10.5, premissa P3).
    // Entradas: id. Saída: nenhuma. Lança o erro do AlarmKit.
    func stop(id: UUID) throws {
        try manager.stop(id: id)
    }

    // Inicia a soneca do alarme que está tocando (tela 10.5, premissa P3).
    // Entradas: id. Saída: nenhuma. Lança o erro do AlarmKit.
    func snooze(id: UUID) throws {
        try manager.countdown(id: id)
    }

    // Estado de cada alarme do app no AlarmKit agora.
    // Entradas: nenhuma. Saída: estado por id (vazio se a leitura falhar).
    func systemStates() -> [UUID: Alarm.State] {
        let alarms = (try? manager.alarms) ?? []
        return Dictionary(alarms.map { ($0.id, $0.state) }, uniquingKeysWith: { first, _ in first })
    }

    // Reconcilia SwiftData com AlarmKit (regra 11.6), aplicando o plano de
    // `Reconciliation.plan`. Grava `ativo = false` direto nas linhas; quem chama salva.
    // As linhas são lidas só quando chega a vez na fila, para refletir o banco
    // depois de qualquer salvamento em andamento.
    // Entradas: leitura das linhas de `alarme`, cor do relógio e se a compra está
    // válida. Saída: nenhuma. Falhas individuais não interrompem as demais.
    func reconcile(fetch: () -> [Alarme], cor: CorRelogio, premiumUnlocked: Bool) async {
        await exclusive {
            let alarmes = fetch()
            let rows = alarmes.map {
                AlarmRowState(id: $0.id, ativo: $0.ativo, repeats: !$0.dias_repeticao.isEmpty)
            }
            let byID = Dictionary(alarmes.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            let system = systemStates()
            let plan = Reconciliation.plan(rows: rows, system: system)
            AlarmLog.log("reconcile: linhas=\(rows.count) sistema=\(system.map { "\(AlarmLog.short($0.key))=\($0.value)" }.sorted()) plano=\(plan)")
            for action in plan {
                switch action {
                case .deactivate(let id):
                    byID[id]?.ativo = false
                case .reschedule(let id):
                    if let alarme = byID[id] {
                        try? await scheduleNow(AlarmDraft(alarme), cor: cor, premiumUnlocked: premiumUnlocked)
                    }
                case .cancel(let id):
                    try? manager.cancel(id: id)
                }
            }
        }
    }

    // Reagenda, numa vez só da fila, os alarmes ativos que estão só agendados,
    // para aplicar cor ou som efetivo novos (troca de cor, compra liberada ou
    // retirada, regras 11.6/11.7). Não mexe em alarme tocando ou em soneca.
    // Entradas: leitura das linhas, cor e compra. Saída: nenhuma.
    func refreshScheduled(fetch: () -> [Alarme], cor: CorRelogio, premiumUnlocked: Bool) async {
        await exclusive {
            let states = systemStates()
            for alarme in fetch() where alarme.ativo && states[alarme.id] == .scheduled {
                try? await scheduleNow(AlarmDraft(alarme), cor: cor, premiumUnlocked: premiumUnlocked)
            }
        }
    }

    // Fluxo com o estado de todos os alarmes a cada mudança no AlarmKit (seção 12:
    // o app não guarda o estado, lê de `alarmUpdates`).
    // Entradas: nenhuma. Saída: sequência com o estado por id.
    func observe() -> AsyncStream<[UUID: Alarm.State]> {
        AsyncStream { continuation in
            let task = Task { @MainActor in
                for await alarms in AlarmManager.shared.alarmUpdates {
                    continuation.yield(Dictionary(alarms.map { ($0.id, $0.state) }, uniquingKeysWith: { first, _ in first }))
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    // MARK: - Chamadas async fora do MainActor (`AlarmManager` não é `Sendable`)

    // Pede a autorização ao AlarmKit. Entradas: nenhuma. Saída: estado retornado.
    nonisolated private static func requestAuthorizationOffMain() async throws -> AlarmManager.AuthorizationState {
        try await AlarmManager.shared.requestAuthorization()
    }

    // Monta a configuração e agenda no AlarmKit (regras 11.1 e 11.2, spec 8.6).
    // Entradas: valores do alarme, cor e arquivo de som efetivo (nil = padrão).
    // Saída: nenhuma. Lança o erro do AlarmKit.
    nonisolated private static func scheduleOffMain(_ draft: AlarmDraft, cor: CorRelogio, soundFile: String?) async throws {
        // Sem repetição: `.never` (próxima ocorrência da hora, amanhã se já passou);
        // com repetição: `.weekly` nos dias marcados (regra 11.1).
        let days = draft.dias_repeticao.compactMap(Weekdays.localeWeekday)
        let schedule = Alarm.Schedule.relative(.init(
            time: .init(hour: draft.hora, minute: draft.minuto),
            repeats: days.isEmpty ? .never : .weekly(days)
        ))
        let snoozeSeconds = draft.soneca_ativa ? TimeInterval(draft.soneca_minutos * 60) : nil
        let configuration = AlarmManager.AlarmConfiguration<Mais5Metadata>(
            countdownDuration: snoozeSeconds.map { .init(preAlert: nil, postAlert: $0) },
            schedule: schedule,
            attributes: attributes(rotulo: draft.rotulo, cor: cor, hasSnooze: snoozeSeconds != nil),
            stopIntent: nil,
            secondaryIntent: nil,
            sound: soundFile.map { .named($0) } ?? .default
        )
        _ = try await AlarmManager.shared.schedule(id: draft.id, configuration: configuration)
    }

    // Apresentação do sistema (spec 8.6, tela 10.9): título = rótulo ou "Alarme",
    // Soneca com contagem só se a soneca estiver ativa (regra 11.2), cor do relógio.
    // No iOS 26.1+ o botão de parar é do sistema ("deslizar para parar"); no 26.0
    // ainda é preciso informar "Parar" (docs/spike-alarmkit.md). O fundo do botão
    // secundário é a cor do relógio, então o texto é preto (achado do spike).
    // Entradas: rótulo, cor e se há soneca. Saída: atributos do alarme.
    nonisolated static func attributes(rotulo: String?, cor: CorRelogio, hasSnooze: Bool) -> AlarmAttributes<Mais5Metadata> {
        let metadata = Mais5Metadata(rotulo: rotulo, cor: cor.rawValue)
        let title = LocalizedStringResource(stringLiteral: metadata.displayTitle)
        let snooze = hasSnooze ? AlarmButton(text: "Soneca", textColor: .black, systemImageName: "zzz") : nil
        let alert: AlarmPresentation.Alert
        if #available(iOS 26.1, *) {
            alert = AlarmPresentation.Alert(
                title: title,
                secondaryButton: snooze,
                secondaryButtonBehavior: hasSnooze ? .countdown : nil
            )
        } else {
            alert = AlarmPresentation.Alert(
                title: title,
                stopButton: AlarmButton(text: "Parar", textColor: .black, systemImageName: "stop.fill"),
                secondaryButton: snooze,
                secondaryButtonBehavior: hasSnooze ? .countdown : nil
            )
        }
        let presentation = AlarmPresentation(
            alert: alert,
            countdown: hasSnooze ? AlarmPresentation.Countdown(title: "Soneca") : nil
        )
        return AlarmAttributes(presentation: presentation, metadata: metadata, tintColor: cor.color)
    }
}
