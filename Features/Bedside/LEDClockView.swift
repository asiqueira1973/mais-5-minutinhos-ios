import SwiftUI

// Relógio do tema `led_classico`: dígitos de 7 segmentos desenhados em vetor,
// nunca imagem rasterizada (spec 16). Geometria copiada de `Clock.dc.html` do
// design system: caixa de altura 100, dígito 60×100 em slot 68 com espaço 10,
// segmentos hexagonais de espessura 10 e folga 1,6, inclinação −6°, segmentos
// apagados visíveis a 9% da cor, dois-pontos em quadrados 10×10.
// Entradas: texto da hora ("07:00"), segundos opcionais ("42"), cor, intensidade
// (`dim`, 0–1, opacidade dos segmentos acesos) e alinhamento horizontal.
// Saída: view que ocupa o espaço oferecido mantendo a proporção (aspect fit).
struct LEDClockView: View {
    let time: String
    var seconds: String? = nil
    let color: Color
    var dim: Double = 1
    var alignment: HorizontalAlignment = .center

    var body: some View {
        Canvas { context, size in
            LEDClockGeometry.draw(
                in: &context, size: size, time: time, seconds: seconds,
                color: color, dim: dim, leading: alignment == .leading
            )
        }
        .accessibilityElement()
        .accessibilityLabel(Text(time))
    }
}

// Geometria e desenho dos dígitos de 7 segmentos (design system, `Clock.dc.html`).
// Todas as medidas estão na unidade relativa da caixa de altura 100.
enum LEDClockGeometry {
    static let slot: CGFloat = 68          // largura de um dígito
    static let spacing: CGFloat = 10       // espaço entre caracteres
    static let colonSlot: CGFloat = 22     // largura dos dois-pontos
    static let thickness: CGFloat = 10     // espessura do segmento
    static let gap: CGFloat = 1.6          // folga entre segmentos
    static let offOpacity = 0.09           // segmento apagado a 9% da cor
    static let secondsScale: CGFloat = 0.42 // segundos a 42%, alinhados pela base
    static let skew = tan(-6 * CGFloat.pi / 180)

    // Segmentos acesos por algarismo (a = topo, sentido horário, g = meio).
    static let litSegments: [Character: String] = [
        "0": "abcdef", "1": "bc", "2": "abged", "3": "abgcd", "4": "fgbc",
        "5": "afgcd", "6": "afgedc", "7": "abc", "8": "abcdefg", "9": "abcdfg",
    ]

    // Hexágono horizontal de um segmento. Entradas: x inicial, x final e y do eixo.
    // Saída: vértices do polígono.
    static func horizontal(_ x0: CGFloat, _ x1: CGFloat, _ y: CGFloat) -> [CGPoint] {
        let t = thickness, g = gap
        return [
            .init(x: x0 + g, y: y), .init(x: x0 + g + t / 2, y: y - t / 2),
            .init(x: x1 - g - t / 2, y: y - t / 2), .init(x: x1 - g, y: y),
            .init(x: x1 - g - t / 2, y: y + t / 2), .init(x: x0 + g + t / 2, y: y + t / 2),
        ]
    }

    // Hexágono vertical de um segmento. Entradas: x do eixo, y inicial e y final.
    // Saída: vértices do polígono.
    static func vertical(_ x: CGFloat, _ y0: CGFloat, _ y1: CGFloat) -> [CGPoint] {
        let t = thickness, g = gap
        return [
            .init(x: x, y: y0 + g), .init(x: x + t / 2, y: y0 + g + t / 2),
            .init(x: x + t / 2, y: y1 - g - t / 2), .init(x: x, y: y1 - g),
            .init(x: x - t / 2, y: y1 - g - t / 2), .init(x: x - t / 2, y: y0 + g + t / 2),
        ]
    }

