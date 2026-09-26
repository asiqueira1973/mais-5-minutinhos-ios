import SwiftData
import SwiftUI

// Tela 10.2 — Editar alarme (sheet, detent large). Roda nativa de hora, dias da
// semana com atalhos, rótulo (máx. 30), som, soneca (toggle + 5/9/10/15) e
// "Excluir alarme" só na edição. Design system, tela 2.
// Entradas: linha em edição (nil = novo), formato 24h, cor e controlador.
struct AlarmEditView: View {
    let editing: Alarme?
    let is24h: Bool
    let tint: Color
    let controller: AlarmController

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var draft: AlarmDraft
    @State private var isSaving = false

    // Máximo do rótulo (seção 7.1).
    private static let maxLabelLength = 30
    // Durações permitidas da soneca (regra 11.2).
    private static let snoozeOptions = [5, 9, 10, 15]

    // Prepara o rascunho: cópia do alarme em edição ou um novo na hora atual.
    // Entradas: alarme em edição, formato, cor e controlador. Saída: view.
    init(editing: Alarme?, is24h: Bool, tint: Color, controller: AlarmController) {
        self.editing = editing
        self.is24h = is24h
        self.tint = tint
        self.controller = controller
        if let editing {
            _draft = State(initialValue: AlarmDraft(editing))
        } else {
            let now = Calendar.current.dateComponents([.hour, .minute], from: .now)
            _draft = State(initialValue: AlarmDraft(hora: now.hour ?? 7, minuto: now.minute ?? 0))
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Hora", selection: timeBinding, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                        // pt-BR mostra 24h; en_US mostra 12h com AM/PM (`formato_24h`).
                        .environment(\.locale, Locale(identifier: is24h ? "pt_BR" : "en_US"))
                }
                Section("Repetir") {
                    WeekdayPicker(days: $draft.dias_repeticao, tint: tint)
                }
                Section {
                    LabeledContent("Rótulo") {
                        TextField("Alarme", text: labelBinding)
                            .multilineTextAlignment(.trailing)
                    }
                    // A escolha do som (tela 10.3) entra no épico 8.4.
                    LabeledContent("Som", value: SoundCatalog.option(draft.som).name)
                } footer: {
                    // Resposta da pergunta 25.3 (spike 8.1): o volume segue o de toque.
                    Text("O alarme toca no volume de toque do iPhone.")
                }
                Section {
                    Toggle("Soneca", isOn: $draft.soneca_ativa)
                    Picker("Duração", selection: $draft.soneca_minutos) {
                        ForEach(Self.snoozeOptions, id: \.self) { Text("\($0) min").tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .disabled(!draft.soneca_ativa)
                }
                if let editing {
                    Section {
                        Button("Excluir alarme", role: .destructive) {
                            Task {
                                if await controller.delete(editing, in: context) { dismiss() }
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") {
                        isSaving = true
                        Task {
                            let done = await controller.save(normalizedDraft, editing: editing, in: context)
                            isSaving = false
                            if done { dismiss() }
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(isSaving)
                }
            }
        }
        .presentationDetents([.large])
        .alert(item: Binding(get: { controller.alert }, set: { controller.alert = $0 })) { kind in
            AlarmAlerts.alert(for: kind)
        }
    }

    // Rótulo vazio vira nulo (seção 7.1: nulo quando a pessoa não deu nome).
    private var normalizedDraft: AlarmDraft {
        var result = draft
        let trimmed = (draft.rotulo ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        result.rotulo = trimmed.isEmpty ? nil : trimmed
        return result
    }

    // Liga a roda de hora ao par hora/minuto do rascunho.
    private var timeBinding: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(bySettingHour: draft.hora, minute: draft.minuto, second: 0, of: .now) ?? .now
            },
            set: { date in
                let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
                draft.hora = parts.hour ?? draft.hora
                draft.minuto = parts.minute ?? draft.minuto
            }
        )
    }

    // Liga o campo de texto ao rótulo, cortando em 30 caracteres (seção 7.1).
    private var labelBinding: Binding<String> {
        Binding(
            get: { draft.rotulo ?? "" },
            set: { draft.rotulo = String($0.prefix(Self.maxLabelLength)) }
        )
    }
}

// Sete botões redondos "D S T Q Q S S" + atalhos "Dias úteis" e "Todos os dias"
// (tela 10.2, design system). Selecionado: fundo na cor, letra #000; não
// selecionado: #3A3A3C, letra branca.
// Entradas: dias 1–7 (ligação) e cor.
struct WeekdayPicker: View {
    @Binding var days: [Int]
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 0) {
                ForEach(1...7, id: \.self) { day in
                    let selected = days.contains(day)
                    Button {
                        toggle(day)
                    } label: {
                        Text(Weekdays.initials[day] ?? "")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(selected ? .black : .white)
                            .frame(width: 38, height: 38)
                            .background(selected ? tint : Color(white: 0x3A / 255), in: .circle)
                            .frame(minWidth: 44, minHeight: 44)
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel(Weekdays.shortNames[day] ?? "")
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
            HStack(spacing: 24) {
                Button("Dias úteis") { days = Weekdays.workdays.sorted() }
                Button("Todos os dias") { days = Weekdays.all.sorted() }
            }
            .buttonStyle(.borderless)
            .foregroundStyle(tint)
        }
        .padding(.vertical, 4)
    }

    // Marca ou desmarca um dia. Entradas: dia 1–7. Saída: nenhuma.
    private func toggle(_ day: Int) {
        if let index = days.firstIndex(of: day) {
            days.remove(at: index)
        } else {
            days.append(day)
            days.sort()
        }
    }
}

// Alertas compartilhados pela lista e pela edição.
enum AlarmAlerts {
    // Monta o alerta. Entradas: tipo. Saída: `Alert` com a copy.
    static func alert(for kind: AlarmController.AlertKind) -> Alert {
        switch kind {
        case .limit:
            // Copy 15.6.
            Alert(title: Text("Você chegou a 10 alarmes. Apague um para criar outro."))
        case .error:
            // Copy aprovada por Alexandre em 26/09/2026 (a seção 15 não define).
            Alert(
                title: Text("Erro no alarme"),
                message: Text("Não foi possível salvar. Tente de novo."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}
