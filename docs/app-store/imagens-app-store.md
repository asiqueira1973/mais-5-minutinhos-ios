# Imagens da App Store — Mais 5 Minutinhos

**Formato final de cada imagem: 1284 × 2778 px (iPhone 6,5"), em retrato.** É o tamanho da arte inteira: fundo, título, subtítulo e o print ou a cena dentro. São 10 imagens que alternam dois tipos:

- **PRINT**: tela real do app dentro de um iPhone, com título em cima. Arquivos em `docs/app-store/prints/`, capturados no simulador do iPhone 17 Pro Max (1320 × 2868; os de paisagem, 2868 × 1320).
- **CENA**: foto de marketing gerada no Gemini (prompts na seção 2), com título em cima.

A ideia central é **transformar o iPhone num despertador de antigamente**: rádio-relógio de LED, placas flip, mesa de cabeceira, soneca.

Fluxo:
1. Gerar as 5 cenas no Gemini (seção 2).
2. Colar o prompt da seção 3 no Claude Design, com os 10 prints e as 5 cenas anexados.
3. Exportar as 10 artes em 1284 × 2778.

---

## 1. Roteiro das 10 imagens

A ordem importa: as 3 primeiras aparecem na busca da App Store.

| # | Tipo | Título | Subtítulo | Material |
|---|---|---|---|---|
| 1 | CENA | Seu iPhone virou despertador de mesa. | Relógio grande e escuro na cabeceira, como os de antigamente. | Cena A (Gemini) |
| 2 | PRINT (paisagem) | O rádio-relógio voltou. | Números de LED que você lê de longe, sem óculos. | `05-cabeceira-led-vermelho.png` |
| 3 | PRINT | Mais 5 minutinhos? Um toque. | Soneca gigante em cima, Parar embaixo. Sem desafio, sem susto. | `04-tocando.png` |
| 4 | CENA | Feito para quem acorda sem óculos. | Botões enormes para o momento mais difícil do dia. | Cena B (Gemini) |
| 5 | PRINT | Escolha o seu clássico. | LED, placas flip, fino ou negrito. Em 5 cores. | `10-ajustes.png` (+ `06`, `07`, `08` em miniatura, opcional) |
| 6 | CENA | Toca mesmo no silencioso. | Alarme do sistema: funciona com o app fechado. | Cena C (Gemini) |
| 7 | PRINT | Alarmes simples, do jeito certo. | Academia, natação, corrida: cada um com seus dias e sua soneca. | `01-lista.png` |
| 8 | CENA | O charme de antigamente. A precisão de hoje. | Fica aceso a noite toda, no brilho que você escolher. | Cena D (Gemini) |
| 9 | PRINT | Sons de despertador de verdade. | Campainha, sino, rádio-relógio, pássaros e mais. | `03-sons.png` |
| 10 | CENA | Sem conta. Sem anúncios. Sem assinatura. | Pague uma vez, use para sempre. Nada sai do seu iPhone. | Cena E (Gemini) |

**Prints reserva:** `02-editar.png`, `06-cabeceira-flip-ambar.png`, `07-cabeceira-fino-azul.png`, `08-cabeceira-negrito-verde.png` e `09-cabeceira-soneca-led.png` ("Soneca até 06:48"). Qualquer um pode substituir um PRINT acima.

**Conferir antes de publicar:**
- "Toca mesmo no silencioso" e "funciona com o app fechado" foram confirmados no spike 8.1.
- "Nada sai do seu iPhone" segue a seção 20 do spec.
- A imagem 10 fala em "pague uma vez": o app tem uma parte grátis e uma compra única, e alarmes e modo cabeceira são grátis e ilimitados. Se quiser evitar qualquer leitura de "o app é pago", troque o subtítulo por "Alarmes e cabeceira grátis. Temas e sons extras com compra única."

---

## 2. Prompts do Gemini para as cenas

### Como usar no Gemini
- Peça em **formato vertical 9:16**. O Claude Design corta ou estende para 1284 × 2778.
- **Anexe o print indicado** em cada cena e peça para ele aparecer na tela do celular. Assim a tela da foto é o app de verdade, não uma interface inventada.
- Gere 3 ou 4 variações por cena e escolha a melhor. Se a tela sair distorcida, gere a cena com a **tela preta** (frase alternativa no fim de cada prompt) e o Claude Design encaixa o print por cima.
- Os prompts estão em inglês, porque os geradores de imagem seguem instruções visuais melhor assim.

**Regras comuns** (já incluídas em cada prompt): fotorrealista, sem logotipos nem marcas no celular, **o terço de cima livre** (parede escura ou desfoque) para o título, luz noturna quente e calma.

### Cena A — capa: o iPhone deitado na mesa de cabeceira (imagem 1)
Anexar: `05-cabeceira-led-vermelho.png`

```
Photorealistic lifestyle photo, vertical 9:16. A cozy, dark bedroom at night. On a wooden bedside table, a modern smartphone lies horizontally (landscape), propped slightly on a small stand and plugged into a charging cable, turned into a retro alarm clock. The phone screen shows EXACTLY the attached screenshot: big red seven-segment LED digits "23:48" on a pure black background, with a small column on the right. The red LED glow softly reflects on the wood surface. Next to the phone: a small ceramic cup, a folded book, reading glasses. Background: out-of-focus bed with white linen, a dim warm lamp turned very low, faint bluish moonlight from a window. Mood: calm, nostalgic, 1980s clock-radio feeling in a modern home. Shallow depth of field, focus on the phone screen. Camera slightly above table level, 35mm lens. Leave the top third of the image as a calm, dark, softly blurred wall (empty space for a headline). No logos, no brand names, no text other than the screen content, no people.
```
Alternativa de tela: troque "The phone screen shows EXACTLY the attached screenshot…" por "The phone screen is pure black and slightly glossy (it will be replaced later)".

### Cena B — acordar sem óculos (imagem 4)
Anexar: `04-tocando.png`

```
Photorealistic close-up photo, vertical 9:16. Early morning in a bedroom, soft golden sunlight coming through linen curtains. A sleepy person in their 60s (Brazilian, warm skin tone, gray hair, messy pillow hair, eyes half-closed) reaches from the bed and taps a smartphone lying on the bedside table with one finger. The phone screen shows EXACTLY the attached screenshot: a huge red "Soneca" button filling most of the screen, a dark "Parar" button below, and red LED digits "06:30" at the top. The finger is touching the big red button. Reading glasses rest folded on the table, out of reach. Mood: gentle, humorous, relatable "just five more minutes". Shallow depth of field, focus on the finger and the screen. Leave the top third of the image as soft, bright, out-of-focus curtains (empty space for a headline). No logos, no brand names, no text other than the screen content.
```
Alternativa de tela: "The phone screen shows a bright red rectangle filling most of the screen (it will be replaced later)".

### Cena C — toca no silencioso (imagem 6)
Anexar: `04-tocando.png`

```
Photorealistic photo, vertical 9:16. Dawn in a quiet bedroom, cool blue light just before sunrise. On a nightstand, a smartphone stands upright in a simple wooden stand, screen facing the camera, showing EXACTLY the attached screenshot: a huge red "Soneca" button, a dark "Parar" button below and red LED digits "06:30" at the top. The screen's red glow softly lights the nightstand and the edge of the bed. In the soft-focus background, a person under a gray duvet is starting to wake up, one hand reaching out from the covers. The room is otherwise silent and still: no speakers, no other devices. Mood: reliable, calm, trustworthy — "it rang, you woke up". Leave the top third of the image as a dark, calm, blurred wall (empty space for a headline). No logos, no brand names, no icons, no text other than the screen content.
```
Obs.: o "silencioso" vai no título; a cena só precisa passar "tocou e acordou".

### Cena D — antigo e novo lado a lado (imagem 8)
Anexar: `06-cabeceira-flip-ambar.png`

```
Photorealistic still-life photo, vertical 9:16, warm night light. On a walnut bedside table: on the left, a vintage 1970s flip clock (generic, no brand) with white-on-black flip cards; on the right, a modern smartphone lying horizontally on a small stand, plugged in, whose screen shows EXACTLY the attached screenshot: amber flip-card style digits "23:48" on black, with a small column on the right. Both clocks side by side, same height, same warm amber-orange mood. A small brass lamp turned very low behind them, a potted plant leaf entering the frame. Mood: nostalgic, elegant, "the charm of the past with today's precision". Straight-on camera at table level, shallow depth of field, both clocks in focus. Leave the top third of the image as a dark, textured wall in soft focus (empty space for a headline). No logos, no brand names, no readable text other than the digits.
```

### Cena E — tranquilidade: sem conta, sem anúncios (imagem 10)
Anexar: `05-cabeceira-led-vermelho.png` (ou `09-cabeceira-soneca-led.png`)

```
Photorealistic photo, vertical 9:16. A peaceful bedroom at night seen from the foot of the bed: a person in their 30s (Brazilian, dark curly hair) sleeping deeply and comfortably, face relaxed, one arm over the duvet. On the bedside table, a smartphone lies horizontally on a small stand, plugged in, screen showing EXACTLY the attached screenshot: red seven-segment LED digits on pure black. The red glow is the only light source besides faint moonlight. No other devices, no clutter: a glass of water and a small plant. Mood: privacy, simplicity, deep sleep, nothing to worry about. Wide shot, 28mm lens, soft film grain. Leave the top third of the image as a very dark, calm ceiling/wall (empty space for a headline). No logos, no brand names, no text other than the screen content.
```

---

## 3. Prompt para o Claude Design

Anexe os 10 prints de `docs/app-store/prints/` e as 5 cenas geradas, com os nomes `cena-A.png` … `cena-E.png`. Depois cole:

```
Crie 10 imagens de App Store para o app iOS "Mais 5 Minutinhos" (nome sob o ícone: "5 Minutinhos"), em pt-BR.

FORMATO (obrigatório)
- Cada imagem: 1284 × 2778 px, retrato (iPhone 6,5"). Esse é o tamanho TOTAL da arte: fundo, títulos, prints e cenas ficam todos dentro desse retângulo.
- Margem de segurança: 80 px nas laterais, 120 px em cima e embaixo.
- Exporte cada imagem separada, numerada de 01 a 10.

CONCEITO
O app transforma o iPhone num despertador de mesa de antigamente: à noite, relógio grande de LED vermelho (ou placas flip) em fundo preto, na mesa de cabeceira; de manhã, um botão "Soneca" gigante. O tom é nostálgico, calmo e com um humor leve (o nome é "Mais 5 Minutinhos"). Nada de visual "tech" genérico.

IDENTIDADE VISUAL
- Fundo das artes com PRINT: preto #000000 com um brilho radial muito sutil na cor do relógio atrás do aparelho (máx. 12% de opacidade). Nada de gradiente colorido chamativo.
- Cor de destaque: vermelho LED #FF3B30. Nas artes com o tema flip, âmbar #FFA10A; nas de outros temas, a cor do próprio print (azul #3F8CFF, verde #34D158).
- Título: SF Pro Display Bold (ou Inter Display Bold), branco #FFFFFF, 96–110 px, no máximo 2 linhas, alinhado à esquerda, no topo.
- Subtítulo: SF Pro Text Regular, 44–48 px, branco a 65%, no máximo 2 linhas, logo abaixo do título.
- Detalhe vintage opcional em todas: uma pequena "etiqueta" no canto superior esquerdo acima do título, com a palavra-chave em fonte de 7 segmentos (ex.: DSEG7 ou similar) na cor de destaque, 36 px (ex.: "05:45", "SONECA", "LED"). Use com moderação; se poluir, remova.
- Proibido: emoji, sombras pesadas, bordas grossas, MAIÚSCULAS decorativas nos títulos, logotipo da Apple.

COMO MONTAR CADA TIPO
- PRINT em retrato: moldura de iPhone moderno preto (bordas finas, Dynamic Island), centralizado horizontalmente, ocupando ~72% da largura, começando ~120 px abaixo do subtítulo e podendo sangrar para fora da borda de baixo. Cantos da tela arredondados.
- PRINT em paisagem (cabeceira): o iPhone DEITADO na horizontal, ocupando ~92% da largura, centralizado verticalmente na metade de baixo, com um reflexo suave vermelho/âmbar embaixo, como se estivesse sobre uma mesa escura. É a imagem mais importante do conceito.
- CENA: a foto ocupa a arte inteira (sangrada), cortada para 1284 × 2778 mantendo o celular visível no terço de baixo/meio. Título e subtítulo no terço de cima, sobre a área escura da foto; se faltar contraste, aplique um degradê preto de 0% → 60% só no topo.

AS 10 IMAGENS (ordem final)
01 — CENA (cena-A.png)
  Título: "Seu iPhone virou despertador de mesa."
  Subtítulo: "Relógio grande e escuro na cabeceira, como os de antigamente."
02 — PRINT paisagem (05-cabeceira-led-vermelho.png)
  Título: "O rádio-relógio voltou."
  Subtítulo: "Números de LED que você lê de longe, sem óculos."
03 — PRINT retrato (04-tocando.png)
  Título: "Mais 5 minutinhos? Um toque."
  Subtítulo: "Soneca gigante em cima, Parar embaixo. Sem desafio, sem susto."
04 — CENA (cena-B.png)
  Título: "Feito para quem acorda sem óculos."
  Subtítulo: "Botões enormes para o momento mais difícil do dia."
05 — PRINT retrato (10-ajustes.png)
  Título: "Escolha o seu clássico."
  Subtítulo: "LED, placas flip, fino ou negrito. Em 5 cores."
  Extra opcional: abaixo do iPhone, 3 miniaturas em paisagem de 06-cabeceira-flip-ambar.png, 07-cabeceira-fino-azul.png e 08-cabeceira-negrito-verde.png, levemente sobrepostas, com raio 24 px.
06 — CENA (cena-C.png)
  Título: "Toca mesmo no silencioso."
  Subtítulo: "Alarme do sistema: funciona com o app fechado."
07 — PRINT retrato (01-lista.png)
  Título: "Alarmes simples, do jeito certo."
  Subtítulo: "Academia, natação, corrida: cada um com seus dias e sua soneca."
08 — CENA (cena-D.png)
  Título: "O charme de antigamente. A precisão de hoje."
  Subtítulo: "Fica aceso a noite toda, no brilho que você escolher."
09 — PRINT retrato (03-sons.png)
  Título: "Sons de despertador de verdade."
  Subtítulo: "Campainha, sino, rádio-relógio, pássaros e mais."
10 — CENA (cena-E.png)
  Título: "Sem conta. Sem anúncios. Sem assinatura."
  Subtítulo: "Pague uma vez, use para sempre. Nada sai do seu iPhone."

CONSISTÊNCIA
- Mesma posição e tamanho de título/subtítulo em todas as 10 (a vitrine da App Store mostra várias lado a lado).
- Alterne o ritmo: cena escura e quente / print preto limpo.
- Não altere nem redesenhe o conteúdo dos prints (são telas reais do app); só redimensione e coloque na moldura.
- Antes de exportar, confira: 1284 × 2778 px, textos dentro da margem de segurança, nenhum texto cortado.
```

---

## 4. Como os prints foram gerados (para refazer)

No simulador iPhone 17 Pro Max, com a build Debug e a barra de status fixa (`xcrun simctl status_bar <id> override --time "9:41" …`), usando os ganchos de depuração, que só existem em Debug:

| Gancho | Efeito |
|---|---|
| `-debugSeedAlarms YES` | cria Academia 05:45 (dias úteis), Natação 06:30 (seg/qua/sex), Corrida 07:00 (fins de semana) e 09:00 desligado |
| `-debugUnlocked YES` | libera temas, cores e sons |
| `-debugClockTime HH:mm` | fixa a hora exibida pelos relógios |
| `-debugBedside YES` | abre o modo cabeceira |
| `-debugRinging YES` | abre a tela de alarme tocando (usa o alarme da hora fixada) |
| `-debugSnooze YES` | cabeceira em soneca ("Soneca até") |

O tema e a cor foram trocados direto no banco do simulador (`ZPREFERENCIAS`). Os prints de paisagem foram girados com `sips -r 270`.
