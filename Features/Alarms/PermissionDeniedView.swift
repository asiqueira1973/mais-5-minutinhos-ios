import SwiftUI

// Tela 10.8 — Permissão de alarme negada (sheet, detent medium). Explica e leva
// aos Ajustes do iPhone (seção 5, copy 15.8, design system tela 8).
// Entradas: cor do relógio.
struct PermissionDeniedView: View {
    let tint: Color

    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 16) {
            // "alarm com barra" do design: o SF Symbols não tem `alarm.slash`, então
            // o ícone é `alarm` com `line.diagonal` girada por cima.
            Image(systemName: "alarm")
                .overlay {
                    Image(systemName: "line.diagonal")
                        .rotationEffect(.degrees(90))
                        .fontWeight(.bold)
                }
                .font(.system(size: 60))
                .foregroundStyle(tint)
                .accessibilityHidden(true)
            Text("Alarmes desligados")
                .font(.title2.bold())
            Text("Para o Mais 5 Minutinhos tocar mesmo no silencioso, permita alarmes nos Ajustes do iPhone.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
            } label: {
                Text("Abrir Ajustes")
                    .font(.headline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(tint, in: .rect(cornerRadius: 14))
            }
            .padding(.top, 8)
        }
        .padding(24)
        .presentationDetents([.medium])
    }
}
