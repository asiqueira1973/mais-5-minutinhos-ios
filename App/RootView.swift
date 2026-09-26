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
    // Posição do aparelho e carregador (regra 11.4) e última saída manual.
    @State private var device = DevicePositionMonitor()
    @State private var lastManualExit: Date?

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
                    theme: prefs?.tema_relogio ?? .ledClassico,
                    color: cor.color,
                    is24h: is24h,
                    showSeconds: prefs?.mostrar_segundos ?? false,
                    brightness: prefs?.brilho_cabeceira ?? 0.30,
                    position: device.position,
                    nextAlarm: nextAlarmInfo(),
                    isRinging: alertingID != nil,
                    onExit: {
                        // Saída manual: a entrada automática espera 10 min (regra 11.4).
                        lastManualExit = .now
                        showsBedside = false
                    }
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
        .task { await checkAutoEntry() }
        .onChange(of: scenePhase, initial: true) { _, phase in
            if phase == .active {
                BedsideController.restorePendingBrightness()
                device.start()
                Task { await controller.reconcile(in: context) }
            } else {
                device.stop()
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

    // A cada segundo, com o app na frente e fora do modo cabeceira, avalia a
    // entrada automática (regra 11.4).
    // Entradas: nenhuma. Saída: nenhuma (roda enquanto a view existir).
    private func checkAutoEntry() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(1))
            guard !showsBedside, alertingID == nil else { continue }
            let input = AutoEntryInput(
                enabled: prefs?.entrar_automatico ?? true,
                isForeground: scenePhase == .active,
                position: device.position,
                positionSince: device.positionSince,
                isCharging: device.isCharging,
                nextActiveAlarm: nextActiveAlarm(after: .now)?.date,
                lastManualExit: lastManualExit,
                now: .now
            )
            if BedsideAutoEntry.shouldEnter(input) { showsBedside = true }
        }
    }

    // Alarme ativo que toca primeiro a partir de `now` (8.5, regra 11.4).
    // Entradas: instante. Saída: alarme e data, ou nil se não há alarme ativo.
    private func nextActiveAlarm(after now: Date) -> (alarme: Alarme, date: Date)? {
        alarms.filter(\.ativo).compactMap { alarme -> (alarme: Alarme, date: Date)? in
            NextAlarm.date(hora: alarme.hora, minuto: alarme.minuto, dias: alarme.dias_repeticao, after: now)
                .map { (alarme, $0) }
        }.min { $0.date < $1.date }
    }

    // Próximo alarme ativo para o modo cabeceira ("07:00 amanhã", 8.5).
    // Entradas: nenhuma. Saída: hora e dia, ou nil (copy 15.4).
    private func nextAlarmInfo() -> (time: String, day: String)? {
        let now = Date.now
        guard let (alarme, date) = nextActiveAlarm(after: now) else { return nil }
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
