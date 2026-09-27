import AlarmKit
import Foundation
import Testing
@testable import MaisCincoMinutinhos

// Texto de dias do subtítulo da lista (critério de 8.3, seção 22).
struct WeekdaysTests {
    @Test func summaryCoversSpecCases() {
        #expect(Weekdays.summary([]) == "Uma vez")
        #expect(Weekdays.summary([1, 2, 3, 4, 5, 6, 7]) == "Todos os dias")
        #expect(Weekdays.summary([2, 3, 4, 5, 6]) == "Dias úteis")
        #expect(Weekdays.summary([1, 7]) == "Fins de semana")
        #expect(Weekdays.summary([6, 2, 4]) == "Seg, Qua, Sex")
        #expect(Weekdays.summary([7, 1, 3]) == "Dom, Ter, Sáb")
    }

    // Repetição e valores fora de 1–7 não mudam o texto.
    @Test func summaryIgnoresDuplicatesAndInvalidDays() {
        #expect(Weekdays.summary([2, 2, 3, 4, 5, 6, 9]) == "Dias úteis")
    }

    // 1 = domingo (seção 7.1) ↔ `Locale.Weekday` do AlarmKit (premissa P4).
    @Test func convertsToAlarmKitWeekday() {
        #expect(Weekdays.localeWeekday(1) == .sunday)
        #expect(Weekdays.localeWeekday(7) == .saturday)
        #expect(Weekdays.localeWeekday(0) == nil)
    }
}

// Formato da hora (regra 11.8).
struct ClockFormatTests {
    @Test func formats24hAnd12h() {
        #expect(ClockFormat.parts(hora: 7, minuto: 5, is24h: true) == ("07:05", nil))
        #expect(ClockFormat.parts(hora: 0, minuto: 0, is24h: false) == ("12:00", "AM"))
        #expect(ClockFormat.parts(hora: 13, minuto: 30, is24h: false) == ("1:30", "PM"))
        #expect(ClockFormat.text(hora: 12, minuto: 0, is24h: false) == "12:00 PM")
    }
}

// Próximo alarme (seção 22: virada de semana, toque único, fuso).
struct NextAlarmTests {
    // Calendário fixo em São Paulo para o teste não depender do aparelho.
    let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Sao_Paulo")!
        return calendar
    }()

    // Monta uma data no fuso do teste. Entradas: componentes. Saída: data.
    func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int, _ min: Int) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
    }

    // Toque único ainda não passado hoje → hoje; já passado → amanhã (regra 11.1).
    @Test func oneShotTodayOrTomorrow() {
        let now = date(2026, 9, 26, 6, 0) // sábado 06:00
        #expect(NextAlarm.date(hora: 7, minuto: 0, dias: [], after: now, calendar: calendar) == date(2026, 9, 26, 7, 0))
        #expect(NextAlarm.date(hora: 5, minuto: 0, dias: [], after: now, calendar: calendar) == date(2026, 9, 27, 5, 0))
    }

    // Dias úteis num sábado → segunda-feira seguinte (virada de semana).
    @Test func weekdaysWrapToNextWeek() {
        let saturday = date(2026, 9, 26, 8, 0)
        let next = NextAlarm.date(hora: 7, minuto: 0, dias: [2, 3, 4, 5, 6], after: saturday, calendar: calendar)
        #expect(next == date(2026, 9, 28, 7, 0))
    }

    // Mesmo dia da semana, hora já passada → próxima semana.
    @Test func sameWeekdayPastTimeGoesToNextWeek() {
        let saturday = date(2026, 9, 26, 8, 0)
        let next = NextAlarm.date(hora: 7, minuto: 0, dias: [7], after: saturday, calendar: calendar)
        #expect(next == date(2026, 10, 3, 7, 0))
    }

    // Texto do dia para o modo cabeceira (8.5).
    @Test func dayText() {
        let now = date(2026, 9, 26, 22, 0)
        #expect(NextAlarm.dayText(for: date(2026, 9, 26, 23, 0), now: now, calendar: calendar) == "hoje")
        #expect(NextAlarm.dayText(for: date(2026, 9, 27, 7, 0), now: now, calendar: calendar) == "amanhã")
    }

    // Fuso diferente: a hora é sempre local ao calendário (regra 11.8).
    @Test func usesCalendarTimeZone() {
        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        let now = tokyo.date(from: DateComponents(year: 2026, month: 9, day: 26, hour: 6, minute: 0))!
        let next = NextAlarm.date(hora: 7, minuto: 0, dias: [], after: now, calendar: tokyo)!
        #expect(tokyo.component(.hour, from: next) == 7)
    }
}

// Reconciliação SwiftData × AlarmKit (regra 11.6, seção 22).
struct ReconciliationTests {
    let a = UUID(), b = UUID(), c = UUID(), orphan = UUID()

    // Linha: ativo, com ou sem repetição.
    func row(_ id: UUID, ativo: Bool = true, repeats: Bool = false) -> AlarmRowState {
        AlarmRowState(id: id, ativo: ativo, repeats: repeats)
    }

    // Ativo, sem repetição, ausente no AlarmKit → já tocou → ativo = false.
    @Test func oneShotMissingIsDeactivated() {
        #expect(Reconciliation.plan(rows: [row(a)], system: [:]) == [.deactivate(a)])
    }

    // Ativo, com repetição, ausente → reagenda.
    @Test func repeatingMissingIsRescheduled() {
        #expect(Reconciliation.plan(rows: [row(a, repeats: true)], system: [:]) == [.reschedule(a)])
    }

    // Inativo, presente → cancela.
    @Test func inactivePresentIsCancelled() {
        #expect(Reconciliation.plan(rows: [row(a, ativo: false)], system: [a: .scheduled]) == [.cancel(a)])
    }

    // Presente no AlarmKit sem linha → cancela.
    @Test func orphanIsCancelled() {
        #expect(Reconciliation.plan(rows: [], system: [orphan: .scheduled]) == [.cancel(orphan)])
    }

    // Alarme agendado ou em soneca nunca é reagendado pela reconciliação: o
    // reagendamento contínuo causava a disputa do bug do build 2.
    @Test func presentAlarmsAreNeverRescheduled() {
        #expect(Reconciliation.plan(rows: [row(a, repeats: true)], system: [a: .scheduled]).isEmpty)
        #expect(Reconciliation.plan(rows: [row(a)], system: [a: .countdown]).isEmpty)
    }

    // Tudo em ordem → nenhuma ação.
    @Test func consistentStateHasNoActions() {
        let rows = [row(a), row(b, repeats: true), row(c, ativo: false)]
        #expect(Reconciliation.plan(rows: rows, system: [a: .scheduled, b: .alerting]).isEmpty)
    }
}
