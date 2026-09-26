import SwiftUI

// Ponto de entrada do app. No épico 8.1 abre só o app mínimo do spike do AlarmKit.
@main
struct MaisCincoMinutinhosApp: App {
    // Delegate só para travar a orientação (paisagem no modo cabeceira, 8.5).
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            SpikeView()
        }
    }
}
