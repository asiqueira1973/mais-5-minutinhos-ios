import SwiftData
import SwiftUI

// Tela 10.6 — Ajustes (push a partir da 10.1). Prévia ao vivo do relógio; tema,
// cor, 24h e segundos; brilho da cabeceira com prévia e entrada automática;
// compra/restaurar; sobre/privacidade (design system tela 6, épico 8.7).
// Temas e cores pagos mostram cadeado e abrem o paywall (regra 11.7).
// Entradas: se a compra está válida, ação de restaurar e ação chamada quando a
// cor muda (para reagendar a apresentação dos alarmes com a cor nova).
struct SettingsView: View {
    let premiumUnlocked: Bool
    let onRestore: () -> Void
    let onColorChange: () -> Void

    @Query private var preferences: [Preferencias]

    var body: some View {
        if let prefs = preferences.first {
            SettingsForm(
                prefs: prefs, premiumUnlocked: premiumUnlocked,
                onRestore: onRestore, onColorChange: onColorChange
            )
        }
    }
}

// Formulário dos Ajustes ligado à linha única de `preferencias` (seção 7.2).
private struct SettingsForm: View {
    @Bindable var prefs: Preferencias
    let premiumUnlocked: Bool
    let onRestore: () -> Void
    let onColorChange: () -> Void

    @Environment(\.modelContext) private var context
    @Environment(PurchaseStore.self) private var store
    @State private var showsPaywall = false
    // Brilho da tela antes de arrastar o slider (prévia do brilho, 10.6).
    @State private var brightnessBeforePreview: CGFloat?

    private var tint: Color { Entitlements.effective(prefs.cor_relogio, unlocked: premiumUnlocked).color }

