import SwiftData
import SwiftUI

// Tela 10.1 — Alarmes (tela inicial). Lista ordenada por hora e minuto, toggle,
// swipe para excluir, "+" (desabilitado com 10 alarmes, copy 15.6), estado vazio
// (copy 15.1) e botão fixo "Dormir" (copy 15.3). Design system, tela 1.
// Entradas: controlador de ações, formato 24h, cor do relógio e ação de dormir.
struct AlarmListView: View {
    let controller: AlarmController
    let is24h: Bool
    let tint: Color
    let onSleep: () -> Void

    @Environment(\.modelContext) private var context
    @Environment(PurchaseStore.self) private var store
    // Critério de 8.3: ordenada por hora, depois minuto.
    @Query(sort: [SortDescriptor(\Alarme.hora), SortDescriptor(\Alarme.minuto)]) private var alarms: [Alarme]

    // Sheet de edição: nil fechada; `.new` ou `.edit(alarme)`.
    @State private var editing: EditTarget?

    private var isFull: Bool { alarms.count >= AlarmController.maxAlarms }

    var body: some View {
        NavigationStack {
            List {
                if !alarms.isEmpty {
                    Section {
                        ForEach(alarms) { alarme in
                            AlarmRow(alarme: alarme, is24h: is24h, controller: controller) {
                                editing = .edit(alarme)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    Task { await controller.delete(alarme, in: context) }
                                } label: {
                                    Label("Excluir", systemImage: "trash")
                                }
                            }
                        }
                    } footer: {
                        if isFull {
                            // Copy 15.6.
                            Text("Você chegou a 10 alarmes. Apague um para criar outro.")
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .overlay {
                if alarms.isEmpty {
                    // Copy 15.1.
                    ContentUnavailableView(
                        "Nenhum alarme",
                        systemImage: "alarm",
                        description: Text("Toque em + para criar o primeiro.")
                    )
                }
            }
            .navigationTitle("Alarmes")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink {
                        SettingsView(
                            premiumUnlocked: controller.premiumUnlocked,
                            onRestore: { Task { await store.restore() } },
                            onColorChange: { Task { await controller.refreshPresentation(in: context) } }
                        )
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Ajustes")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        editing = .new
                    } label: {
                        Image(systemName: "plus")
                    }
                    .disabled(isFull)
                    .accessibilityLabel("Novo alarme")
                }
            }
            .safeAreaInset(edge: .bottom) { sleepButton }
        }
        .sheet(item: $editing) { target in
            AlarmEditView(
                editing: target.alarme, is24h: is24h, tint: tint, controller: controller
            )
        }
    }

    // Botão fixo "Dormir" (copy 15.3): altura 56, raio 14, fundo na cor do relógio,
    // texto #000 headline, `moon.fill` (design system, tela 1).
    private var sleepButton: some View {
        Button(action: onSleep) {
            Label("Dormir", systemImage: "moon.fill")
                .font(.headline)
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(tint, in: .rect(cornerRadius: 14))
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

// Alvo da sheet de edição (novo ou existente).
enum EditTarget: Identifiable {
    case new
    case edit(Alarme)

    var id: String {
        switch self {
        case .new: "new"
        case .edit(let alarme): alarme.id.uuidString
        }
    }

    var alarme: Alarme? {
        if case .edit(let alarme) = self { return alarme }
        return nil
    }
}

// Linha da lista: hora 48 light tabular, subtítulo "Dias · Rótulo" e toggle
// (design system, tela 1). Desligado: hora em `tertiaryLabel`.
// Entradas: alarme, formato, controlador (o toggle pede a mudança a ele) e ação
// de editar. Só a área de hora/texto abre a edição, para o toque no toggle não
// ser capturado pela linha.
struct AlarmRow: View {
    let alarme: Alarme
    let is24h: Bool
    let controller: AlarmController
    let onEdit: () -> Void

    var body: some View {
        HStack {
            Button(action: onEdit) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        timeText
                            .foregroundStyle(alarme.ativo ? .primary : .tertiary)
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            // O toggle só reflete o banco: muda depois do sucesso no AlarmKit (8.3).
            // O `set` captura só valores `Sendable` (controlador `@MainActor` e o UUID).
            Toggle("Ativo", isOn: Binding(
                get: { alarme.ativo },
                set: { [controller, id = alarme.id] on in
                    Task { await controller.setActive(id: id, on) }
                }
            ))
            .labelsHidden()
        }
        .accessibilityElement(children: .combine)
    }

    // Hora 48 light tabular; no formato 12h, AM/PM pequeno ao lado (regra 11.8).
    private var timeText: some View {
        let parts = ClockFormat.parts(hora: alarme.hora, minuto: alarme.minuto, is24h: is24h)
        return HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(parts.time)
                .font(.system(size: 48, weight: .light).monospacedDigit())
            if let suffix = parts.suffix {
                Text(suffix).font(.title3)
            }
        }
    }

    // "Dias · Rótulo" (design system); só os dias quando não há rótulo.
    private var subtitle: String {
        [Weekdays.summary(alarme.dias_repeticao), alarme.rotulo]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }
}
