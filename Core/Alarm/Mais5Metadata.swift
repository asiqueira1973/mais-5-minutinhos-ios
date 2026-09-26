import AlarmKit

// Metadados que o app anexa a cada alarme do AlarmKit e que a Live Activity
// da soneca lê para exibir rótulo e cor (spec seção 13, 8.6, 10.9).
// Entradas: rótulo do alarme (nil = "Alarme", copy 15.2) e o id da cor do
// relógio (valor bruto do enum `cor_relogio`, seção 7.2).
// Saída: estrutura codificável trafegada pelo sistema até a widget extension.
nonisolated struct Mais5Metadata: AlarmMetadata {
    var rotulo: String?
    var cor: String

    // Título exibido ao usuário: rótulo ou "Alarme" quando nulo (seção 7.1, copy 15.2).
    // Entradas: nenhuma. Saída: texto do título.
    var displayTitle: String {
        guard let rotulo, !rotulo.isEmpty else { return "Alarme" }
        return rotulo
    }
}
