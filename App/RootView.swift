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
    // Compra única (épico 8.8): fonte do desbloqueio, disponível para todas as telas.
    @State private var store = PurchaseStore()
    @State private var showsBedside = false
    // Alarme tocando agora, lido de `alarmUpdates` (premissa P2).
    @State private var alertingID: UUID?
    // Últimos ids vistos no AlarmKit, para perceber alarmes que sumiram.
    @State private var knownIDs: Set<UUID> = []
    // Posição do aparelho e carregador (regra 11.4) e última saída manual.
    @State private var device = DevicePositionMonitor()
    @State private var lastManualExit: Date?
    // Fim de cada soneca em andamento (spec 8.6: "Soneca até 07:09"). O AlarmKit
    // não informa a hora do fim; ela é calculada quando o alarme entra em
    // `countdown`: agora + `soneca_minutos` do alarme.
    @State private var snoozes: [UUID: Date] = [:]

    private var prefs: Preferencias? { preferences.first }
    // Cor e tema efetivos: pagos sem compra válida caem para os grátis (regra 11.7).
    private var cor: CorRelogio { Entitlements.effective(prefs?.cor_relogio ?? .vermelho, unlocked: controller.premiumUnlocked) }
    private var theme: TemaRelogio { Entitlements.effective(prefs?.tema_relogio ?? .ledClassico, unlocked: controller.premiumUnlocked) }
    private var is24h: Bool { prefs?.formato_24h ?? true }

    var body: some View {
        AlarmListView(controller: controller, is24h: is24h, tint: cor.color) {
            showsBedside = true
        }
        .overlay {
            if showsBedside {
                BedsideView(
                    theme: theme,
                    color: cor.color,
                    is24h: is24h,
                    showSeconds: prefs?.mostrar_segundos ?? false,
                    brightness: prefs?.brilho_cabeceira ?? 0.30,
                    position: device.position,
                    nextAlarm: nextAlarmInfo(),
                    snoozeUntil: snoozeText(),
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
                theme: theme,
                color: cor.color,
                is24h: is24h,
                hasSnooze: alarme?.soneca_ativa ?? true,
                onSnooze: { try? AlarmScheduler.shared.snooze(id: item.id); alertingID = nil },
                onStop: { try? AlarmScheduler.shared.stop(id: item.id); alertingID = nil }
            )
        }
        .sheet(isPresented: $controller.showsPermissionDenied) {
            PermissionDeniedView(tint: cor.color)
        }
        .alert(item: $controller.alert) { AlarmAlerts.alert(for: $0) }
        .environment(store)
        .tint(cor.color)
        .preferredColorScheme(.dark)
        .onAppear { store.start() }
        // Compra, restauração ou reembolso: libera ou retira na hora, sem reiniciar,
        // e reagenda os alarmes com o som e a cor efetivos (critérios de 8.8, 11.6).
        .onChange(of: store.isUnlocked, initial: true) { _, unlocked in
            guard store.hasLoadedEntitlement else { return }
            Task { await controller.applyEntitlement(unlocked, in: context) }
        }
        // Primeira leitura da compra: só então o estado é confiável para aplicar.
        .onChange(of: store.hasLoadedEntitlement) { _, loaded in
            guard loaded else { return }
            Task { await controller.applyEntitlement(store.isUnlocked, in: context) }
        }
        .onAppear { controller.context = context }
        .task { await observeAlarmKit() }
        .task { await checkAutoEntry() }
        #if DEBUG
        .onAppear { applyDebugLaunchArguments() }
        #endif
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
            AlarmLog.log("alarmUpdates: \(states.map { "\(AlarmLog.short($0.key))=\($0.value)" }.sorted())")
            alertingID = states.first { $0.value == .alerting }?.key
            trackSnoozes(states)
            let ids = Set(states.keys)
            if !knownIDs.subtracting(ids).isEmpty {
                await controller.reconcile(in: context)
            }
            knownIDs = ids
        }
    }

    // Atualiza o fim das sonecas: registra quando um alarme entra em `countdown`
    // e esquece quando sai (volta a tocar, é parado ou cancelado).
    // Entradas: estado de cada alarme. Saída: nenhuma.
    private func trackSnoozes(_ states: [UUID: Alarm.State]) {
        for (id, state) in states where state == .countdown && snoozes[id] == nil {
            let minutes = alarms.first { $0.id == id }?.soneca_minutos ?? 9
            snoozes[id] = Date.now.addingTimeInterval(TimeInterval(minutes * 60))
        }
        for id in snoozes.keys where states[id] != .countdown {
            snoozes[id] = nil
        }
    }

    // "Soneca até 07:09" da soneca que termina primeiro (spec 8.6), ou nil.
    // Entradas: nenhuma. Saída: hora formatada conforme `formato_24h`.
    private func snoozeText() -> String? {
        guard let end = snoozes.values.min() else { return nil }
        let parts = Calendar.current.dateComponents([.hour, .minute], from: end)
        return ClockFormat.text(hora: parts.hour ?? 0, minuto: parts.minute ?? 0, is24h: is24h)
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

#if DEBUG
// Ganchos de depuração da raiz (só em DEBUG).
extension RootView {
    // SÓ DEPURAÇÃO (não entra na build da loja): simula estados para conferir as
    // telas no simulador sem tocar alarme de verdade.
    // `-debugRinging YES` abre a 10.5; `-debugSnooze YES` abre a cabeceira em soneca;
    // `-debugBedside YES` abre a cabeceira; `-debugSeedAlarms YES` cria alarmes de exemplo (prints da App Store) se a
    // lista estiver vazia.
    // Entradas: argumentos de abertura. Saída: nenhuma.
    fileprivate func applyDebugLaunchArguments() {
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: "debugSeedAlarms"), alarms.isEmpty {
            let samples: [(Int, Int, [Int], String?, Bool)] = [
                (5, 45, [2, 3, 4, 5, 6], "Academia", true),
                (6, 30, [2, 4, 6], "Natação", true),
                (7, 0, [1, 7], "Corrida", true),
                (9, 0, [], nil, false),
            ]
            for (hora, minuto, dias, rotulo, ativo) in samples {
                context.insert(Alarme(hora: hora, minuto: minuto, dias_repeticao: dias, rotulo: rotulo, ativo: ativo))
            }
            try? context.save()
        }
        // Espera a primeira leitura do AlarmKit, que zeraria o estado simulado.
        if defaults.bool(forKey: "debugRinging") {
            Task {
                try? await Task.sleep(for: .seconds(1))
                // Usa um alarme existente (mostra o rótulo), senão um id qualquer.
                // O alarme da hora fixada em `-debugClockTime`, senão o primeiro com rótulo.
                let shown = Calendar.current.dateComponents([.hour, .minute], from: DebugClock.display(.now))
                alertingID = (alarms.first { $0.hora == shown.hour && $0.minuto == shown.minute }
                    ?? alarms.first { $0.rotulo != nil })?.id ?? UUID()
            }
        }
        if defaults.bool(forKey: "debugBedside") { showsBedside = true }
        if defaults.bool(forKey: "debugSnooze") {
            showsBedside = true
            Task {
                try? await Task.sleep(for: .seconds(1))
                snoozes[UUID()] = DebugClock.display(.now).addingTimeInterval(9 * 60)
            }
        }
    }
}
#endif

// Envelope identificável para abrir a 10.5 pelo id do alarme.
struct RingingItem: Identifiable {
    let id: UUID
}
