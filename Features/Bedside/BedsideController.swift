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

    // true entre `enter()` e `exit()`; evita guardar o brilho da noite como "anterior".
    private var isActive = false
    // true quando o app saiu do primeiro plano com o modo aberto (brilho já devolvido).
    private var isSuspended = false
    private var savedBrightness: CGFloat?
    private var savedIdleTimer = false
    private var nightBrightness: CGFloat = 0.30
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
        guard !isActive else { return }
        isActive = true
        isSuspended = false
        nightBrightness = CGFloat(min(max(brightness, 0.05), 1.0))
        applyNightSettings()
        setOrientation(.landscape, preferred: .landscapeRight)
        startChargerMonitoring()
    }

    // Sai do modo: restaura idle timer, brilho e retrato (8.5).
    // Entradas: nenhuma. Saída: nenhuma.
    func exit() {
        guard isActive else { return }
        isActive = false
        awakeTask?.cancel()
        chargerTask?.cancel()
        if let batteryObserver { NotificationCenter.default.removeObserver(batteryObserver) }
        batteryObserver = nil
        UIDevice.current.isBatteryMonitoringEnabled = false
        // Se o app já tinha saído do primeiro plano, o brilho já foi devolvido.
        if !isSuspended { restoreUserSettings() }
        isSuspended = false
        isAwake = false
        showsChargerWarning = false
        setOrientation(.portrait, preferred: .portrait)
    }

    // App saiu do primeiro plano com o modo aberto: devolve brilho e idle timer,
    // porque o iOS mantém o brilho definido pelo app mesmo fora dele (regra 8.5).
    // Entradas: nenhuma. Saída: nenhuma.
    func suspend() {
        guard isActive, !isSuspended else { return }
        isSuspended = true
        awakeTask?.cancel()
        isAwake = false
        restoreUserSettings()
    }

    // App voltou ao primeiro plano com o modo aberto: guarda de novo o brilho da
    // pessoa (pode ter mudado fora do app) e reaplica o da noite (regra 8.5).
    // Entradas: nenhuma. Saída: nenhuma.
    func resume() {
        guard isActive, isSuspended else { return }
        isSuspended = false
        applyNightSettings()
    }

    // Chave do brilho da pessoa ainda não devolvido. Fica no UserDefaults para
    // sobreviver a um fechamento à força com o modo aberto (preferência de aparelho,
    // não é dado do usuário; o spec 7 cobre só alarmes e preferências do app).
    private static let pendingBrightnessKey = "bedside.pendingBrightness"

    // Na abertura do app: se ficou um brilho pendente (app fechado à força no modo
    // cabeceira), devolve e limpa (regra 8.5).
    // Entradas: nenhuma. Saída: nenhuma.
    static func restorePendingBrightness() {
        let defaults = UserDefaults.standard
        guard let value = defaults.object(forKey: pendingBrightnessKey) as? Double else { return }
        defaults.removeObject(forKey: pendingBrightnessKey)
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        scene?.screen.brightness = CGFloat(value)
    }

    // Guarda brilho e idle timer atuais e aplica os da noite.
    // Entradas: nenhuma. Saída: nenhuma.
    private func applyNightSettings() {
        savedIdleTimer = UIApplication.shared.isIdleTimerDisabled
        savedBrightness = screen?.brightness
        if let savedBrightness {
            UserDefaults.standard.set(Double(savedBrightness), forKey: Self.pendingBrightnessKey)
        }
        UIApplication.shared.isIdleTimerDisabled = true
        screen?.brightness = nightBrightness
    }

    // Devolve brilho e idle timer guardados na entrada.
    // Entradas: nenhuma. Saída: nenhuma.
    private func restoreUserSettings() {
        UIApplication.shared.isIdleTimerDisabled = savedIdleTimer
        if let savedBrightness { screen?.brightness = savedBrightness }
        UserDefaults.standard.removeObject(forKey: Self.pendingBrightnessKey)
    }

    // Toque na tela: brilho a 60% e botão "Sair" por 5 s, depois volta (8.5).
    // Entradas: nenhuma. Saída: nenhuma.
    func wake() {
        guard isActive, !isSuspended else { return }
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

    // TEMPORÁRIO (spike): ajusta o brilho da noite ao vivo para achar o padrão de
    // `brilho_cabeceira` (seção 7.2). Mantém os controles visíveis por mais 5 s e
    // mostra na tela o próprio brilho escolhido (não os 60% do toque).
    // Entradas: brilho 0,05–1,0. Saída: nenhuma.
    func tuneNightBrightness(_ value: Double) {
        guard isActive, !isSuspended else { return }
        nightBrightness = CGFloat(min(max(value, 0.05), 1.0))
        screen?.brightness = nightBrightness
        isAwake = true
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
        guard isActive, !isSuspended else { return }
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
