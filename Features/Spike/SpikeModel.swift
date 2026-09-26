import ActivityKit
import AlarmKit
import Observation
import SwiftUI

// Estado e ações do app mínimo do spike técnico do AlarmKit (épico 8.1).
// Valida as premissas P1–P4 em aparelho físico antes de construir as telas.
// TEMPORÁRIO: será removido quando o épico 8.2 substituir o app do spike.
@MainActor
@Observable
final class SpikeModel {
    // Linhas do log exibido na tela, com horário até milissegundos (mede os limites de 1 s).
    var log: [String] = []
    // Alarme que está tocando agora, vindo de `alarmUpdates` (P2). Abre a tela de teste.
    var alertingID: UUID?
    // Estado de autorização do AlarmKit, para exibir na tela.
    var authorization: String = "?"

    private let manager = AlarmManager.shared
    // Cor do relógio padrão (`vermelho`, seção 7.2 e design system).
    nonisolated static let tint = Color(red: 1.0, green: 0x3B / 255, blue: 0x30 / 255)

    // Adiciona uma linha ao log com o horário atual (HH:mm:ss.SSS).
    // Entradas: mensagem. Saída: nenhuma (altera `log`).
    func record(_ message: String) {
        let stamp = Date.now.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits).second(.twoDigits).secondFraction(.fractional(3)))
        log.insert("\(stamp)  \(message)", at: 0)
    }

    // Pede a permissão do AlarmKit (seção 5).
    // Entradas: nenhuma. Saída: nenhuma (atualiza `authorization` e o log).
    func requestAuthorization() async {
        do {
            let state = try await Self.requestAuthorizationOffMain()
            authorization = "\(state)"
            record("autorização: \(state)")
        } catch {
            record("erro na autorização: \(error)")
        }
    }

    // Agenda um alarme de teste com `.relative` no minuto cheio seguinte a +1 min,
    // igual ao caminho de produção (regra 11.1), com soneca de 5 min (épico 8.1).
    // Entradas: `customSound` — true usa `bipe_digital.caf` (P1), false usa `.default`.
    // Saída: nenhuma (agenda no AlarmKit e registra no log).
    func scheduleTestAlarm(customSound: Bool) async {
        if manager.authorizationState != .authorized {
            await requestAuthorization()
        }
        // Próximo minuto cheio que esteja a pelo menos 60 s de agora.
        let target = Calendar.current.nextDate(
            after: Date.now.addingTimeInterval(60),
            matching: DateComponents(second: 0),
            matchingPolicy: .nextTime
        ) ?? Date.now.addingTimeInterval(120)
        let parts = Calendar.current.dateComponents([.hour, .minute], from: target)
        let schedule = Alarm.Schedule.relative(.init(
            time: .init(hour: parts.hour ?? 0, minute: parts.minute ?? 0),
            repeats: .never
        ))

        let id = UUID()
        do {
            try await Self.scheduleOffMain(id: id, schedule: schedule, customSound: customSound)
            record("agendado \(customSound ? "bipe_digital.caf" : ".default") para \(target.formatted(date: .omitted, time: .shortened)) — \(id.uuidString.prefix(8))")
        } catch {
            record("erro ao agendar: \(error)")
        }
    }

    // Pede a autorização fora do MainActor: `AlarmManager` não é `Sendable` no
    // SDK 26.1, então as chamadas `async` dele ficam em contexto não isolado.
    // Entradas: nenhuma. Saída: estado de autorização retornado pelo AlarmKit.
    nonisolated private static func requestAuthorizationOffMain() async throws -> AlarmManager.AuthorizationState {
        try await AlarmManager.shared.requestAuthorization()
    }

    // Agenda no AlarmKit fora do MainActor (mesmo motivo acima), com soneca de
    // 5 min (épico 8.1) e som próprio ou padrão (premissa P1).
    // Entradas: id, agenda e escolha do som. Saída: nenhuma; lança o erro do AlarmKit.
    nonisolated private static func scheduleOffMain(id: UUID, schedule: Alarm.Schedule, customSound: Bool) async throws {
        let configuration = AlarmManager.AlarmConfiguration<Mais5Metadata>(
            countdownDuration: .init(preAlert: nil, postAlert: 5 * 60),
            schedule: schedule,
            attributes: attributes(title: customSound ? "Spike som próprio" : "Spike som padrão"),
            stopIntent: nil,
            secondaryIntent: nil,
            sound: customSound ? .named("bipe_digital.caf") : .default
        )
        _ = try await AlarmManager.shared.schedule(id: id, configuration: configuration)
    }

    // Monta a apresentação do sistema: título, Soneca com contagem e cor (spec 8.6).
    // No iOS 26.1+ o botão de parar é do próprio sistema (`stopButton` descontinuado
    // no SDK 26.1, premissa P4); no 26.0 ainda é preciso informar o botão "Parar".
    // Entradas: título do alerta. Saída: atributos para `AlarmConfiguration`.
    nonisolated static func attributes(title: String) -> AlarmAttributes<Mais5Metadata> {
        // O sistema pinta o fundo do botão secundário com `tintColor`; o texto
        // precisa ser preto para aparecer (design: texto sobre a cor é sempre #000).
        let snooze = AlarmButton(text: "Soneca", textColor: .black, systemImageName: "zzz")
        let alert: AlarmPresentation.Alert
        if #available(iOS 26.1, *) {
            alert = AlarmPresentation.Alert(
                title: LocalizedStringResource(stringLiteral: title),
                secondaryButton: snooze,
                secondaryButtonBehavior: .countdown
            )
        } else {
            alert = AlarmPresentation.Alert(
                title: LocalizedStringResource(stringLiteral: title),
                stopButton: AlarmButton(text: "Parar", textColor: .black, systemImageName: "stop.fill"),
                secondaryButton: snooze,
                secondaryButtonBehavior: .countdown
            )
        }
        let presentation = AlarmPresentation(
            alert: alert,
            countdown: AlarmPresentation.Countdown(title: "Soneca")
        )
        return AlarmAttributes(
            presentation: presentation,
            metadata: Mais5Metadata(rotulo: title, cor: "vermelho"),
            tintColor: tint
        )
    }

    // Observa `alarmUpdates` e registra cada mudança de estado; abre a tela de
    // teste quando algum alarme entra em `alerting` (premissa P2).
    // Entradas: nenhuma. Saída: nenhuma (roda até a task ser cancelada).
    func observe() async {
        authorization = "\(manager.authorizationState)"
        var last: [UUID: Alarm.State] = [:]
        for await alarms in manager.alarmUpdates {
            var current: [UUID: Alarm.State] = [:]
            for alarm in alarms {
                current[alarm.id] = alarm.state
                if last[alarm.id] != alarm.state {
                    record("estado \(alarm.id.uuidString.prefix(8)): \(alarm.state)")
                }
            }
            for id in last.keys where current[id] == nil {
                record("removido \(id.uuidString.prefix(8))")
            }
            last = current
            alertingID = alarms.first(where: { $0.state == .alerting })?.id
        }
    }

    // Para o alarme pela tela do app (premissa P3).
    // Entradas: id do alarme. Saída: nenhuma (registra resultado no log).
    func stop(_ id: UUID) {
        do {
            try manager.stop(id: id)
            record("stop(id:) chamado")
        } catch {
            record("erro no stop: \(error)")
        }
        alertingID = nil
    }

    // Inicia a soneca pela tela do app (premissa P3, spec 8.6).
    // Entradas: id do alarme. Saída: nenhuma (registra resultado no log).
    func snooze(_ id: UUID) {
        do {
            try manager.countdown(id: id)
            record("countdown(id:) chamado")
        } catch {
            record("erro no countdown: \(error)")
        }
        alertingID = nil
    }

    // Cancela todos os alarmes do app (limpeza entre testes).
    // Entradas: nenhuma. Saída: nenhuma.
    func cancelAll() {
        for alarm in (try? manager.alarms) ?? [] {
            try? manager.cancel(id: alarm.id)
        }
        record("todos cancelados")
    }
}
