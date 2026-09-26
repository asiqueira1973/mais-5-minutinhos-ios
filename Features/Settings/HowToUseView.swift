import SwiftUI

// Tela 10.10 — Como usar (push a partir de "Sobre" nos Ajustes). Copy 15.11,
// aprovada em 26/09/2026. Entradas: cor do relógio (números dos passos).
struct HowToUseView: View {
    let tint: Color

    // Passos da copy 15.11: título em negrito e explicação.
    private static let steps: [(title: String, text: String)] = [
        ("Crie um alarme.", "Toque em + e escolha a hora, os dias e o som."),
        ("À noite, deixe o iPhone no carregador.", "De lado num suporte ou deitado de costas na mesa, o relógio aparece sozinho. Se preferir, toque em \u{201C}Dormir\u{201D}."),
        ("O alarme toca mesmo no silencioso.", "O volume é o de toque do iPhone (Ajustes › Sons e Tato)."),
        ("De manhã, um toque resolve.", "\u{201C}Soneca\u{201D} é o botão grande; \u{201C}Parar\u{201D} fica embaixo. Com a tela bloqueada, deslize para parar."),
        ("Toque no relógio", "para clarear a tela por 5 segundos e ver o botão \u{201C}Sair\u{201D}."),
    ]

    var body: some View {
        List {
            ForEach(Array(Self.steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .firstTextBaseline, spacing: 14) {
                    Text("\(index + 1)")
                        .font(.title3.weight(.bold).monospacedDigit())
                        .foregroundStyle(tint)
                        .frame(minWidth: 20)
                    Text("\(Text(step.title).bold()) \(step.text)")
                        .font(.body)
                }
                .padding(.vertical, 6)
                .accessibilityElement(children: .combine)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Como usar")
    }
}
