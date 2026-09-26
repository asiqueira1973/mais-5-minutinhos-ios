import Observation
import UIKit

// Entra e sai do modo cabeceira: guarda e restaura brilho e idle timer, força
// paisagem e acompanha o carregador (spec seção 13, épico 8.5).
@MainActor
@Observable
final class BedsideController {
    // true quando o carregador foi desconectado há menos de 10 s (8.5, copy 15.5).
    private(set) var showsChargerWarning = false
    // true enquanto o toque na tela mantém o brilho alto e o botão "Sair" (8.5).
    private(set) var isAwake = false

    private var savedBrightness: CGFloat?
    private var savedIdleTimer = false
    private var nightBrightness: CGFloat = 0.15
    private var awakeTask: Task<Void, Never>?
    private var chargerTask: Task<Void, Never>?
    private var batteryObserver: NSObjectProtocol?

    // Tela ativa do app, de onde vem o brilho (substitui o `UIScreen.main` descontinuado).
    private var screen: UIScreen? { windowScene?.screen }
    private var windowScene: UIWindowScene? {
        UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
    }

    // Entra no modo: idle timer desligado, brilho da cabeceira, paisagem (8.5).
    // Entradas: brilho da noite (`brilho_cabeceira`, 0,05–1,0, seção 7.2).
    // Saída: nenhuma. Guarda os valores anteriores para `exit()`.
    func enter(brightness: Double) {
        nightBrightness = CGFloat(min(max(brightness, 0.05), 1.0))
        savedIdleTimer = UIApplication.shared.isIdleTimerDisabled
        savedBrightness = screen?.brightness
        UIApplication.shared.isIdleTimerDisabled = true
        screen?.brightness = nightBrightness
        setOrientation(.landscape, preferred: .landscapeRight)
        startChargerMonitoring()
    }

    // Sai do modo: restaura idle timer, brilho e retrato (8.5).
    // Entradas: nenhuma. Saída: nenhuma.
    func exit() {
        awakeTask?.cancel()
        chargerTask?.cancel()
        if let batteryObserver { NotificationCenter.default.removeObserver(batteryObserver) }
        batteryObserver = nil
        UIDevice.current.isBatteryMonitoringEnabled = false
        UIApplication.shared.isIdleTimerDisabled = savedIdleTimer
        if let savedBrightness { screen?.brightness = savedBrightness }
        isAwake = false
        showsChargerWarning = false
        setOrientation(.portrait, preferred: .portrait)
    }

    // Toque na tela: brilho a 60% e botão "Sair" por 5 s, depois volta (8.5).
    // Entradas: nenhuma. Saída: nenhuma.
    func wake() {
        isAwake = true
        screen?.brightness = max(nightBrightness, 0.6)
        awakeTask?.cancel()
        awakeTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled, let self else { return }
            self.isAwake = false
            self.screen?.brightness = self.nightBrightness
        }
    }

    // Alarme tocando com o modo cabeceira aberto: sobe o brilho para o mesmo valor
    // do toque (60%) para a pessoa enxergar Soneca/Parar; ao terminar, volta ao
    // brilho da noite (decisão do spike 8.1, ver docs/spike-alarmkit.md).
    // Entradas: true quando começa a tocar, false quando para ou entra em soneca.
    // Saída: nenhuma.
    func setRinging(_ ringing: Bool) {
        awakeTask?.cancel()
        isAwake = false
        screen?.brightness = ringing ? max(nightBrightness, 0.6) : nightBrightness
    }

    // Aplica a trava de orientação e pede a rotação ao sistema.
    // Entradas: máscara permitida e orientação preferida. Saída: nenhuma.
    private func setOrientation(_ mask: UIInterfaceOrientationMask, preferred: UIInterfaceOrientationMask) {
        AppDelegate.orientationLock = mask
        guard let windowScene else { return }
        windowScene.keyWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
        windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: preferred)) { _ in }
    }

    // Observa o estado da bateria; ao desconectar, mostra o aviso por 10 s
    // sem sair do modo (8.5, copy 15.5).
    // Entradas: nenhuma. Saída: nenhuma.
    private func startChargerMonitoring() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        batteryObserver = NotificationCenter.default.addObserver(
            forName: UIDevice.batteryStateDidChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                if UIDevice.current.batteryState == .unplugged { self.flashChargerWarning() }
            }
        }
    }

    // Mostra o aviso de carregador por 10 s. Entradas: nenhuma. Saída: nenhuma.
    private func flashChargerWarning() {
        showsChargerWarning = true
        chargerTask?.cancel()
        chargerTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(10))
            guard !Task.isCancelled else { return }
            self?.showsChargerWarning = false
        }
    }
}
