import Foundation

// Hora exibida pelos relógios do app. Em DEBUG, `-debugClockTime HH:mm` fixa a
// hora mostrada (prints da App Store); fora disso é sempre a hora real.
enum DebugClock {
    // Ajusta a data que o relógio vai mostrar.
    // Entradas: data real. Saída: a mesma data, ou hoje na hora fixada (só DEBUG).
    static func display(_ date: Date) -> Date {
        #if DEBUG
        if let text = UserDefaults.standard.string(forKey: "debugClockTime") {
            let parts = text.split(separator: ":").compactMap { Int($0) }
            if parts.count == 2,
               let fixed = Calendar.current.date(bySettingHour: parts[0], minute: parts[1],
                                                 second: Calendar.current.component(.second, from: date), of: date) {
                return fixed
            }
        }
        #endif
        return date
    }
}
