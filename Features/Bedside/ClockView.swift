import SwiftUI

// Relógio no tema escolhido (`tema_relogio`, seção 7.2; design system,
// "Relógio: 4 temas"). Usado no modo cabeceira (10.4), na tela 10.5 e na prévia
// dos Ajustes (10.6).
// Entradas: tema, hora ("07:00"), segundos opcionais ("42"), sufixo AM/PM opcional
// (regra 11.8), cor, intensidade e alinhamento. Saída: view com aspect fit.
struct ClockView: View {
    let theme: TemaRelogio
    let time: String
    var seconds: String? = nil
    var suffix: String? = nil
    let color: Color
    var dim: Double = 1
    var alignment: HorizontalAlignment = .center

    var body: some View {
        Group {
            switch theme {
            case .ledClassico, .flip:
                HStack(alignment: .bottom, spacing: 0) {
                    // A caixa tem a proporção do próprio desenho, para o AM/PM ficar
                    // colado aos dígitos e o alinhamento funcionar.
                    drawing.aspectRatio(aspect, contentMode: .fit)
                    if let suffix {
                        // Regra 11.8: "AM/PM" pequeno ao lado.
                        Text(suffix)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(color.opacity(dim))
                            .padding(.leading, 8)
                            .fixedSize()
                    }
                }
            case .digitalFino:
                // Numerais finos e altos: SF Pro ultraleve comprimida (design system).
                FittedTextClock(time: time, seconds: seconds, suffix: suffix, color: color, dim: dim,
                                alignment: alignment,
                                font: { .system(size: $0, weight: .ultraLight).width(.compressed) })
            case .grandeNegrito:
                // Numerais pesados: SF Pro Black (design system).
                FittedTextClock(time: time, seconds: seconds, suffix: suffix, color: color, dim: dim,
                                alignment: alignment,
                                font: { .system(size: $0, weight: .black) })
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: Alignment(horizontal: alignment, vertical: .center))
        .accessibilityElement()
        .accessibilityLabel(Text([time, suffix].compactMap { $0 }.joined(separator: " ")))
    }

    // Proporção largura/altura dos temas desenhados (altura 100 do design).
    private var aspect: CGFloat {
        theme == .flip
            ? FlipClock.width(time, seconds) / 100
            : (LEDClockGeometry.width(time: time, seconds: seconds) + 4) / 104
    }

    // Desenho dos temas vetoriais.
    @ViewBuilder private var drawing: some View {
        if theme == .flip {
            FlipClock(time: time, seconds: seconds, color: color, dim: dim)
        } else {
            LEDClockView(time: time, seconds: seconds, color: color, dim: dim, alignment: alignment)
        }
    }
}

// Temas de texto (`digital_fino`, `grande_negrito`): mede o texto no tamanho
// natural e amplia até caber, mantendo segundos a 42% (design system) e o
// AM/PM pequeno ao lado (regra 11.8).
// Entradas: textos, cor, intensidade, alinhamento e fábrica da fonte por tamanho.
private struct FittedTextClock: View {
    let time: String
    let seconds: String?
    let suffix: String?
    let color: Color
    let dim: Double
    let alignment: HorizontalAlignment
    let font: (CGFloat) -> Font

    // Corpo de referência para medir; o resultado é escalado.
    private static let reference: CGFloat = 200
    @State private var natural: CGSize = .zero

    var body: some View {
        GeometryReader { proxy in
            let scale = natural.width > 0 && natural.height > 0
                ? min(proxy.size.width / natural.width, proxy.size.height / natural.height)
                : 0
            let anchor: UnitPoint = alignment == .leading ? .leading : .center
            content
                .fixedSize()
                .onGeometryChange(for: CGSize.self, of: { $0.size }) { natural = $0 }
                .scaleEffect(scale, anchor: anchor)
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: Alignment(horizontal: alignment, vertical: .center))
        }
    }

