import ActivityKit
import AlarmKit
import AppIntents
import SwiftUI
import WidgetKit

// Live Activity dos alarmes do app: mostra a contagem da soneca na tela
// bloqueada e na Dynamic Island, com botão "Parar" (spec 4, 8.6, 10.9).
// O alerta tocando em si é desenhado pelo sistema; aqui entram os estados
// de contagem (soneca) e pausa.
struct SnoozeLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlarmAttributes<Mais5Metadata>.self) { context in
            SnoozeLockScreenView(attributes: context.attributes, state: context.state)
                .activityBackgroundTint(.black)
                .activitySystemActionForegroundColor(context.attributes.tintColor)
        } dynamicIsland: { context in
            let tint = context.attributes.tintColor
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.attributes.metadata?.displayTitle ?? "Alarme", systemImage: "zzz")
                        .font(.headline)
                        .foregroundStyle(tint)
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    CountdownText(state: context.state)
                        .font(.title2.monospacedDigit().weight(.semibold))
                        .foregroundStyle(tint)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    StopButton(alarmID: context.state.alarmID, tint: tint)
                }
            } compactLeading: {
                Image(systemName: "zzz").foregroundStyle(tint)
            } compactTrailing: {
                CountdownText(state: context.state)
                    .monospacedDigit()
                    .foregroundStyle(tint)
                    .frame(maxWidth: 52)
            } minimal: {
                Image(systemName: "zzz").foregroundStyle(tint)
            }
            .keylineTint(tint)
        }
    }
}

// Visual da tela bloqueada: `zzz` + rótulo, contagem grande na cor e "Parar"
// (design system, tela 9). Entradas: atributos e estado do alarme. Saída: view.
private struct SnoozeLockScreenView: View {
    let attributes: AlarmAttributes<Mais5Metadata>
    let state: AlarmPresentationState

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Label(attributes.metadata?.displayTitle ?? "Alarme", systemImage: "zzz")
                    .font(.headline)
                    .foregroundStyle(attributes.tintColor)
                    .lineLimit(1)
                CountdownText(state: state)
                    .font(.system(size: 44, weight: .semibold).monospacedDigit())
                    .foregroundStyle(attributes.tintColor)
            }
            Spacer(minLength: 0)
            StopButton(alarmID: state.alarmID, tint: attributes.tintColor)
                .frame(maxWidth: 120)
        }
        .padding(16)
    }
}

// Texto da contagem regressiva conforme o modo do alarme.
// Entradas: estado da apresentação. Saída: contagem (soneca) ou texto fixo.
private struct CountdownText: View {
    let state: AlarmPresentationState

    var body: some View {
        switch state.mode {
        case .countdown(let countdown):
            // O sistema atualiza o timer sozinho. O intervalo parte do início da
            // contagem informado pelo AlarmKit; se as datas vierem invertidas, um
            // intervalo vazio evita derrubar o widget (`...` exige início ≤ fim).
            let start = min(countdown.startDate, countdown.fireDate)
            Text(timerInterval: start...countdown.fireDate, countsDown: true)
        case .paused:
            Text("Pausado")
        case .alert:
            Text("Tocando")
        @unknown default:
            Text("")
        }
    }
}

// Botão "Parar" que dispara o `StopAlarmIntent` no processo do app (copy 15.2).
// Entradas: id do alarme e cor do relógio. Saída: view.
private struct StopButton: View {
    let alarmID: UUID
    let tint: Color

    var body: some View {
        Button(intent: StopAlarmIntent(alarmID: alarmID)) {
            Text("Parar")
                .font(.headline)
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.plain)
        .background(tint, in: .rect(cornerRadius: 14))
    }
}
