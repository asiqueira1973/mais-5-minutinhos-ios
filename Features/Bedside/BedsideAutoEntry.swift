import CoreMotion
import Foundation
import Observation
import UIKit

// Posição física do iPhone, lida pelo acelerômetro (funciona com o bloqueio de
// rotação ligado; decisão do spike 8.1, docs/spike-alarmkit.md).
nonisolated enum DevicePosition: Equatable, Sendable {
    // De lado, com o lado esquerdo do aparelho para baixo (gravidade em −x):
    // orientação de interface `.landscapeRight`.
    case landscapeLeftSideDown
    // De lado, com o lado direito para baixo (gravidade em +x): `.landscapeLeft`.
    case landscapeRightSideDown
    // Deitado de costas na mesa, tela para cima.
    case faceUp
    // Em pé, na mão ou de bruços.
    case other

    // Classifica a gravidade medida (em g).
    // Entradas: componentes x, y, z. Saída: posição.
    static func from(x: Double, y: Double, z: Double) -> DevicePosition {
        if z < -0.8 { return .faceUp }
        if x < -0.75 { return .landscapeLeftSideDown }
        if x > 0.75 { return .landscapeRightSideDown }
        return .other
    }

    // true nas posições que valem como "paisagem" para a regra 11.4.
    var isBedsidePosition: Bool { self != .other }
}

// Condições da regra 11.4 num instante.
nonisolated struct AutoEntryInput: Sendable {
    var enabled: Bool               // `entrar_automatico`
    var isForeground: Bool          // app em primeiro plano
    var position: DevicePosition    // de lado ou tela para cima
    var positionSince: Date         // desde quando está nessa posição
    var isCharging: Bool            // bateria `charging` ou `full`
    var nextActiveAlarm: Date?      // próximo toque de um alarme ativo
    var lastManualExit: Date?       // última saída pelo botão "Sair"
    var now: Date
}

// Regra 11.4: entrada automática no modo cabeceira.
nonisolated enum BedsideAutoEntry {
    // Janela do próximo alarme (regra 11.4).
    static let alarmWindow: TimeInterval = 14 * 3600
    // Carência depois de sair manualmente (regra 11.4).
    static let manualExitCooldown: TimeInterval = 10 * 60
    // Tempo parado na posição antes de entrar, para não disparar com o iPhone na
    // mão (decisão de implementação, princípio 0.5).
    static let settleTime: TimeInterval = 2

    // Decide se entra. Entra quando todas forem verdadeiras: ligado, primeiro
    // plano, de lado ou tela para cima (há 2 s), carregando, alarme ativo nas
    // próximas 14 h e sem saída manual nos últimos 10 min.
    // Entradas: condições do instante. Saída: true para entrar.
    static func shouldEnter(_ input: AutoEntryInput) -> Bool {
        guard input.enabled, input.isForeground, input.isCharging else { return false }
        guard input.position.isBedsidePosition,
              input.now.timeIntervalSince(input.positionSince) >= settleTime else { return false }
        guard let next = input.nextActiveAlarm,
              next > input.now, next.timeIntervalSince(input.now) <= alarmWindow else { return false }
        if let exit = input.lastManualExit, input.now.timeIntervalSince(exit) < manualExitCooldown {
            return false
        }
        return true
    }
}

// Lê o acelerômetro e a bateria e publica a posição atual (regra 11.4) e o lado
// da paisagem para o modo cabeceira seguir o aparelho.
@MainActor
@Observable
final class DevicePositionMonitor {
    private(set) var position: DevicePosition = .other
    private(set) var positionSince: Date = .now
    private(set) var isCharging = false

    private let motion = CMMotionManager()

    // Começa a ler (2 Hz basta). Entradas: nenhuma. Saída: nenhuma.
    func start() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        updateBattery()
        guard motion.isAccelerometerAvailable, !motion.isAccelerometerActive else { return }
        motion.accelerometerUpdateInterval = 0.5
        motion.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let data else { return }
            MainActor.assumeIsolated {
                self?.update(DevicePosition.from(x: data.acceleration.x, y: data.acceleration.y, z: data.acceleration.z))
            }
        }
    }

    // Para de ler. Entradas: nenhuma. Saída: nenhuma.
    func stop() {
        motion.stopAccelerometerUpdates()
    }

    // Atualiza a posição e a bateria. Entradas: nova posição. Saída: nenhuma.
    private func update(_ new: DevicePosition) {
        if new != position {
            position = new
            positionSince = .now
        }
        updateBattery()
    }

    private func updateBattery() {
        let state = UIDevice.current.batteryState
        isCharging = state == .charging || state == .full
    }
}
