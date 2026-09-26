import Foundation
import SwiftData
import Testing
@testable import MaisCincoMinutinhos

// Testes da camada de persistência (épico 8.2, seção 7).
@MainActor
struct PersistenceTests {
    // Critério 8.2: o primeiro launch cria exatamente 1 linha de `preferencias`,
    // e launches seguintes não criam outra.
    @Test func firstLaunchCreatesExactlyOnePreferencesRow() throws {
        let container = try Persistence.makeContainer(inMemory: true)
        let context = container.mainContext

        try Persistence.ensurePreferences(in: context)
        try Persistence.ensurePreferences(in: context)

        #expect(try context.fetchCount(FetchDescriptor<Preferencias>()) == 1)
    }

    // Se houver linhas duplicadas, sobra exatamente uma (seção 7.2, singleton).
    @Test func duplicatePreferencesAreCollapsed() throws {
        let container = try Persistence.makeContainer(inMemory: true)
        let context = container.mainContext
        context.insert(Preferencias())
        context.insert(Preferencias())
        try context.save()

        try Persistence.ensurePreferences(in: context)

        #expect(try context.fetchCount(FetchDescriptor<Preferencias>()) == 1)
    }

    // Defaults da seção 7.2 (brilho 0,30 desde o spike 8.1).
    @Test func preferencesDefaultsMatchSpec() {
        let preferences = Preferencias()
        #expect(preferences.tema_relogio == .ledClassico)
        #expect(preferences.cor_relogio == .vermelho)
        #expect(preferences.formato_24h)
        #expect(!preferences.mostrar_segundos)
        #expect(preferences.brilho_cabeceira == 0.30)
        #expect(preferences.entrar_automatico)
    }

    // Defaults da seção 7.1.
    @Test func alarmDefaultsMatchSpec() {
        let alarm = Alarme(hora: 7, minuto: 0)
        #expect(alarm.dias_repeticao.isEmpty)
        #expect(alarm.rotulo == nil)
        #expect(alarm.som == .padraoIphone)
        #expect(alarm.soneca_ativa)
        #expect(alarm.soneca_minutos == 9)
        #expect(alarm.ativo)
    }

    // O alarme salvo volta do banco com os mesmos valores, inclusive enum e lista.
    @Test func alarmRoundTrips() throws {
        let container = try Persistence.makeContainer(inMemory: true)
        let context = container.mainContext
        let alarm = Alarme(hora: 6, minuto: 45, dias_repeticao: [2, 3, 4, 5, 6], rotulo: "Trabalho", som: .sino)
        context.insert(alarm)
        try context.save()

        let fetched = try #require(try context.fetch(FetchDescriptor<Alarme>()).first)
        #expect(fetched.id == alarm.id)
        #expect(fetched.dias_repeticao == [2, 3, 4, 5, 6])
        #expect(fetched.som == .sino)
        #expect(fetched.rotulo == "Trabalho")
    }

    // Os valores armazenados dos enums são exatamente os do `.dbml` (seção 7).
    @Test func enumRawValuesMatchDatabaseModel() {
        #expect(SomAlarme.allCases.map(\.rawValue) == [
            "padrao_iphone", "bipe_digital", "campainha_classica", "sino",
            "despertar_suave", "passaros", "piano_manha", "radio_relogio",
        ])
        #expect(TemaRelogio.allCases.map(\.rawValue) == ["led_classico", "digital_fino", "grande_negrito", "flip"])
        #expect(CorRelogio.allCases.map(\.rawValue) == ["vermelho", "ambar", "verde", "azul", "branco"])
    }
}
