import SwiftUI

// Tela 10.7 — Paywall (sheet, detent large). O que a compra libera (regra 11.7),
// copy 15.10, comprar pelo preço do StoreKit, restaurar, e erro sem rede 15.7
// (design system tela 7, épico 8.8). Fecha sozinho quando a compra é liberada.
// Entradas: cor do relógio. Lê o `PurchaseStore` do ambiente.
struct PaywallView: View {
    let tint: Color

    @Environment(PurchaseStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    // Uma cor por miniatura de tema, como no design ("cada uma numa cor").
    private static let thumbnailColors: [CorRelogio] = [.vermelho, .ambar, .verde, .azul]

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
                VStack(alignment: .leading, spacing: 20) {
                    // Copy 15.10.
                    Text("Mais 5 Minutinhos completo")
                        .font(.system(size: 28, weight: .bold))
                    Text("Todos os temas, cores e sons. Pague uma vez, use para sempre.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                    themeStrip
                    colorStrip
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(SoundCatalog.all.filter(\.isPremium)) { option in
                            Label(option.name, systemImage: "speaker.wave.2")
                                .foregroundStyle(.primary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            actions
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .presentationDetents([.large])
        .task { await store.loadProduct() }
        .onChange(of: store.isUnlocked) { _, unlocked in
            if unlocked { dismiss() }
        }
    }

    // Comprar (altura 52, raio 14, fundo na cor, texto #000) e restaurar. Sem
    // rede: botão desabilitado + copy 15.7, sem travar (critério de 8.8).
    private var actions: some View {
        VStack(spacing: 12) {
            if store.isOffline {
                Text("Sem conexão. Tente de novo quando estiver online.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            Button {
                Task { await store.purchase() }
            } label: {
                Group {
                    if let price = store.product?.displayPrice {
                        Text("Comprar por \(price)")
                    } else if store.isOffline {
                        Text("Comprar")
                    } else {
                        ProgressView().tint(.black)
                    }
                }
                .font(.headline)
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(tint.opacity(canBuy ? 1 : 0.4), in: .rect(cornerRadius: 14))
            }
            .disabled(!canBuy)
            Button("Restaurar compra") {
                Task { await store.restore() }
            }
            .foregroundStyle(tint)
            .disabled(store.isBusy)
            .frame(minHeight: 44)
        }
        .padding(.top, 8)
    }

    private var canBuy: Bool { store.product != nil && !store.isBusy }

    // Miniaturas dos 4 temas em linha, cada uma numa cor (design).
    private var themeStrip: some View {
        HStack(spacing: 8) {
            ForEach(Array(TemaRelogio.allCases.enumerated()), id: \.offset) { index, theme in
                ClockView(theme: theme, time: "07:00", color: Self.thumbnailColors[index].color)
                    .padding(6)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(.black, in: .rect(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(white: 0x38 / 255), lineWidth: 1))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("4 temas de relógio")
    }

    // Faixa das 5 cores do relógio (o que a compra libera, regra 11.7).
    private var colorStrip: some View {
        HStack(spacing: 12) {
            ForEach(CorRelogio.allCases, id: \.self) { cor in
                Circle().fill(cor.color).frame(width: 36, height: 36)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("5 cores")
    }
}
