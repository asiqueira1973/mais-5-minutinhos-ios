import AVFoundation
import Observation

// Prévia dos sons na tela 10.3 (épico 8.4): até 5 s, categoria `.playback` para
// tocar mesmo no silencioso; tocar outro som ou sair da tela interrompe.
@MainActor
@Observable
final class SoundPreviewPlayer {
    // Som tocando agora (mostra `speaker.wave.2` na linha, design system tela 3).
    private(set) var playing: SomAlarme?

    // Duração máxima da prévia (8.4).
    static let maxDuration: Duration = .seconds(5)

    private var player: AVAudioPlayer?
    private var stopTask: Task<Void, Never>?

    // Toca a prévia de um som próprio. `padrao_iphone` não tem prévia: não há API
    // pública para tocar o som de alarme do sistema fora do AlarmKit (8.4).
    // Entradas: som. Saída: nenhuma (para a prévia anterior antes).
    func play(_ id: SomAlarme) {
        stop()
        guard let file = SoundCatalog.option(id).fileName,
              let url = Bundle.main.url(forResource: file, withExtension: nil) else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            let player = try AVAudioPlayer(contentsOf: url)
            player.play()
            self.player = player
            playing = id
            stopTask = Task { [weak self] in
                try? await Task.sleep(for: Self.maxDuration)
                guard !Task.isCancelled else { return }
                self?.stop()
            }
        } catch {
            playing = nil
        }
    }

    // Para a prévia e libera a sessão de áudio para outros apps.
    // Entradas: nenhuma. Saída: nenhuma.
    func stop() {
        stopTask?.cancel()
        stopTask = nil
        guard player != nil else { return }
        player?.stop()
        player = nil
        playing = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
