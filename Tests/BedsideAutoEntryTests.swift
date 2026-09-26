import Foundation
import Testing
@testable import MaisCincoMinutinhos

// Regra 11.4: entrada automática no modo cabeceira (seção 22).
struct BedsideAutoEntryTests {
    let now = Date(timeIntervalSince1970: 1_800_000_000)

    // Todas as condições verdadeiras; cada teste quebra uma.
    func ready() -> AutoEntryInput {
        AutoEntryInput(
            enabled: true, isForeground: true, position: .landscapeLeftSideDown,
            positionSince: now.addingTimeInterval(-5), isCharging: true,
            nextActiveAlarm: now.addingTimeInterval(8 * 3600), lastManualExit: nil, now: now
        )
    }

    @Test func entersWhenAllConditionsHold() {
        #expect(BedsideAutoEntry.shouldEnter(ready()))
    }

    // Deitado de costas também vale (decisão de Alexandre, 26/09/2026).
    @Test func faceUpCounts() {
        var input = ready()
        input.position = .faceUp
        #expect(BedsideAutoEntry.shouldEnter(input))
    }

    @Test func eachConditionBlocks() {
        var input = ready(); input.enabled = false
        #expect(!BedsideAutoEntry.shouldEnter(input))
        input = ready(); input.isForeground = false
        #expect(!BedsideAutoEntry.shouldEnter(input))
        input = ready(); input.position = .other
        #expect(!BedsideAutoEntry.shouldEnter(input))
        input = ready(); input.isCharging = false
        #expect(!BedsideAutoEntry.shouldEnter(input))
        input = ready(); input.nextActiveAlarm = nil
        #expect(!BedsideAutoEntry.shouldEnter(input))
    }

    // Alarme além de 14 h não conta; dentro de 14 h conta.
    @Test func alarmWindowIs14Hours() {
        var input = ready()
        input.nextActiveAlarm = now.addingTimeInterval(14 * 3600 + 60)
        #expect(!BedsideAutoEntry.shouldEnter(input))
        input.nextActiveAlarm = now.addingTimeInterval(14 * 3600)
        #expect(BedsideAutoEntry.shouldEnter(input))
    }

    // Saída manual há menos de 10 min bloqueia; depois libera.
    @Test func manualExitCooldownIs10Minutes() {
        var input = ready()
        input.lastManualExit = now.addingTimeInterval(-9 * 60)
        #expect(!BedsideAutoEntry.shouldEnter(input))
        input.lastManualExit = now.addingTimeInterval(-11 * 60)
        #expect(BedsideAutoEntry.shouldEnter(input))
    }

    // Recém-deitado (menos de 2 s na posição) ainda não entra.
    @Test func waitsForPositionToSettle() {
        var input = ready()
        input.positionSince = now.addingTimeInterval(-1)
        #expect(!BedsideAutoEntry.shouldEnter(input))
    }

    // Classificação da gravidade (em g) em posição.
    @Test func classifiesGravity() {
        #expect(DevicePosition.from(x: 0, y: 0, z: -1) == .faceUp)
        #expect(DevicePosition.from(x: -0.95, y: 0.1, z: -0.2) == .landscapeLeftSideDown)
        #expect(DevicePosition.from(x: 0.95, y: 0.1, z: -0.2) == .landscapeRightSideDown)
        #expect(DevicePosition.from(x: 0, y: -1, z: 0) == .other)
        #expect(DevicePosition.from(x: 0, y: 0, z: 1) == .other)
    }
}
