import SwiftUI

// Tela 10.5 — Alarme tocando, opção 5A "Blocos" (design system, tela 5). Só:
// hora atual no tema/cor do relógio, rótulo ou "Alarme", Soneca (grande, em cima)
// e Parar (embaixo). Um toque, sem confirmação (regra 11.5). Fundo preto puro.
// Entradas: título, tema, cor, formato 24h, se há soneca e as duas ações.
struct RingingView: View {
    let title: String
    var theme: TemaRelogio = .ledClassico
    let color: Color
    var is24h = true
    let hasSnooze: Bool
    let onSnooze: () -> Void
    let onStop: () -> Void

    // Dispara o haptic a cada toque (design: "Haptic ao tocar").
    @State private var taps = 0

    // Proporções do design em pontos: retrato 751 pt úteis (cabeçalho 100, Soneca
    // 430 = 57%, Parar 197 = 26%, 2 espaços de 12); paisagem 357 pt (44, 200 = 56%,
    // 97 = 27%, 2 espaços de 8). Critério 8.6: Soneca ≥ 55%, Parar ≥ 25%.
    private struct Layout {
        let header: CGFloat, snooze: CGFloat, stop: CGFloat, spacing: CGFloat
        var total: CGFloat { header + snooze + stop + 2 * spacing }
    }
    private static let portrait = Layout(header: 100, snooze: 430, stop: 197, spacing: 12)
    private static let landscape = Layout(header: 44, snooze: 200, stop: 97, spacing: 8)

    var body: some View {
        GeometryReader { proxy in
            let isLandscape = proxy.size.width > proxy.size.height
            let layout = isLandscape ? Self.landscape : Self.portrait
            // Escala as medidas do design para a altura útil deste aparelho.
            let k = proxy.size.height / layout.total
            VStack(spacing: layout.spacing * k) {
                header(isLandscape: isLandscape)
                    .frame(height: layout.header * k)
                if hasSnooze {
                    block("Soneca", icon: "zzz", size: isLandscape ? 56 : 64, filled: true, action: onSnooze)
                        .frame(height: layout.snooze * k)
                    block("Parar", icon: nil, size: isLandscape ? 40 : 48, filled: false, action: onStop)
                        .frame(height: layout.stop * k)
                } else {
                    // Sem soneca: só Parar, 60% da altura útil, ancorado embaixo (regra 11.2).
                    Spacer(minLength: 0)
                    block("Parar", icon: nil, size: isLandscape ? 44 : 52, filled: false, action: onStop)
                        .frame(height: proxy.size.height * 0.60)
                }
            }
        }
        .padding(.horizontal, 16)
        .background(Color.black.ignoresSafeArea())
        .sensoryFeedback(.impact(weight: .heavy), trigger: taps)
        .statusBarHidden()
    }

    // Hora atual no tema do relógio e o título do alarme (em linha na paisagem).
    // Entradas: se está em paisagem. Saída: view.
    private func header(isLandscape: Bool) -> some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            let parts = Calendar.current.dateComponents([.hour, .minute], from: timeline.date)
            let time = ClockFormat.parts(hora: parts.hour ?? 0, minuto: parts.minute ?? 0, is24h: is24h)
            let clock = ClockView(theme: theme, time: time.time, suffix: time.suffix, color: color,
                                  alignment: isLandscape ? .leading : .center)
            let label = Text(title)
                .font(.headline)
                .foregroundStyle(color.opacity(0.6))
                .lineLimit(1)
            if isLandscape {
                HStack(spacing: 16) {
                    clock
                    label.frame(maxWidth: .infinity, alignment: .trailing)
                }
            } else {
                VStack(spacing: 4) {
                    clock
                    label
                }
            }
        }
    }

    // Bloco de botão da 5A: cheio (fundo na cor, texto #000, raio 32) ou escuro
    // (#1C1C1E, texto na cor). O texto encolhe para caber com Dynamic Type; a
    // área de toque é o bloco inteiro (≥ 88 pt, critério 8.6).
    // Entradas: texto, ícone, corpo, se é cheio e ação. Saída: view.
    private func block(_ text: String, icon: String?, size: CGFloat, filled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            taps += 1
            action()
        } label: {
            HStack(spacing: 16) {
                if let icon { Image(systemName: icon).font(.system(size: size * 0.85, weight: .bold)) }
                Text(text).font(.system(size: size, weight: .bold))
            }
            .minimumScaleFactor(0.5)
            .lineLimit(1)
            .foregroundStyle(filled ? Color.black : color)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .frame(minHeight: 88)
            .background(filled ? color : Color(white: 0x1C / 255), in: .rect(cornerRadius: 32))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
