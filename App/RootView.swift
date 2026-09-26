import AlarmKit
import SwiftData
import SwiftUI

// Raiz do app: lista de alarmes (10.1), modo cabeceira por cima (10.4), alarme
// tocando por cima de tudo (10.5), permissão negada (10.8). Observa o AlarmKit
// (seção 12) e reconcilia a cada volta ao primeiro plano (regra 11.6, 8.3).
struct RootView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Query private var preferences: [Preferencias]
    @Query private var alarms: [Alarme]

    @State private var controller = AlarmController()
    @State private var showsBedside = false
    // Alarme tocando agora, lido de `alarmUpdates` (premissa P2).
    @State private var alertingID: UUID?
    // Últimos ids vistos no AlarmKit, para perceber alarmes que sumiram.
    @State private var knownIDs: Set<UUID> = []

    private var prefs: Preferencias? { preferences.first }
    private var cor: CorRelogio { prefs?.cor_relogio ?? .vermelho }
    private var is24h: Bool { prefs?.formato_24h ?? true }

    var body: some View {
        AlarmListView(controller: controller, is24h: is24h, tint: cor.color) {
            showsBedside = true
        }
        .overlay {
            if showsBedside {
                BedsideView(
                    color: cor.color,
                    brightness: prefs?.brilho_cabeceira ?? 0.30,
                    nextAlarm: nextAlarmInfo(),
                    isRinging: alertingID != nil,
                    onExit: { showsBedside = false }
                )
            }
        }
        .fullScreenCover(item: ringingBinding) { item in
            let alarme = alarms.first { $0.id == item.id }
            RingingView(
                title: Mais5Metadata(rotulo: alarme?.rotulo, cor: cor.rawValue).displayTitle,
                color: cor.color,
                hasSnooze: alarme?.soneca_ativa ?? true,
                onSnooze: { try? AlarmScheduler.shared.snooze(id: item.id); alertingID = nil },
                onStop: { try? AlarmScheduler.shared.stop(id: item.id); alertingID = nil }
            )
        }
        .sheet(isPresented: $controller.showsPermissionDenied) {
            PermissionDeniedView(tint: cor.color)
        }
        .alert(item: $controller.alert) { AlarmAlerts.alert(for: $0) }
        .tint(cor.color)
        .preferredColorScheme(.dark)
        .onAppear { controller.context = context }
        .task { await observeAlarmKit() }
        .onChange(of: scenePhase, initial: true) { _, phase in
            if phase == .active {
                BedsideController.restorePendingBrightness()
                Task { await controller.reconcile(in: context) }
            }
        }
    }

    // Liga a tela 10.5 ao alarme em `alerting`.
    private var ringingBinding: Binding<RingingItem?> {
        Binding(
            get: { alertingID.map(RingingItem.init) },
            set: { if $0 == nil { alertingID = nil } }
        )
    }

    // Acompanha o AlarmKit: abre a 10.5 quando algum alarme toca e reconcilia
    // quando algum some (ex.: toque único parado → `ativo = false`, seção 12).
    // Entradas: nenhuma. Saída: nenhuma (roda enquanto a view existir).
    private func observeAlarmKit() async {
        for await states in AlarmScheduler.shared.observe() {
            alertingID = states.first { $0.value == .alerting }?.key
            let ids = Set(states.keys)
            if !knownIDs.subtracting(ids).isEmpty {
                await controller.reconcile(in: context)
            }
            knownIDs = ids
        }
    }

    // Próximo alarme ativo para o modo cabeceira ("07:00 amanhã", 8.5).
    // Entradas: nenhuma. Saída: hora e dia, ou nil (copy 15.4).
    private func nextAlarmInfo() -> (time: String, day: String)? {
        let now = Date.now
        let next = alarms.filter(\.ativo).compactMap { alarme -> (Alarme, Date)? in
            NextAlarm.date(hora: alarme.hora, minuto: alarme.minuto, dias: alarme.dias_repeticao, after: now)
                .map { (alarme, $0) }
        }.min { $0.1 < $1.1 }
        guard let (alarme, date) = next else { return nil }
        return (
            ClockFormat.text(hora: alarme.hora, minuto: alarme.minuto, is24h: is24h),
            NextAlarm.dayText(for: date, now: now)
        )
    }
}

// Envelope identificável para abrir a 10.5 pelo id do alarme.
struct RingingItem: Identifiable {
    let id: UUID
}
