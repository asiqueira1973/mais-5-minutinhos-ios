import Foundation
import SwiftData

// Versão 1 do schema SwiftData (seção 7). Versionado desde a v1, mesmo com um
// único schema, para as próximas mudanças entrarem por `MigrationPlan` (seção 7).
// Convenção (seção 7/18): classes e propriedades em português, com os nomes
// snake_case do spec. SwiftData não exige camelCase, então o nome da propriedade
// já é o nome armazenado e não é preciso `@Attribute(originalName:)`.
nonisolated enum SchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Alarme.self, Preferencias.self]
    }

    // Tabela `alarme` (seção 7.1): 0 a 10 linhas (regra 11.1), hard delete.
    // O `id` é o mesmo `Alarm.ID` usado no AlarmKit (seção 7.1).
    @Model
    final class Alarme {
        @Attribute(.unique) var id: UUID
        // 0–23.
        var hora: Int
        // 0–59.
        var minuto: Int
        // 1–7, 1 = domingo (padrão `Calendar.weekday`). Vazio = toca uma vez.
        var dias_repeticao: [Int]
        // Nulo quando a pessoa não deu nome; exibido como "Alarme". Máx. 30 caracteres.
        var rotulo: String?
        var som: SomAlarme
        var soneca_ativa: Bool
        // Só 5, 9, 10 ou 15 (regra 11.2).
        var soneca_minutos: Int
        var ativo: Bool
        var criado_em: Date
        // Atualizado a cada edição.
        var atualizado_em: Date

        // Cria um alarme com os defaults da seção 7.1.
        // Entradas: hora e minuto obrigatórios; demais campos opcionais com o default
        // do spec. Saída: alarme novo, ainda não inserido no contexto.
        init(
            id: UUID = UUID(),
            hora: Int,
            minuto: Int,
            dias_repeticao: [Int] = [],
            rotulo: String? = nil,
            som: SomAlarme = .padraoIphone,
            soneca_ativa: Bool = true,
            soneca_minutos: Int = 9,
            ativo: Bool = true,
            criado_em: Date = .now,
            atualizado_em: Date = .now
        ) {
            self.id = id
            self.hora = hora
            self.minuto = minuto
            self.dias_repeticao = dias_repeticao
            self.rotulo = rotulo
            self.som = som
            self.soneca_ativa = soneca_ativa
            self.soneca_minutos = soneca_minutos
            self.ativo = ativo
            self.criado_em = criado_em
            self.atualizado_em = atualizado_em
        }
    }

    // Tabela `preferencias` (seção 7.2): singleton, exatamente 1 linha criada no
    // primeiro launch. A compra não fica aqui; vem de `Transaction.currentEntitlements`.
    @Model
    final class Preferencias {
        @Attribute(.unique) var id: UUID
        var tema_relogio: TemaRelogio
        var cor_relogio: CorRelogio
        var formato_24h: Bool
        var mostrar_segundos: Bool
        // 0,05–1,0. Default 0,30 desde o spike 8.1 (docs/spike-alarmkit.md).
        var brilho_cabeceira: Double
        // Regra 11.4.
        var entrar_automatico: Bool

        // Cria a linha de preferências com os defaults da seção 7.2.
        // Entradas: nenhuma obrigatória. Saída: preferências novas, não inseridas.
        init(
            id: UUID = UUID(),
            tema_relogio: TemaRelogio = .ledClassico,
            cor_relogio: CorRelogio = .vermelho,
            formato_24h: Bool = true,
            mostrar_segundos: Bool = false,
            brilho_cabeceira: Double = 0.30,
            entrar_automatico: Bool = true
        ) {
            self.id = id
            self.tema_relogio = tema_relogio
            self.cor_relogio = cor_relogio
            self.formato_24h = formato_24h
            self.mostrar_segundos = mostrar_segundos
            self.brilho_cabeceira = brilho_cabeceira
            self.entrar_automatico = entrar_automatico
        }
    }
}

// Nomes curtos para o schema atual; o resto do app usa só estes.
typealias Alarme = SchemaV1.Alarme
typealias Preferencias = SchemaV1.Preferencias