    static let segments: [Character: [CGPoint]] = [
        "a": horizontal(5, 55, 5), "b": vertical(55, 5, 50), "c": vertical(55, 50, 95),
        "d": horizontal(5, 55, 95), "e": vertical(5, 50, 95), "f": vertical(5, 5, 50),
        "g": horizontal(5, 55, 50),
    ]

    // Largura total do texto na unidade relativa (mesma conta do `Clock.dc.html`).
    // Entradas: hora e segundos opcionais. Saída: largura sem o espaço final.
    static func width(time: String, seconds: String?) -> CGFloat {
        var x: CGFloat = 0
        var last: CGFloat = 1
        for ch in time { x += ((ch == ":" ? colonSlot : slot) + spacing); last = 1 }
        if let seconds, !seconds.isEmpty {
            x += spacing * 1.5
            for ch in seconds { x += ((ch == ":" ? colonSlot : slot) + spacing) * secondsScale; last = secondsScale }
        }
        return max(1, x - spacing * last)
    }

    // Desenha o relógio no contexto, com aspect fit e alinhamento pedido.
    // Entradas: contexto, tamanho disponível, textos, cor, intensidade e se alinha
    // à esquerda. Saída: nenhuma (desenha no `context`).
    static func draw(
        in context: inout GraphicsContext, size: CGSize, time: String, seconds: String?,
        color: Color, dim: Double, leading: Bool
    ) {
        // Caixa de visualização do SVG original: x de −2 a largura+2, y de −2 a 102.
        let boxWidth = width(time: time, seconds: seconds) + 4
        let scale = min(size.width / boxWidth, size.height / 104)
        let originX = leading ? 0 : (size.width - boxWidth * scale) / 2
        let originY = (size.height - 104 * scale) / 2
        context.translateBy(x: originX + 2 * scale, y: originY + 2 * scale)
        context.scaleBy(x: scale, y: scale)

        // Apagados ficam a 9% da cor, mas nunca somem com brilho baixo (mínimo 0,6 × 9%).
        let off = offOpacity * max(dim, 0.6)
        var x: CGFloat = 0

        // Desenha um caractere (algarismo ou dois-pontos) na posição x atual.
        func place(_ ch: Character, scale s: CGFloat, y: CGFloat) {
            var glyph = context
            glyph.translateBy(x: x, y: y)
            glyph.scaleBy(x: s, y: s)
            if ch == ":" {
                // Dois-pontos: translate(4,0) skewX(−6), quadrados 10×10 em y=25 e y=65.
                let c = colonSlot / 2
                for top in [CGFloat(25), 65] {
                    let rect = CGRect(x: c - 5, y: top, width: 10, height: 10)
                    let path = Path(roundedRect: rect, cornerRadius: 1)
                        .applying(CGAffineTransform(a: 1, b: 0, c: skew, d: 1, tx: 4, ty: 0))
                    glyph.fill(path, with: .color(color.opacity(dim)))
                }
                x += (colonSlot + spacing) * s
            } else {
                // Dígito: translate(11,0) skewX(−6); cada segmento aceso ou apagado.
                let lit = litSegments[ch] ?? ""
                let transform = CGAffineTransform(a: 1, b: 0, c: skew, d: 1, tx: 11, ty: 0)
                for (name, points) in segments {
                    var path = Path()
                    path.addLines(points)
                    path.closeSubpath()
                    let opacity = lit.contains(name) ? dim : off
                    glyph.fill(path.applying(transform), with: .color(color.opacity(opacity)))
                }
                x += (slot + spacing) * s
            }
        }

        for ch in time { place(ch, scale: 1, y: 0) }
        if let seconds, !seconds.isEmpty {
            x += spacing * 1.5
            // Segundos a 42%, deslocados em y=58 para alinhar pela base.
            for ch in seconds { place(ch, scale: secondsScale, y: 58) }
        }
    }
}

#Preview {
    LEDClockView(time: "23:48", color: Color(red: 1, green: 0.23, blue: 0.19))
        .frame(width: 560, height: 230)
        .background(.black)
}
