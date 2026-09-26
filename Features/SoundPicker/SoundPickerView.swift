import SwiftUI

// Tela 10.3 — Escolher som (push a partir da 10.2). Seção 1: "Padrão do iPhone";
// seção 2: os 7 sons próprios. `checkmark` no escolhido, `speaker.wave.2` durante
// a prévia, `lock.fill` nos pagos sem compra (design system tela 3, épico 8.4).
// Som pago sem compra: toca a prévia e abre o paywall, sem escolher (decisão
// de Alexandre em 26/09/2026; une o spec 8.4 e o design).
// Entradas: som escolhido (ligação), se a compra está válida e cor.
struct SoundPickerView: View {
    @Binding var selection: SomAlarme
    let premiumUnlocked: Bool
    let tint: Color

    @State private var preview = SoundPreviewPlayer()
    @State private var showsPaywall = false

    // Sons próprios na oferta: nenhum se `customSoundsEnabled == false` (regra 11.3).
    private var customSounds: [SoundOption] {
        SoundCatalog.customSoundsEnabled ? SoundCatalog.all.filter { $0.id != .padraoIphone } : []
    }

    var body: some View {
        List {
            Section {
                row(SoundCatalog.option(.padraoIphone))
            } footer: {
                // Sem prévia: não há como tocar o som do sistema fora do AlarmKit (8.4).
                Text("Som de alarme do próprio iPhone")
            }
            if !customSounds.isEmpty {
                Section {
                    ForEach(customSounds) { row($0) }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Som")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { preview.stop() }
        .sheet(isPresented: $showsPaywall) {
            PaywallView(tint: tint)
        }
    }

    // Linha de um som. Toque: prévia (exceto o padrão) e escolha; se pago sem
    // compra, prévia + paywall. Entradas: opção. Saída: view.
    private func row(_ option: SoundOption) -> some View {
        let locked = option.isPremium && !premiumUnlocked
        return Button {
            if option.id != .padraoIphone { preview.play(option.id) }
            if locked {
                showsPaywall = true
            } else {
                selection = option.id
            }
        } label: {
            HStack {
                Text(option.name).foregroundStyle(.primary)
                Spacer()
                if preview.playing == option.id {
                    Image(systemName: "speaker.wave.2").foregroundStyle(tint)
                }
                if locked {
                    Image(systemName: "lock.fill").foregroundStyle(.tertiary)
                } else if selection == option.id {
                    Image(systemName: "checkmark").foregroundStyle(tint).fontWeight(.semibold)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selection == option.id ? .isSelected : [])
    }
}
