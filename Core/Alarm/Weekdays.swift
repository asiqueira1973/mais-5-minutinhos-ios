import Foundation

// Dias da semana do campo `dias_repeticao` (seção 7.1): 1–7, 1 = domingo,
// mesmo padrão de `Calendar.weekday`. Converte para o AlarmKit e gera o texto
// do subtítulo da lista (critério de 8.3).
nonisolated enum Weekdays {
    static let all: Set<Int> = Set(1...7)
    // Atalho "Dias úteis" da tela 10.2: segunda a sexta.
    static let workdays: Set<Int> = [2, 3, 4, 5, 6]
    static let weekend: Set<Int> = [1, 7]

    // Abreviações usadas no subtítulo ("Seg, Qua, Sex").
    static let shortNames: [Int: String] = [
        1: "Dom", 2: "Seg", 3: "Ter", 4: "Qua", 5: "Qui", 6: "Sex", 7: "Sáb",
    ]

    // Letras dos 7 botões redondos da tela 10.2, de domingo a sábado (design system).
    static let initials: [Int: String] = [
        1: "D", 2: "S", 3: "T", 4: "Q", 5: "Q", 6: "S", 7: "S",
    ]

    // Texto do subtítulo da lista (critério de 8.3): "Uma vez", "Todos os dias",
    // "Dias úteis", "Fins de semana" ou a lista abreviada ("Seg, Qua, Sex").
    // Entradas: dias 1–7 (ordem e repetições não importam). Saída: texto.
    static func summary(_ days: [Int]) -> String {
        let set = Set(days).intersection(all)
        switch set {
        case []: return "Uma vez"
        case all: return "Todos os dias"
        case workdays: return "Dias úteis"
        case weekend: return "Fins de semana"
        default:
            // Ordem de domingo a sábado, a mesma dos botões da tela 10.2.
            return set.sorted().compactMap { shortNames[$0] }.joined(separator: ", ")
        }
    }

    // Converte 1–7 (1 = domingo) para o tipo do AlarmKit (premissa P4).
    // Entradas: número do dia. Saída: `Locale.Weekday` ou nil se fora de 1–7.
    static func localeWeekday(_ day: Int) -> Locale.Weekday? {
        switch day {
        case 1: .sunday
        case 2: .monday
        case 3: .tuesday
        case 4: .wednesday
        case 5: .thursday
        case 6: .friday
        case 7: .saturday
        default: nil
        }
    }
}
