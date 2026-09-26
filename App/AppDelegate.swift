import UIKit

// Delegate do app usado só para travar a orientação por tela: o modo cabeceira
// força paisagem (spec 8.5) e o resto do app fica em retrato.
final class AppDelegate: NSObject, UIApplicationDelegate {
    // Orientações permitidas agora; o `BedsideController` troca ao entrar/sair.
    @MainActor static var orientationLock: UIInterfaceOrientationMask = .portrait

    // Informa ao sistema as orientações permitidas no momento.
    // Entradas: app e janela. Saída: máscara de orientações.
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        MainActor.assumeIsolated { Self.orientationLock }
    }
}