    // Texto no corpo de referência.
    private var content: some View {
        HStack(alignment: .lastTextBaseline, spacing: Self.reference * 0.05) {
            Text(time).font(font(Self.reference))
            if let seconds {
                Text(seconds).font(font(Self.reference * 0.42))
            }
            if let suffix {
                Text(suffix).font(.system(size: Self.reference * 0.16, weight: .semibold))
            }
        }
        .monospacedDigit()
        .foregroundStyle(color.opacity(dim))
        .lineLimit(1)
    }
}

// Tema `flip`: uma placa por dígito, 74×100, raio 8, fundo #171717 com metade de
// baixo #131313, dobradiça preta de 2,4 no meio, pinos laterais #2A2A2A, numeral
// condensado seminegrito na cor; dois-pontos em círculos r 4,5 (design system).
// Entradas: textos, cor e intensidade.
struct FlipClock: View {
    let time: String
    let seconds: String?
    let color: Color
    let dim: Double

    // Medidas na unidade relativa da caixa de altura 100 (Clock.dc.html).
    private static let plateWidth: CGFloat = 74
    private static let colonWidth: CGFloat = 18
    private static let spacing: CGFloat = 6

    // Largura total na unidade relativa. Entradas: textos. Saída: largura.
    static func width(_ time: String, _ seconds: String?) -> CGFloat {
        var x: CGFloat = 0
        for ch in time { x += (ch == ":" ? colonWidth : plateWidth) + spacing }
        if let seconds {
            x += spacing * 1.5
            for ch in seconds { x += ((ch == ":" ? colonWidth : plateWidth) + spacing) * 0.42 }
        }
        return x - spacing
    }

    var body: some View {
        GeometryReader { proxy in
            let unit = min(proxy.size.width / Self.width(time, seconds), proxy.size.height / 100)
            HStack(alignment: .bottom, spacing: Self.spacing * unit) {
                glyphs(time, unit: unit)
                if let seconds {
                    glyphs(seconds, unit: unit * 0.42)
                        .padding(.leading, Self.spacing * 0.5 * unit)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }

    // Placas e dois-pontos de um texto. Entradas: texto e escala. Saída: view.
    private func glyphs(_ text: String, unit: CGFloat) -> some View {
        HStack(spacing: Self.spacing * unit) {
            ForEach(Array(text.enumerated()), id: \.offset) { _, ch in
                if ch == ":" {
                    VStack(spacing: 31 * unit) {
                        Circle().frame(width: 9 * unit, height: 9 * unit)
                        Circle().frame(width: 9 * unit, height: 9 * unit)
                    }
                    .foregroundStyle(color.opacity(dim))
                    .frame(width: Self.colonWidth * unit, height: 100 * unit)
                } else {
                    plate(String(ch), unit: unit)
                }
            }
        }
    }

    // Uma placa com o numeral. Entradas: dígito e escala. Saída: view.
    private func plate(_ digit: String, unit: CGFloat) -> some View {
        let w = Self.plateWidth * unit, h = 100 * unit
        return ZStack {
            RoundedRectangle(cornerRadius: 8 * unit).fill(Color(white: 0x17 / 255))
            // Metade de baixo um pouco mais escura.
            Rectangle().fill(Color(white: 0x13 / 255))
                .frame(height: 41 * unit)
                .offset(y: (51 + 41 / 2 - 50) * unit)
            Text(digit)
                .font(.system(size: 92 * unit, weight: .semibold).width(.condensed))
                .foregroundStyle(color.opacity(dim))
            // Dobradiça preta no meio.
            Rectangle().fill(.black).frame(height: 2.4 * unit)
            // Pinos laterais.
            HStack {
                pin(unit)
                Spacer()
                pin(unit)
            }
            .padding(.horizontal, -1 * unit)
        }
        .frame(width: w, height: h)
        .clipShape(RoundedRectangle(cornerRadius: 8 * unit))
    }

    // Pino lateral da placa (#2A2A2A, 3×12). Entradas: escala. Saída: view.
    private func pin(_ unit: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 1 * unit)
            .fill(Color(white: 0x2A / 255))
            .frame(width: 3 * unit, height: 12 * unit)
    }
}
