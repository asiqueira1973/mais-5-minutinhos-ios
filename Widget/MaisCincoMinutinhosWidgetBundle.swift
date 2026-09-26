import SwiftUI
import WidgetKit

// Pacote da widget extension. Contém só a Live Activity da soneca (spec 4, 8.6);
// o app não tem widgets de tela inicial no MVP.
@main
struct MaisCincoMinutinhosWidgetBundle: WidgetBundle {
    var body: some Widget {
        SnoozeLiveActivity()
    }
}
