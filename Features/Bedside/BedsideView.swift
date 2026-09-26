import SwiftUI

// Tela 10.4 — modo cabeceira, opção 4C "Coluna" do design system: relógio LED
// à esquerda, divisor vertical e coluna à direita com dia e próximo alarme.
// Fundo preto puro (spec 16); a cor do relógio é a única cor (design system).
// Entradas: cor do relógio, brilho da noite, texto do próximo alarme (nil =
// copy 15.4), se há alarme tocando e ação de sair. Saída: view em tela cheia.
struct BedsideView: View {
    let color: Color
    var brightness: Double = 0.30
    var nextAlarm: (time: String, day: String)?
    // true enquanto um alarme toca por cima do modo (tela 10.5).
    var isRinging = false
    let onExit: () -> Void

    @State private var controller = BedsideController()
    @Environment(\.scenePhase) private var scenePhase
    // Deslocamento anti-marcação: até 6 pt em posição aleatória a cada minuto (8.5).
    @State private var burnInOffset: CGSize = .zero
    // TEMPORÁRIO (spike): brilho escolhido no slider de teste; nil = usa `brightness`.
    @State private var tunedBrightness: Double?

    // Localidade fixa pt-BR: o MVP é só em português (spec 17).
    private static let locale = Locale(identifier: "pt_BR")

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            content(now: timeline.date)
        }
        .background(Color.black.ignoresSafeArea())
        .contentShape(Rectangle())
        .onTapGesture { controller.wake() }
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .onAppear { controller.enter(brightness: brightness) }
        .onDisappear { controller.exit() }
        // Fora do primeiro plano o brilho da pessoa é devolvido; na volta, reaplicado.
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { controller.resume() } else { controller.suspend() }
        }
        .onChange(of: isRinging) { _, ringing in controller.setRinging(ringing) }
        .task { await shiftEveryMinute() }
    }

    // Monta o layout 4C para o instante atual.
    // Entradas: data/hora atual. Saída: view.
    private func content(now: Date) -> some View {
        // LED sempre com a cor cheia: só o brilho da tela controla a luz, para ler a
        // hora sem tocar (decisão de Alexandre no spike, diverge do design, que
        // previa 0,42 em brilho baixo e 0,85 normal).
        let clockDim = 1.0
        let info = color.opacity(controller.isAwake ? 0.9 : 0.6)
        return GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            HStack(spacing: 0) {
                // Relógio em 560×230 numa tela de 844×390, alinhado à esquerda.
                LEDClockView(time: Self.timeText(now), color: color, dim: clockDim, alignment: .leading)
                    .frame(width: w * 560 / 844, height: h * 230 / 390)
                    .padding(.leading, w * 40 / 844)
                Spacer(minLength: 0)
                // Divisor vertical 1 pt na cor a 25%.
                Rectangle()
                    .fill(color.opacity(0.25))
                    .frame(width: 1, height: h * 0.5)
                sideColumn(now: now, color: info)
                    .frame(width: w * 150 / 844, alignment: .leading)
                    .padding(.leading, 24)
                    .padding(.trailing, 16)
            }
            .frame(width: w, height: h)
            .offset(burnInOffset)
            .overlay(alignment: .bottomTrailing) { exitButton }
        }
        .ignoresSafeArea()
    }

    // Coluna da direita: dia (20 pt), sino + hora (28 pt medium) e "amanhã" (15 pt).
    // Entradas: agora e cor das informações. Saída: view.
    private func sideColumn(now: Date, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(now.formatted(.dateTime.weekday(.wide).locale(Self.locale)).capitalized(with: Self.locale))
                .font(.system(size: 20))
            if controller.showsChargerWarning {
                // Copy 15.5, mostrada por 10 s ao desconectar o carregador.
                Label("O iPhone não está carregando", systemImage: "bolt.slash")
                    .font(.system(size: 15))
            } else if let nextAlarm {
                Label(nextAlarm.time, systemImage: "alarm")
                    .font(.system(size: 28, weight: .medium).monospacedDigit())
                Text(nextAlarm.day)
                    .font(.system(size: 15))
            } else {
                // Copy 15.4.
                Text("Nenhum alarme ativo")
                    .font(.system(size: 15))
            }
        }
        .foregroundStyle(color)
        .lineLimit(2)
        .minimumScaleFactor(0.7)
    }

    // Botão "Sair": aparece só nos 5 s após um toque (8.5; design: fundo branco
    // 14%, texto secundário, raio 8).
    @ViewBuilder private var exitButton: some View {
        if controller.isAwake {
            HStack(spacing: 16) {
                brightnessTuner
                Button("Sair", action: onExit)
                .font(.body)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)
                .frame(minHeight: 44)
                .background(Color.white.opacity(0.14), in: .rect(cornerRadius: 8))
            }
            .padding(24)
            .transition(.opacity)
        }
    }

    // TEMPORÁRIO (spike): slider para achar o brilho padrão da noite (7.2),
    // com a porcentagem ao lado. Some junto com o botão "Sair".
    private var brightnessTuner: some View {
        let value = Binding<Double>(
            get: { tunedBrightness ?? brightness },
            set: { tunedBrightness = $0; controller.tuneNightBrightness($0) }
        )
        return HStack(spacing: 10) {
            Image(systemName: "sun.min")
            Slider(value: value, in: 0.05...1.0).frame(width: 220)
            Image(systemName: "sun.max")
            Text("\(Int((value.wrappedValue * 100).rounded()))%")
                .monospacedDigit()
                .frame(width: 48, alignment: .trailing)
        }
        .foregroundStyle(.secondary)
        .tint(color)
    }

    // Hora no formato 24h "HH:mm" (default `formato_24h = true`, seção 7.2).
    // Entradas: data. Saída: texto da hora.
    static func timeText(_ date: Date) -> String {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", parts.hour ?? 0, parts.minute ?? 0)
    }

    // A cada virada de minuto, sorteia um novo deslocamento de até 6 pt (8.5).
    // Entradas: nenhuma. Saída: nenhuma (roda até a view sumir).
    private func shiftEveryMinute() async {
        while !Task.isCancelled {
            let second = Calendar.current.component(.second, from: .now)
            try? await Task.sleep(for: .seconds(60 - second))
            withAnimation(.easeInOut(duration: 2)) {
                burnInOffset = CGSize(width: .random(in: -6...6), height: .random(in: -6...6))
            }
        }
    }
}

#Preview(traits: .landscapeRight) {
    BedsideView(color: Color(red: 1, green: 0.23, blue: 0.19), nextAlarm: ("07:00", "amanhã"), onExit: {})
}
