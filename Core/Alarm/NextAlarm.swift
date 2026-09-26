import Foundation

// Formatação da hora conforme `formato_24h` (seção 7.2, regra 11.8).
nonisolated enum ClockFormat {
    // Divide a hora em texto principal e sufixo AM/PM (regra 11.8: no formato
    // 12h, "AM/PM" pequeno ao lado).
    // Entradas: hora 0–23, minuto 0–59 e se o formato é 24h.
    // Saída: ("07:00", nil) em 24h ou ("7:00", "AM") em 12h.
    static func parts(hora: Int, minuto: Int, is24h: Bool) -> (time: String, suffix: String?) {
        if is24h {
            return (String(format: "%02d:%02d", hora, minuto), nil)
        }
        let hour12 = hora % 12 == 0 ? 12 : hora % 12
        return (String(format: "%d:%02d", hour12, minuto), hora < 12 ? "AM" : "PM")
    }

    // Hora como texto único ("07:00" ou "7:00 AM"), para linhas de informação.
    // Entradas: hora, minuto e formato. Saída: texto.
    static func text(hora: Int, minuto: Int, is24h: Bool) -> String {
        let parts = parts(hora: hora, minuto: minuto, is24h: is24h)
        return [parts.time, parts.suffix].compactMap { $0 }.joined(separator: " ")
    }
}

// Cálculo do próximo toque de um alarme (seções 8.5 e 22). Espelha o que o
// AlarmKit faz com `.relative`: sem repetição, a próxima ocorrência da hora
// (hoje se ainda não passou, senão amanhã, regra 11.1); com repetição, o
// próximo dia da semana marcado.
nonisolated enum NextAlarm {
    // Próxima data em que o alarme toca.
    // Entradas: hora, minuto, dias 1–7 (vazio = uma vez), instante de referência e
    // calendário (fuso do sistema, regra 11.8). Saída: data ou nil se inválida.
    static func date(hora: Int, minuto: Int, dias: [Int], after now: Date, calendar: Calendar = .current) -> Date? {
        let time = DateComponents(hour: hora, minute: minuto, second: 0)
        let days = Set(dias).intersection(Weekdays.all)
        if days.isEmpty {
            return calendar.nextDate(after: now, matching: time, matchingPolicy: .nextTime)
        }
        return days.compactMap { day -> Date? in
            var match = time
            match.weekday = day
            return calendar.nextDate(after: now, matching: match, matchingPolicy: .nextTime)
        }.min()
    }

    // Texto do dia do próximo toque, para o modo cabeceira ("07:00 amanhã", 8.5).
    // Entradas: data do toque, agora e calendário.
    // Saída: "hoje", "amanhã" ou o dia da semana em pt-BR ("segunda-feira").
    static func dayText(for date: Date, now: Date, calendar: Calendar = .current) -> String {
        if calendar.isDate(date, inSameDayAs: now) { return "hoje" }
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
           calendar.isDate(date, inSameDayAs: tomorrow) { return "amanhã" }
        return date.formatted(.dateTime.weekday(.wide).locale(Locale(identifier: "pt_BR")))
    }
}
