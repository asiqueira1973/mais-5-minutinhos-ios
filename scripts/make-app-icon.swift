// Gera o ícone A do design system: fundo #000 e "05" em LED clássico vermelho
// (#FF3B30), com os segmentos apagados a ~16%. Mesma geometria de
// Features/Bedside/LEDClockView.swift (Clock.dc.html).
// Gera PNG sem canal alfa (exigência da App Store para o ícone).
// Uso: swift scripts/make-app-icon.swift <saida.png>
import AppKit
import ImageIO
import UniformTypeIdentifiers

let size: CGFloat = 1024
let red = NSColor(srgbRed: 1, green: 0x3B / 255.0, blue: 0x30 / 255.0, alpha: 1)
let t: CGFloat = 10, g: CGFloat = 1.6
// Segmento horizontal hexagonal (mesma geometria do LEDClockView).
func H(_ x0: CGFloat, _ x1: CGFloat, _ y: CGFloat) -> [CGPoint] {
    [.init(x: x0+g, y: y), .init(x: x0+g+t/2, y: y-t/2), .init(x: x1-g-t/2, y: y-t/2),
     .init(x: x1-g, y: y), .init(x: x1-g-t/2, y: y+t/2), .init(x: x0+g+t/2, y: y+t/2)]
}
// Segmento vertical hexagonal (mesma geometria do LEDClockView).
func V(_ x: CGFloat, _ y0: CGFloat, _ y1: CGFloat) -> [CGPoint] {
    [.init(x: x, y: y0+g), .init(x: x+t/2, y: y0+g+t/2), .init(x: x+t/2, y: y1-g-t/2),
     .init(x: x, y: y1-g), .init(x: x-t/2, y: y1-g-t/2), .init(x: x-t/2, y: y0+g+t/2)]
}
let segs: [Character: [CGPoint]] = ["a": H(5,55,5), "b": V(55,5,50), "c": V(55,50,95), "d": H(5,55,95),
                                    "e": V(5,50,95), "f": V(5,5,50), "g": H(5,55,50)]
let lit: [Character: String] = ["0": "abcdef", "5": "afgcd"]
let skew = tan(-6 * CGFloat.pi / 180)

// Contexto RGB sem alfa (noneSkipLast): o PNG sai sem canal alfa.
let ctx = CGContext(data: nil, width: Int(size), height: Int(size), bitsPerComponent: 8, bytesPerRow: 0,
                    space: CGColorSpace(name: CGColorSpace.sRGB)!,
                    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
ctx.setFillColor(NSColor.black.cgColor)
ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))
// Sistema de coordenadas do SVG (y para baixo), "05" centralizado: largura 68+10+68 = 146 unidades.
let scale: CGFloat = 5.2
let width: CGFloat = 146 * scale, height: CGFloat = 100 * scale
ctx.translateBy(x: (size - width) / 2, y: (size + height) / 2)
ctx.scaleBy(x: scale, y: -scale)
for (i, ch) in "05".enumerated() {
    ctx.saveGState()
    ctx.translateBy(x: CGFloat(i) * 78, y: 0)
    ctx.concatenate(CGAffineTransform(a: 1, b: 0, c: skew, d: 1, tx: 11, ty: 0))
    for (name, pts) in segs {
        ctx.setFillColor(red.withAlphaComponent(lit[ch]!.contains(name) ? 1 : 0.16).cgColor)
        ctx.addLines(between: pts); ctx.closePath(); ctx.fillPath()
    }
    ctx.restoreGState()
}
let url = URL(fileURLWithPath: CommandLine.arguments[1]) as CFURL
let dest = CGImageDestinationCreateWithURL(url, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, ctx.makeImage()!, nil)
CGImageDestinationFinalize(dest)
