import SwiftUI

// Tela 10.5 — Alarme tocando, opção 5A "Blocos" (design system, tela 5). Só:
// hora atual, rótulo ou "Alarme", Soneca (grande, em cima) e Parar (embaixo).
// Um toque, sem confirmação (regra 11.5). Fundo preto puro (spec 16).
// Versão inicial trazida do spike; o épico 8.6 valida proporções e fluxos.
// Entradas: título, cor, se há soneca e as duas ações.
struct RingingView: View {
    let title: String
    let color: Color
    let hasSnooze: Bool
    let onSnooze: () -> Void
    let onStop: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let h = proxy.size.height
            VStack(spacing: 12) {
                header.frame(height: h * 0.13)
                if hasSnooze {
                    // Retrato: Soneca 57% da altura útil, Parar 26% (design, critério 8.6).
                    block("Soneca", icon: "zzz", size: 64, filled: true, action: onSnooze)
                        .frame(height: h * 0.57)
                    block("Parar", icon: nil, size: 48, filled: false, action: onStop)
                        .frame(height: h * 0.26)
                } else {
                    // Sem soneca: só Parar, 60% da altura, ancorado embaixo (regra 11.2).
                    Spacer(minLength: 0)
                    block("Parar", icon: nil, size: 48, filled: false, action: onStop)
                        .frame(height: h * 0.60)
                }
            }
        }
        .padding(16)
        .background(Color.black.ignoresSafeArea())
        .sensoryFeedback(.impact, trigger: hasSnooze)
    }

    // Hora atual no relógio LED e o título do alarme.
    private var header: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            VStack(spacing: 4) {
                LEDClockView(time: BedsideView.timeText(timeline.date), color: color)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(color.opacity(0.6))
                    .lineLimit(1)
            }
        }
    }

    // Bloco de botão da 5A: cheio (fundo na cor, texto #000) ou escuro (#1C1C1E,
    // texto na cor), raio 32. O texto encolhe para caber com Dynamic Type.
    private func block(_ text: String, icon: String?, size: CGFloat, filled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                if let icon { Image(systemName: icon).font(.system(size: 56, weight: .bold)) }
                Text(text).font(.system(size: size, weight: .bold))
            }
            .minimumScaleFactor(0.5)
            .foregroundStyle(filled ? Color.black : color)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(filled ? color : Color(white: 0x1C / 255), in: .rect(cornerRadius: 32))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .heavy), trigger: text)
    }
}
