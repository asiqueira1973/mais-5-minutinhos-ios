import SwiftUI

// Tela 10.7 — Paywall (sheet, detent large). O que a compra libera (regra 11.7),
// copy 15.10, comprar e restaurar (design system tela 7).
// Versão do 8.4: conteúdo e layout. Compra, restauração, preço do StoreKit e
// erro sem rede (15.7) entram no épico 8.8.
// Entradas: cor do relógio.
struct PaywallView: View {
    let tint: Color

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color(white: 0.6))
                        .frame(width: 30, height: 30)
                        .background(Color(white: 0x3A / 255), in: .circle)
                        .frame(minWidth: 44, minHeight: 44)
                }
                .accessibilityLabel("Fechar")
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Copy 15.10.
                    Text("Mais 5 Minutinhos completo")
                        .font(.system(size: 28, weight: .bold))
                    Text("Todos os temas, cores e sons. Pague uma vez, use para sempre.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                    colorStrip
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(SoundCatalog.all.filter(\.isPremium)) { option in
                            Label(option.name, systemImage: "speaker.wave.2")
                                .foregroundStyle(.primary)
                        }
                    }
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            VStack(spacing: 12) {
                // Preço fixo da regra 11.7 até o 8.8 trazer o `displayPrice` do StoreKit.
                Text("Comprar por R$ 19,90")
                    .font(.headline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(tint.opacity(0.4), in: .rect(cornerRadius: 14))
                Text("Restaurar compra")
                    .foregroundStyle(tint.opacity(0.4))
            }
            .accessibilityHint("Disponível em breve")
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .presentationDetents([.large])
    }

    // Faixa das 5 cores do relógio (o que a compra libera, regra 11.7).
    private var colorStrip: some View {
        HStack(spacing: 12) {
            ForEach(CorRelogio.allCases, id: \.self) { cor in
                Circle().fill(cor.color).frame(width: 36, height: 36)
            }
        }
        .accessibilityHidden(true)
    }
}
