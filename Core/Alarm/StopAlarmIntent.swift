import AlarmKit
import AppIntents

// Intent do botão "Parar" da Live Activity da soneca (spec 8.6, 10.9).
// Roda no processo do app quando tocado na tela bloqueada/Dynamic Island.
// Entradas: `alarmID` (UUID em texto; o mesmo id do alarme no SwiftData, seção 7.1).
// Saída: para o alarme no AlarmKit (encerra a contagem da soneca).
struct StopAlarmIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Parar"
    static let isDiscoverable = false

    @Parameter(title: "ID do alarme")
    var alarmID: String

    init() {}

    // Cria o intent para um alarme específico.
    // Entradas: id do alarme. Saída: intent pronto para `Button(intent:)`.
    init(alarmID: UUID) {
        self.alarmID = alarmID.uuidString
    }

    // Para o alarme no AlarmKit. Entradas: nenhuma. Saída: resultado vazio.
    // Lança erro se o id for inválido ou o AlarmKit recusar.
    @MainActor
    func perform() async throws -> some IntentResult {
        guard let id = UUID(uuidString: alarmID) else { return .result() }
        try AlarmManager.shared.stop(id: id)
        return .result()
    }
}