    var body: some View {
        List {
            Section {
                preview
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }
            Section("Relógio") {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Tema")
                    themeGrid
                }
                .padding(.vertical, 4)
                VStack(alignment: .leading, spacing: 10) {
                    Text("Cor")
                    colorRow
                }
                .padding(.vertical, 4)
                Toggle("Formato 24 horas", isOn: $prefs.formato_24h)
                Toggle("Mostrar segundos", isOn: $prefs.mostrar_segundos)
            }
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Brilho")
                    HStack(spacing: 12) {
                        Image(systemName: "sun.min").foregroundStyle(.secondary)
                        Slider(value: $prefs.brilho_cabeceira, in: 0.05...1.0) { editing in
                            previewBrightness(editing)
                        }
                        Image(systemName: "sun.max").foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Brilho da cabeceira")
                    .accessibilityValue("\(Int((prefs.brilho_cabeceira * 100).rounded())) por cento")
                }
                .padding(.vertical, 4)
                Toggle("Entrar automaticamente", isOn: $prefs.entrar_automatico)
            } header: {
                Text("Cabeceira")
            } footer: {
                Text("Ao deitar o iPhone no carregador com um alarme ativo")
            }
            Section("Mais 5 Minutinhos completo") {
                if premiumUnlocked {
                    Label("Comprado", systemImage: "checkmark")
                } else {
                    Button {
                        showsPaywall = true
                    } label: {
                        LabeledContent {
                            // Preço do StoreKit (`displayPrice`); some sem rede.
                            Text(store.product?.displayPrice ?? "")
                        } label: {
                            Text("Comprar").foregroundStyle(tint)
                        }
                    }
                    Button("Restaurar compra", action: onRestore)
                        .disabled(store.isBusy)
                }
            }
            Section("Sobre") {
                NavigationLink("Como usar") { HowToUseView(tint: tint) }
                // Abre a Política de Privacidade (Guideline 5.1.1: acessível no app).
                Link(destination: AppLinks.privacyPolicy) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Privacidade").foregroundStyle(.primary)
                            Text("Nenhum dado sai do seu iPhone")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.footnote)
                            .foregroundStyle(.tertiary)
                    }
                }
                LabeledContent("Versão", value: Self.version)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Ajustes")
        .sheet(isPresented: $showsPaywall) { PaywallView(tint: tint) }
        .onChange(of: prefs.cor_relogio) { _, _ in onColorChange() }
        // Durante o arraste, a tela acompanha o valor do slider (prévia do brilho).
        .onChange(of: prefs.brilho_cabeceira) { _, value in
            guard brightnessBeforePreview != nil else { return }
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first?.screen.brightness = CGFloat(value)
        }
        .task { await store.loadProduct() }
        .onDisappear {
            previewBrightness(false)
            try? context.save()
        }
    }

    // Prévia ao vivo: retângulo #000, altura 150, borda 1 pt #38383A, raio 12 (design).
    private var preview: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            let parts = Calendar.current.dateComponents([.hour, .minute, .second], from: DebugClock.display(timeline.date))
            let time = ClockFormat.parts(hora: parts.hour ?? 0, minuto: parts.minute ?? 0, is24h: prefs.formato_24h)
            ClockView(
                theme: Entitlements.effective(prefs.tema_relogio, unlocked: premiumUnlocked),
                time: time.time,
                seconds: prefs.mostrar_segundos ? String(format: "%02d", parts.second ?? 0) : nil,
                suffix: time.suffix,
                color: tint
            )
            .padding(.vertical, 20)
            .padding(.horizontal, 28)
        }
        .frame(height: 150)
        .frame(maxWidth: .infinity)
        .background(.black, in: .rect(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(white: 0x38 / 255), lineWidth: 1))
    }

    // Quatro miniaturas de tema: 50 pt de altura, raio 8, borda 2 pt na cor no
    // escolhido, `lock.fill` no canto se pago, nome em caption embaixo (design).
    private var themeGrid: some View {
        HStack(spacing: 10) {
            ForEach(TemaRelogio.allCases, id: \.self) { theme in
                let locked = !premiumUnlocked && !Entitlements.isFree(theme)
                let selected = Entitlements.effective(prefs.tema_relogio, unlocked: premiumUnlocked) == theme
                Button {
                    if locked { showsPaywall = true } else { prefs.tema_relogio = theme }
                } label: {
                    VStack(spacing: 6) {
                        ClockView(theme: theme, time: "07:00", color: tint)
                            .padding(6)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(.black, in: .rect(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(selected ? tint : Color(white: 0x38 / 255), lineWidth: selected ? 2 : 1)
                            )
                            .overlay(alignment: .topTrailing) {
                                if locked {
                                    Image(systemName: "lock.fill")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .padding(4)
                                }
                            }
                        Text(Entitlements.name(theme))
                            .font(.caption)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Entitlements.name(theme))
                .accessibilityAddTraits(selected ? .isSelected : [])
                .accessibilityHint(locked ? "Disponível na compra" : "")
            }
        }
    }

    // Cinco círculos de 44 pt, anel de 2 pt no escolhido, `lock.fill` preto
    // dentro dos pagos (design).
    private var colorRow: some View {
        HStack(spacing: 0) {
            ForEach(CorRelogio.allCases, id: \.self) { cor in
                let locked = !premiumUnlocked && !Entitlements.isFree(cor)
                let selected = Entitlements.effective(prefs.cor_relogio, unlocked: premiumUnlocked) == cor
                Button {
                    if locked { showsPaywall = true } else { prefs.cor_relogio = cor }
                } label: {
                    Circle()
                        .fill(cor.color)
                        .frame(width: 36, height: 36)
                        .overlay {
                            if locked {
                                Image(systemName: "lock.fill").font(.caption).foregroundStyle(.black)
                            }
                        }
                        .padding(4)
                        .overlay(Circle().stroke(selected ? cor.color : .clear, lineWidth: 2))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .accessibilityLabel(Entitlements.name(cor))
                .accessibilityAddTraits(selected ? .isSelected : [])
                .accessibilityHint(locked ? "Disponível na compra" : "")
            }
        }
    }

    // Prévia do brilho (10.6): enquanto arrasta o slider, a tela vai para o brilho
    // escolhido; ao soltar, volta ao brilho de antes.
    // Entradas: true ao começar a arrastar, false ao soltar. Saída: nenhuma.
    private func previewBrightness(_ editing: Bool) {
        let screen = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first?.screen
        if editing {
            if brightnessBeforePreview == nil { brightnessBeforePreview = screen?.brightness }
            screen?.brightness = CGFloat(prefs.brilho_cabeceira)
        } else if let before = brightnessBeforePreview {
            screen?.brightness = before
            brightnessBeforePreview = nil
        }
    }

    // Versão do app (CFBundleShortVersionString).
    private static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }
}
