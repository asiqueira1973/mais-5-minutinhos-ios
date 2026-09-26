import Foundation
import SwiftData

// Plano de migração do SwiftData (seção 7). Hoje só existe a v1 e nenhuma etapa;
// cada schema novo entra em `schemas` com a `MigrationStage` correspondente.
nonisolated enum MigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [SchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}

// Criação do container e garantia do singleton de preferências (seção 7, épico 8.2).
enum Persistence {
    // Cria o container do app com o schema versionado e o plano de migração.
    // Entradas: `inMemory` (true nos testes). Saída: container pronto.
    // Lança erro se o armazenamento não puder ser aberto ou migrado.
    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        if !inMemory {
            // No primeiro launch a pasta ainda não existe; sem ela o CoreData registra
            // erro e só depois se recupera sozinho.
            try FileManager.default.createDirectory(
                at: .applicationSupportDirectory, withIntermediateDirectories: true
            )
        }
        let schema = Schema(versionedSchema: SchemaV1.self)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        return try ModelContainer(
            for: schema,
            migrationPlan: MigrationPlan.self,
            configurations: [configuration]
        )
    }

    // Garante exatamente 1 linha de `preferencias` (seção 7.2, critério de 8.2):
    // cria no primeiro launch e, se por algum motivo houver mais de uma, mantém a
    // primeira e apaga as demais.
    // Entradas: contexto do SwiftData. Saída: a linha única de preferências.
    // Lança o erro do SwiftData se a leitura ou a gravação falhar.
    @discardableResult
    static func ensurePreferences(in context: ModelContext) throws -> Preferencias {
        let existing = try context.fetch(FetchDescriptor<Preferencias>())
        if let first = existing.first {
            for extra in existing.dropFirst() { context.delete(extra) }
            if existing.count > 1 { try context.save() }
            return first
        }
        let preferences = Preferencias()
        context.insert(preferences)
        try context.save()
        return preferences
    }
}
