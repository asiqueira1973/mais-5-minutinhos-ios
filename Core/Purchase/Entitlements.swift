import Foundation

// O que a compra única libera (regra 11.7). Grátis: tema `led_classico`, cores
// `vermelho` e `ambar`, sons `padrao_iphone` e `bipe_digital` (sons em
// `SoundCatalog`). Alarmes, soneca e modo cabeceira nunca têm limite.
nonisolated enum Entitlements {
    // Nomes exibidos dos temas (design system, lista de temas).
    static func name(_ theme: TemaRelogio) -> String {
        switch theme {
        case .ledClassico: "LED clássico"
        case .digitalFino: "Digital fino"
        case .grandeNegrito: "Grande negrito"
        case .flip: "Flip"
        }
    }

    // Nomes exibidos das cores (design system, tokens de cor).
    static func name(_ color: CorRelogio) -> String {
        switch color {
        case .vermelho: "Vermelho"
        case .ambar: "Âmbar"
        case .verde: "Verde"
        case .azul: "Azul"
        case .branco: "Branco"
        }
    }

    // true para o tema grátis (regra 11.7). Entradas: tema. Saída: se é grátis.
    static func isFree(_ theme: TemaRelogio) -> Bool { theme == .ledClassico }

    // true para as cores grátis (regra 11.7). Entradas: cor. Saída: se é grátis.
    static func isFree(_ color: CorRelogio) -> Bool { color == .vermelho || color == .ambar }

    // Tema que aparece de fato: pago sem compra válida (ex.: reembolso, 8.8) cai
    // para o grátis sem alterar `tema_relogio`, para voltar se a compra for
    // restaurada (mesmo tratamento dos sons, regra 11.6).
    // Entradas: tema salvo e se a compra está válida. Saída: tema efetivo.
    static func effective(_ theme: TemaRelogio, unlocked: Bool) -> TemaRelogio {
        unlocked || isFree(theme) ? theme : .ledClassico
    }

    // Cor que aparece de fato (mesma regra do tema). Entradas: cor salva e compra.
    // Saída: cor efetiva.
    static func effective(_ color: CorRelogio, unlocked: Bool) -> CorRelogio {
        unlocked || isFree(color) ? color : .vermelho
    }
}
