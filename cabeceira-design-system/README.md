# Handoff: Mais 5 Minutinhos – Despertador (iOS)

## Visão geral
Despertador de cabeceira para iPhone (SwiftUI, iOS nativo, pt-BR). À noite o iPhone fica deitado no carregador mostrando um relógio grande em preto puro. De manhã o alarme toca e a pessoa, sonolenta e sem óculos, resolve com um toque: **Soneca** ou **Parar**. Público: qualquer adulto, com atenção a idosos.

Princípios (desempate de qualquer decisão):
1. Um toque para parar, um toque para soneca. Alvos enormes, nenhuma confirmação.
2. Telas noturnas em preto puro (#000), sem nada claro ou chamativo.
3. Simplicidade antes de recurso.

## Sobre os arquivos de design
Os arquivos desta pasta são **referências de design feitas em HTML**: protótipos que mostram aparência e comportamento, não código para copiar. A tarefa é **recriar estas telas em SwiftUI** usando componentes nativos (NavigationStack, List `.insetGrouped`, Toggle, DatePicker `.wheel`, Picker `.segmented`, `.sheet` com detents, `.swipeActions`, SF Symbols, estilos tipográficos semânticos, Dynamic Type).

Para abrir: `Mais 5 Minutinhos.dc.html` no navegador (precisa de `support.js` e `Clock.dc.html` na mesma pasta). É um canvas com zoom/pan.

## Fidelidade
**Alta fidelidade** para cores, proporções, tamanhos dos botões do alarme e desenho dos 4 temas de relógio. Os ícones são aproximações desenhadas dos SF Symbols: usar os símbolos reais. Tamanhos de texto das listas seguem os estilos semânticos do iOS (usar `Font.TextStyle`, não pontos fixos).

## Decisões pendentes (escolher antes de implementar)
- **Tela 4 (Modo cabeceira):** 4A Centro · 4B Borda a borda · 4C Coluna.
- **Tela 5 (Alarme tocando):** 5A Blocos · 5B Tinta · 5C Tela inteira.
- **Ícone:** A (LED “05”) · B (placa flip “5”).
- **Gratuitos:** assumido LED clássico + vermelho grátis; demais temas/cores pagos. Confirmar.
- **Textos não definidos no spec:** botão do paywall (“Comprar por R$ 19,90” proposto), título do push de sons (“Som” proposto), número da versão (placeholder), nome curto na tela inicial (“Mais 5 Min” proposto).

## Direção visual
- Noite (telas 4 e 5): fundo #000, a **cor do relógio é a única cor**. Nenhum branco grande.
- Configuração (telas 1–3, 6–8): iOS **sempre em modo escuro** (`.preferredColorScheme(.dark)`), `tint` = cor do relógio escolhida.
- Texto sobre a cor do relógio: sempre #000.
- Proibido: cards com sombra, gradientes, bordas grossas, cantos arbitrários, emoji, MAIÚSCULAS decorativas.

## Design tokens

### Cores do relógio (também o tint do app)
| id | nome | hex |
|---|---|---|
| vermelho (default) | Vermelho | #FF3B30 |
| ambar | Âmbar | #FFA10A |
| verde | Verde | #34D158 |
| azul | Azul | #3F8CFF |
| branco | Branco | #EDEDED |

Derivações: Soneca diluída (5B, Dynamic Island) = cor a 20–22% sobre preto. Informações noturnas (dia, próximo alarme) = cor a 55–60%. Divisor da opção 4C = cor a 25%.

### Superfícies (usar as cores semânticas do sistema no escuro)
- Fundo: #000 (`systemBackground` / `.black` nas telas noturnas)
- Célula agrupada: #1C1C1E (`secondarySystemGroupedBackground`); em sheet: #2C2C2E
- Controle inativo (toggle off): #39393D
- Separador: #545458 a 65%
- Texto secundário: rgba(235,235,245,.6) (`secondaryLabel`); terciário: .3 (`tertiaryLabel`)
- Destrutivo: #FF453A (`.red` do sistema)
- Placa do tema flip: #171717 (metade inferior #131313), dobradiça #000

### Tipografia
SF Pro via estilos semânticos: largeTitle 34 bold, title2 22 bold, headline 17 semibold, body 17, subheadline 15, footnote 13. Hora na lista de alarmes: 48 pt light, `monospacedDigit()`.
Botões do alarme: Soneca 60–76 pt bold/heavy, Parar 40–52 pt bold. Esses textos devem escalar com Dynamic Type até caber no botão (`minimumScaleFactor`).

### Raios
Células 10 (padrão inset grouped). Botão “Dormir” e botões de sheet 14. Botões do alarme: 5A 32, 5B 24, 5C 0 (borda a borda). Miniaturas de tema 8.

## Relógio: 4 temas (`Clock.dc.html` tem a geometria exata)
Todos em caixa de altura 100 (unidade relativa), escalados para caber (`aspectRatio(.fit)`). Slot por dígito e espaçamento:
- **led_classico** — 7 segmentos hexagonais, espessura 10, folga 1,6, dígito 60×100 (slot 68, espaço 10), inclinado −6° (skewX). Segmentos apagados visíveis a **9%** da cor (12% em brilho baixo). Dois-pontos: quadrados 10×10 em y=25 e y=65. Implementar como `Shape`/`Canvas`.
- **digital_fino** — numerais finos e altos (referência: Big Shoulders Display 200; em produção pode ser SF Pro Display Ultralight com `.width(.compressed)` ou fonte licenciada embutida). Slot 48, espaço 6. Dois-pontos: círculos r 3,4.
- **grande_negrito** — numerais pesados (referência: Archivo 800; em produção SF Pro Heavy/Black). Slot 80, espaço 4. Dois-pontos: quadrados 14×14.
- **flip** — uma placa por dígito, 74×100, raio 8, fundo #171717, metade inferior #131313, linha de dobradiça preta de 2,4 no meio, pinos laterais #2A2A2A. Numeral condensado seminegrito (ref.: Big Shoulders Display 600) na cor do relógio. Dois-pontos: círculos r 4,5.
- Segundos (opcional): mesmos dígitos a 42% do tamanho, alinhados pela base.
- Opacidade do relógio: normal 0,85 · após toque 1,0 · brilho baixo (15%) 0,42.

## Telas

### 1. Alarmes (tela inicial, retrato)
- NavigationStack, título grande “Alarmes”. Toolbar: `gearshape` à esquerda (→ Ajustes), `plus` à direita (→ sheet Editar).
- List inset grouped. Linha: hora 48 light tabular; abaixo, subheadline secundário “Dias · Rótulo” (ex.: “Dias úteis · Trabalho”; valores de dias: “Dias úteis”, “Todos os dias”, “Seg, Qua, Sex”, “Uma vez”). Toggle à direita com tint. Desligado: hora em `tertiaryLabel`.
- Swipe para excluir (`.swipeActions`, destrutivo, `trash`).
- Botão fixo na base (`safeAreaInset(edge: .bottom)`): “Dormir” com `moon.fill`, altura 56, raio 14, fundo = cor do relógio, texto #000 headline. Margens 16.
- Vazio: `alarm` grande terciário, “Nenhum alarme” (title2 bold), “Toque em + para criar o primeiro.” (body secundário). Usar `ContentUnavailableView`.
- 10 alarmes: `plus` desabilitado; rodapé da seção: “Você chegou a 10 alarmes. Apague um para criar outro.”

### 2. Editar alarme (sheet, detent large)
- Toolbar: “Cancelar” / “Salvar” (semibold). Sem título.
- DatePicker `.wheel`, só hora, 24 h conforme ajuste.
- Section “Repetir”: 7 círculos 38 pt “D S T Q Q S S” (selecionado: fundo tint, letra #000; não selecionado: #3A3A3C, letra branca). Abaixo, na mesma célula, dois botões de texto tint: “Dias úteis”, “Todos os dias”.
- Section: “Rótulo” (TextField, máx. 30 caracteres); “Som” com valor atual e chevron (push → tela 3).
- Section “Soneca”: Toggle “Soneca”; Picker segmentado “5 min / 9 min / 10 min / 15 min” (desabilitado se Toggle off).
- Em edição: Section final com botão destrutivo centralizado “Excluir alarme”.

### 3. Escolher som (push)
- Título inline “Som”.
- Section 1: “Padrão do iPhone”, rodapé “Som de alarme do próprio iPhone”.
- Section 2: Bipe digital, Campainha clássica, Sino, Despertar suave, Pássaros, Piano da manhã, Rádio-relógio.
- `checkmark` tint no selecionado. Tocar numa linha toca prévia; durante a prévia, `speaker.wave.2` tint na linha. Sem compra: `lock.fill` terciário em todos exceto Padrão do iPhone e Bipe digital (tocar num bloqueado abre o paywall).

### 4. Modo cabeceira (paisagem, #000) — opção a escolher
Tela cheia, `persistentSystemOverlays(.hidden)`, `isIdleTimerDisabled = true`, brilho da tela conforme ajuste.
- **4A Centro:** relógio centralizado ocupando ~83% da largura (caixa 700×230 em 844×390). Linha inferior centralizada a 30 pt da base, 17 pt, cor a 60%: “Sábado” + `alarm` “07:00 amanhã”, espaço 24.
- **4B Borda a borda:** relógio em 744×284 (máximo). Dia no canto superior esquerdo e próximo alarme no superior direito, 15 pt, cor a 55%, a 28 pt do topo e 64 das laterais.
- **4C Coluna:** relógio alinhado à esquerda em 560×230; divisor vertical 1 pt (cor a 25%) em x=654; coluna à direita: dia 20 pt, `alarm` + hora 28 pt medium, “amanhã” 15 pt.
- Estados (todas as opções): sem alarme → “Nenhum alarme ativo”; em soneca → `zzz` “Soneca até 07:09”; carregador desconectado → `bolt.slash` “O iPhone não está carregando”; toque → opacidade do relógio 1,0, brilho sobe e botão “Sair” (fundo branco 14%, texto secundário, raio 8) por 5 s, depois volta.

### 5. Alarme tocando (retrato e paisagem, #000) — opção a escolher
Nada além de: hora atual (tema/cor do relógio), rótulo ou “Alarme”, Soneca, Parar.
- Retrato (390×844, área útil 751 pt entre as safe areas, margens 16, espaço 12): cabeçalho 100 · **Soneca 430 (57%)** · **Parar 197 (26%)**. Paisagem (área útil 357 pt, margens 59): cabeçalho 44 · Soneca 200 (56%) · Parar 97 (27%).
- Sem soneca: só “Parar”, 60% da altura útil, ancorado embaixo.
- Área de toque mínima 88 pt. Toque único, sem confirmação. Haptic ao tocar.
- **5A Blocos:** Soneca fundo cor, `zzz` 56 + “Soneca” 64 bold #000, raio 32. Parar fundo #1C1C1E, texto cor 48 bold.
- **5B Tinta:** Soneca fundo cor a 20%, texto/ícone na cor, 68 bold. Parar fundo cor sólida, texto #000 48 bold. Raio 24. Cabeçalho alinhado à esquerda.
- **5C Tela inteira:** sem margens nem raios. Soneca de y=170 a 606 na cor, 76 heavy #000. Espaço 3 pt preto. Parar até a borda inferior em #161616, texto na cor 52 bold.

### 6. Ajustes (push, retrato)
- Título grande “Ajustes”. No topo: prévia ao vivo, retângulo #000, altura 150, borda 1 pt #38383A, raio 12.
- Section “Relógio”: Tema (4 miniaturas em grade, 50 pt de altura, raio 8, selecionada com borda 2 pt tint, `lock.fill` no canto se pago, nome abaixo em caption); Cor (5 círculos 44 com anel 2 pt no selecionado; pagos com `lock.fill` preto dentro); Toggle “Formato 24 horas”; Toggle “Mostrar segundos”.
- Section “Cabeceira”: Brilho (Slider com `sun.min` / `sun.max`); Toggle “Entrar automaticamente”, rodapé “Ao deitar o iPhone no carregador com um alarme ativo”.
- Section “Mais 5 Minutinhos completo”: “Comprar” (tint) com preço à direita; “Restaurar compra” (tint). Após compra: linha única “Comprado” com `checkmark`.
- Section “Sobre”: “Privacidade” com subtítulo “Nenhum dado sai do seu iPhone”; “Versão” com número.

### 7. Paywall (sheet, detent large)
- Botão fechar (`xmark` em círculo #3A3A3C) no topo à direita.
- “Mais 5 Minutinhos completo” (title bold 28). “Todos os temas, cores e sons. Pague uma vez, use para sempre.” (body secundário).
- Miniaturas dos 4 temas em linha (cada uma numa cor), faixa das 5 cores, lista dos 6 sons pagos com `speaker.wave.2`.
- Base: botão “Comprar por R$ 19,90” (altura 52, raio 14, tint, texto #000) e link “Restaurar compra”. Preço vem do StoreKit (`displayPrice`).
- Sem rede: botão desabilitado + “Sem conexão. Tente de novo quando estiver online.”

### 8. Permissão de alarme negada (sheet, detent medium)
`alarm` com barra (`alarm.slash`) 60 pt tint; “Alarmes desligados” (title2 bold); “Para o Mais 5 Minutinhos tocar mesmo no silencioso, permita alarmes nos Ajustes do iPhone.”; botão “Abrir Ajustes” (abre `UIApplication.openSettingsURLString`).

### 9. Sistema (AlarmKit / Live Activity — layout da Apple)
- Alerta de alarme (tela bloqueada e Dynamic Island): título = rótulo ou “Alarme”; botões “Parar” (fundo cor, texto #000) e “Soneca” com `zzz` (fundo cor a 22%, texto cor). Ícone `alarm` na cor.
- Live Activity da soneca: `zzz` + rótulo, contagem regressiva grande na cor (monospaced), botão “Parar”. Dynamic Island compacta: `zzz` à esquerda, contagem à direita, na cor.

## Fluxo e estado
Primeira abertura (1 vazio) → + → Editar (2) → Salvar → permissão do sistema (negou → 8) → Lista → “Dormir” ou deitar no carregador com alarme ativo (se “Entrar automaticamente”) → Modo cabeceira (4) → na hora: Alarme tocando (5) → Soneca volta a (4) em soneca / Parar volta a (4).

Estado mínimo:
- `alarms: [Alarm]` (máx. 10): id, hora, minuto, dias (Set<Weekday>), rótulo (≤30), som, sonecaAtiva, sonecaMinutos (5/9/10/15), ativo.
- Ajustes: tema, cor, formato24h, mostrarSegundos, brilho (0–1), entrarAutomaticamente.
- Compra: comprado (StoreKit 2, compra única não consumível).
- Cabeceira: estadoCarregando (`UIDevice.batteryState`), sonecaAte (Date?), controlesVisíveis (timer de 5 s).
- Nenhum dado sai do iPhone.

## Ícone
- **A:** fundo #000, “05” em LED clássico vermelho com segmentos apagados a ~16%.
- **B:** fundo #000, uma placa flip com “5” vermelho.
Nome curto sob o ícone: a definir (“Mais 5 Min” proposto).

## Arquivos
- `Mais 5 Minutinhos.dc.html` — canvas com todas as telas, opções, ícones e tokens.
- `Clock.dc.html` — componente do relógio: geometria dos 7 segmentos, slots e dois-pontos de cada tema.
- `support.js` — runtime necessário para abrir os HTML.
