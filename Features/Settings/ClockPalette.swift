import SwiftUI

// Cores do relógio do design system (tokens "Cores do relógio"), que também são o
// tint do app (spec 16).
extension CorRelogio {
    // Cor SwiftUI do token. Entradas: nenhuma. Saída: cor sRGB.
    var color: Color {
        switch self {
        case .vermelho: Color(red: 0xFF / 255, green: 0x3B / 255, blue: 0x30 / 255)
        case .ambar: Color(red: 0xFF / 255, green: 0xA1 / 255, blue: 0x0A / 255)
        case .verde: Color(red: 0x34 / 255, green: 0xD1 / 255, blue: 0x58 / 255)
        case .azul: Color(red: 0x3F / 255, green: 0x8C / 255, blue: 0xFF / 255)
        case .branco: Color(red: 0xED / 255, green: 0xED / 255, blue: 0xED / 255)
        }
    }
}
