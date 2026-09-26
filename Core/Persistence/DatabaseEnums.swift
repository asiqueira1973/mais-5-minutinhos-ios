import Foundation

// Enums do banco local, espelho exato de `modelo-mais-5-minutinhos.dbml` e da
// seção 7 do spec. Nomes de tipo em português (são parte do "banco"); o valor
// bruto armazenado é o nome snake_case do spec.

// Enum `som_alarme` (seção 7.1, regra 11.3): som tocado pelo alarme.
nonisolated enum SomAlarme: String, Codable, CaseIterable, Sendable {
    case padraoIphone = "padrao_iphone"
    case bipeDigital = "bipe_digital"
    case campainhaClassica = "campainha_classica"
    case sino = "sino"
    case despertarSuave = "despertar_suave"
    case passaros = "passaros"
    case pianoManha = "piano_manha"
    case radioRelogio = "radio_relogio"
}

// Enum `tema_relogio` (seção 7.2): desenho do relógio da cabeceira.
nonisolated enum TemaRelogio: String, Codable, CaseIterable, Sendable {
    case ledClassico = "led_classico"
    case digitalFino = "digital_fino"
    case grandeNegrito = "grande_negrito"
    case flip = "flip"
}

// Enum `cor_relogio` (seção 7.2): cor do relógio, também o tint do app (spec 16).
nonisolated enum CorRelogio: String, Codable, CaseIterable, Sendable {
    case vermelho = "vermelho"
    case ambar = "ambar"
    case verde = "verde"
    case azul = "azul"
    case branco = "branco"
}
