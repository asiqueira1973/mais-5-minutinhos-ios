import SwiftUI

// Tela única do app do spike (épico 8.1): botões de agendar, log de estados e
// tela de teste que abre sozinha quando o alarme toca com o app aberto (P2).
// TEMPORÁRIO: será removida no épico 8.2.
struct SpikeView: View {
    @State private var model = SpikeModel()
    // Prévia do modo cabeceira (épico 8.5) aberta a partir do spike.
    @State private var showsBedside = false

    var body: some View {
        NavigationStack {
            List {
                Section("Agendar (toca no minuto cheio após +1 min)") {
                    Button("Agendar com som próprio (bipe_digital.caf)") {
                        Task { await model.scheduleTestAlarm(customSound: true) }
                    }
                    Button("Agendar com som padrão do iPhone") {
                        Task { await model.scheduleTestAlarm(customSound: false) }
                    }
                    Button("Cancelar todos", role: .destructive) { model.cancelAll() }
                }
                Section("Prévia") {
                    Button("Ver modo cabeceira") { showsBedside = true }
                }
                Section("Autorização: \(model.authorization)") {
                    Button("Pedir permissão") {
                        Task { await model.requestAuthorization() }
                    }
                }
                Section("Log") {
                    ForEach(Array(model.log.enumerated()), id: \.offset) { _, line in
                        Text(line).font(.caption.monospaced())
                    }
                }
            }
            .navigationTitle("Spike AlarmKit")
        }
        .overlay {
            if showsBedside {
                BedsideView(
                    color: SpikeModel.tint,
                    nextAlarm: model.nextAlarm(),
                    onExit: { showsBedside = false }
                )
            }
        }
        .task { await model.observe() }
        .fullScreenCover(item: Binding(
            get: { model.alertingID.map(AlertingItem.init) },
            set: { if $0 == nil { model.alertingID = nil } }
        )) { item in
            SpikeRingingView(
                onSnooze: { model.snooze(item.id) },
                onStop: { model.stop(item.id) }
            )
            .onAppear { model.record("tela de teste exibida") }
        }
        .preferredColorScheme(.dark)
    }
}

// Envelope identificável para abrir a tela de teste pelo id do alarme.
private struct AlertingItem: Identifiable {
    let id: UUID
}

// Tela de teste do alarme tocando: só Soneca (grande) e Parar (spec 11.5).
// Entradas: ações de soneca e parar. Saída: view.
private struct SpikeRingingView: View {
    let onSnooze: () -> Void
    let onStop: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text(Date.now, style: .time)
                .font(.system(size: 64, weight: .light).monospacedDigit())
                .foregroundStyle(SpikeModel.tint)
                .frame(maxWidth: .infinity, minHeight: 100)
            Button(action: onSnooze) {
                Text("Soneca")
                    .font(.system(size: 64, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(SpikeModel.tint, in: .rect(cornerRadius: 32))
            }
            .frame(maxHeight: .infinity)
            .layoutPriority(2)
            Button(action: onStop) {
                Text("Parar")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(SpikeModel.tint)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(white: 0.11), in: .rect(cornerRadius: 32))
            }
            .frame(height: 200)
        }
        .padding(16)
        .background(.black)
    }
}
