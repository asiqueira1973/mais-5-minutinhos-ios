import SwiftData
import SwiftUI

// Ponto de entrada do app: cria o container SwiftData versionado, garante o
// singleton de `preferencias` (épico 8.2) e aplica o modo escuro permanente
// (decisão de design). A tela inicial é a lista de alarmes (10.1, via `RootView`).
@main
struct MaisCincoMinutinhosApp: App {
    // Delegate só para travar a orientação (paisagem no modo cabeceira, 8.5).
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    private let container: ModelContainer

    // Abre o banco e cria a linha de preferências no primeiro launch (seção 7.2).
    // Entradas: nenhuma. Saída: app pronto. Falha ao abrir o banco derruba o
    // app: sem banco não há como agendar nem listar alarmes.
    init() {
        do {
            container = try Persistence.makeContainer()
            try Persistence.ensurePreferences(in: container.mainContext)
        } catch {
            fatalError("Não foi possível abrir o banco local: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
