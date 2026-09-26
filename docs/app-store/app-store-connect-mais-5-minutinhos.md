# App Store Connect — conteúdo pronto para colar (Mais 5 Minutinhos)

Checado contra os limites vigentes da App Store Connect com `check_limits.py` (resultado no fim do documento). Localização: **Português (Brasil)**. Fonte: SDD v1.2 e `DOCUMENTACAO-TECNICA.md`.

---

## App Information

| Campo | Valor |
|---|---|
| **Nome** (≤30) | `Mais 5 Minutinhos: Despertador` |
| **Subtítulo** (≤30) | `Relógio de cabeceira retrô` |
| **Categoria primária** | Utilities (Utilidades) |
| **Categoria secundária** | Lifestyle (Estilo de vida) |
| **Copyright** | `© 2026 Alexandre Siqueira` |
| **Bundle ID** | `com.dablab.mais5minutinhos` |
| **SKU** (sugestão) | `mais5minutinhos` |
| **Idioma principal** | Português (Brasil) |

> **Nome:** o spec definia "Mais 5 Minutinhos – Despertador", que tem **31 caracteres**, um a mais que o limite. Usei **dois-pontos** no lugar do travessão (30/30). A alternativa sem pontuação, "Mais 5 Minutinhos Despertador", tem 29. O nome sob o ícone continua "5 Minutinhos".
>
> **Categoria:** Utilities, porque despertadores e relógios de cabeceira ficam aí. Não usei Health & Fitness porque o app não é de sono (anti-escopo, seção 1 do spec).

---

## Version Information

### Texto promocional (≤170)
```
À noite, um relógio de LED grande e escuro na cabeceira. De manhã, o alarme toca até no silencioso e a soneca é um botão gigante. Sem conta, sem anúncios.
```

### Descrição (≤4.000)
```
Transforme o seu iPhone num despertador de mesa de antigamente.

À noite, deixe o iPhone no carregador e ele vira um relógio grande, escuro e fácil de ler, com números de LED vermelho, placas flip ou numerais clássicos. De manhã, o alarme toca mesmo no silencioso e se resolve com um toque: Soneca é o botão gigante, Parar fica embaixo.

Sem conta, sem anúncios, sem assinatura. Nada sai do seu iPhone.

O RELÓGIO DE CABECEIRA
• Tela cheia na horizontal, fundo preto e brilho baixo que você ajusta
• A tela fica acesa a noite toda
• Mostra o dia da semana e o próximo alarme ("07:00 amanhã")
• Entra sozinho quando você deixa o iPhone no carregador com um alarme ativo: de lado num suporte ou deitado de costas na mesa
• Toque na tela para clarear por alguns segundos
• Avisa com discrição se o carregador desconectar

O ALARME QUE ACORDA DE VERDADE
• Usa os alarmes do próprio iPhone: toca com o app fechado, no modo silencioso e com o Foco ativado
• Tela de alarme com botões enormes: um toque para a soneca, um toque para parar. Sem desafios, sem contas de matemática
• Soneca de 5, 9, 10 ou 15 minutos, com contagem regressiva na tela bloqueada
• Repetição por dias da semana, com atalhos para dias úteis e todos os dias
• Até 10 alarmes, cada um com seu nome: academia, natação, corrida, trabalho

FEITO PARA QUEM ACORDA SEM ÓCULOS
Números enormes, botões gigantes e nada de slider para acertar meio dormindo. Pensado também para pessoas idosas e para quem enxerga pouco à noite.

SONS DE DESPERTADOR DE VERDADE
Use o som de alarme do próprio iPhone ou um dos sons do app: bipe digital, campainha clássica, sino, despertar suave (começa baixinho e vai crescendo), pássaros, piano da manhã e rádio-relógio.

GRÁTIS, COM UM EXTRA OPCIONAL
Alarmes, soneca e modo cabeceira são grátis e ilimitados, assim como o relógio LED clássico em vermelho e âmbar. O Mais 5 Minutinhos completo é uma compra única, sem assinatura, que libera os 4 temas (LED clássico, digital fino, grande negrito e flip), as 5 cores e todos os sons.

PRIVACIDADE
Sem cadastro, sem internet, sem anúncios, sem rastreamento. Seus alarmes e preferências ficam só no seu iPhone e somem se você apagar o app.

Requer iOS 26 ou posterior.
```

### Keywords (≤100 bytes)
```
alarme,soneca,acordar,LED,flip,radio relogio,vintage,noturno,mesa,silencioso,sono,digital,clock
```
Não repeti palavras do nome nem do subtítulo (Mais, 5, Minutinhos, Despertador, Relógio, cabeceira, retrô), porque elas já contam para a busca. "radio relogio" vai sem acento para economizar bytes; a busca da App Store ignora acentos.

### Notas da versão / What's New
```
Primeira versão do Mais 5 Minutinhos: seu iPhone vira um despertador de mesa de antigamente. Relógio de cabeceira com LED, flip e mais temas, alarme que toca no silencioso e soneca com um toque só.
```

---

## App Privacy (questionário)

**Resposta: "Data Not Collected" (Dados não coletados).**

Justificativa, conferida contra as seções 0.4, 7 e 20 do spec e o código:
- Não há conta, login, backend, analytics, Crashlytics, SDK de terceiros nem anúncios.
- Alarmes e preferências ficam só no SwiftData do aparelho e somem ao apagar o app.
- A compra única usa StoreKit, processado pela Apple. O desenvolvedor não recebe nenhum dado.
- O acelerômetro é lido só em memória, para detectar a posição do aparelho. Nada é gravado nem enviado.

---

## URLs obrigatórias

| Campo | Valor |
|---|---|
| **Support URL** | `https://suportedablab.carrd.co/` |
| **Privacy Policy URL** | `https://app.notion.com/p/POL-TICA-DE-PRIVACIDADE-APLICATIVOS-DA-DAB-LAB-2bd4305f24e180c395cdda41879cf567` |
| **Marketing URL** (opcional) | vazio |

O app abre essa mesma URL em **Ajustes › Sobre › Privacidade** (Guideline 5.1.1).

### Seção nova para adicionar ao documento "Política de Privacidade — Aplicativos da Dab Lab"

O texto genérico do documento cita Firebase Authentication, Crashlytics/Analytics e permissões de câmera, galeria e notificações. **Nada disso vale para o Mais 5 Minutinhos**, então a seção deixa isso explícito para não contradizer o "Data Not Collected":

```
Mais 5 Minutinhos – Despertador

1. Coleta de Dados
O Mais 5 Minutinhos não coleta dados pessoais. O app não tem cadastro, login ou conta, não usa Firebase Authentication, Crashlytics, Analytics nem nenhum SDK de terceiros, e não exibe anúncios. As seções genéricas deste documento sobre identificador anônimo, dados técnicos e permissões de câmera, galeria e notificações não se aplicam a este app.

2. Uso dos Dados
Os alarmes que você cria (hora, dias, nome, som e soneca) e as preferências do relógio (tema, cor, brilho e formato) são usados apenas para agendar os alarmes no próprio iPhone e mostrar o relógio. O app pede permissão para agendar alarmes do sistema, para que eles toquem com o app fechado e no silencioso. O sensor de movimento do iPhone é lido apenas enquanto o app está aberto, para saber se o aparelho está deitado no carregador; essa leitura não é gravada nem enviada.

3. Armazenamento e Segurança
Todos os dados ficam armazenados apenas no seu iPhone. Nada é enviado para servidores da Dab Lab ou de terceiros. Ao apagar o app, todos os dados são apagados junto.

4. Compartilhamento com Terceiros
Nenhum dado é compartilhado com terceiros. A compra opcional "Mais 5 Minutinhos completo" é processada inteiramente pela Apple (App Store); a Dab Lab não recebe dados de pagamento nem de identificação.

5. Contato
Dúvidas sobre privacidade: alexandre@dablab.com.br
```

---

## Pricing and Availability

| Campo | Valor |
|---|---|
| **Preço do app** | Grátis (Free) |
| **Disponibilidade** | All Countries or Regions |

### In-App Purchase

| Campo | Valor |
|---|---|
| **Tipo** | Non-Consumable (não consumível) |
| **Reference Name** | `Mais 5 Minutinhos completo (compra única)` |
| **Product ID** | `com.dablab.mais5minutinhos.completo` (igual ao código, **não mude**) |
| **Preço** | R$ 19,90 (regra 11.7) |
| **Nome de exibição** (≤30) | `Mais 5 Minutinhos completo` |
| **Descrição** (≤30) | `Todos os temas, cores e sons` |
| **Review screenshot** | print do paywall: Ajustes › Comprar |
| **Review notes do IAP** | `Libera os temas, cores e sons extras. Alarmes e modo cabeceira são grátis. Abrir em Ajustes > Comprar.` |
| **Family Sharing** | desligado (igual ao `.storekit` local) |

---

## App Review Information

| Campo | Valor |
|---|---|
| **Sign-in Required** | **Não** (o app não tem conta nem login) |
| **Contato** | Alexandre Siqueira · alexandre@dablab.com.br · (telefone: preencher) |

### Notes
```
Mais 5 Minutinhos turns the iPhone into a bedside alarm clock. The UI is in Brazilian Portuguese. Glossary: Alarmes = Alarms, Dormir = Sleep (bedside mode), Soneca = Snooze, Parar = Stop, Ajustes = Settings (gear icon, top left).

NO ACCOUNT, NO DATA COLLECTED
- There is no login, sign-up or account of any kind, so no account deletion, password or logout options apply.
- The app has no backend and no analytics or third-party SDKs. Alarms and preferences are stored only on the device (SwiftData). The only network use is StoreKit for the optional in-app purchase.
- Privacy Policy: available at the Privacy Policy URL of this listing. In-app: Ajustes > Sobre > Privacidade.

PERMISSIONS
- AlarmKit (NSAlarmKitUsageDescription): requested only when the user saves the first alarm, never at launch. Alarms are scheduled with AlarmKit so they ring with the app closed, in silent mode and with Focus on.
- The accelerometer (Core Motion, no permission prompt) is read only while the app is open, only to detect when the phone lies on its side or face up on the charger (automatic bedside mode). Nothing is stored or sent.
- No camera, photos, microphone, location, contacts, calendar, Bluetooth or notifications are used.

HOW TO TEST THE ALARM
1. Tap + (top right), set a time 2 minutes ahead, tap Salvar (Save) and allow alarms.
2. Lock the device. At the set time, the system alarm appears on the Lock Screen with a Snooze button (Soneca). Tapping Soneca shows a countdown Live Activity with a Stop button (Parar).
3. With the app open, the in-app alarm screen appears instead, with a large Soneca button and a Parar button.

HOW TO TEST THE BEDSIDE MODE
Tap Dormir (Sleep) at the bottom of the main screen. The screen turns landscape, black and dimmed, and stays on (idle timer disabled only while this screen is visible). Tap the screen to show the Sair (Exit) button. Brightness and the idle timer are restored when leaving the mode or the app.

HOW TO TEST THE IN-APP PURCHASE (non-consumable, no subscription, no trial)
Product: com.dablab.mais5minutinhos.completo, Mais 5 Minutinhos completo. It unlocks extra clock themes, colors and alarm sounds. Alarms, snooze and bedside mode are free and unlimited.
- Open the paywall from Ajustes > Comprar, or tap any item with a lock icon (themes, colors in Ajustes, or sounds in the alarm editor > Som).
- Buy with a Sandbox account: everything unlocks immediately, without restarting; Ajustes then shows Comprado (Purchased).
- Restaurar compra (Restore Purchase) is in Ajustes and in the paywall.

Support website: https://suportedablab.carrd.co/
Contact: alexandre@dablab.com.br
```

---

## App Encryption Documentation

**Resposta: "None of the algorithms mentioned above".**

O app só usa frameworks da Apple (StoreKit, AlarmKit, SwiftData) e não implementa criptografia própria. O `Info.plist` já declara `ITSAppUsesNonExemptEncryption = NO` (commit desta sessão), então os builds chegam sem o aviso "Missing Compliance".

---

## Content Rights

**Resposta: "No, it does not contain, show, or access third-party content".**

Os 7 sons foram sintetizados por código para o app (`Resources/Sounds/LICENSES.md`). Os relógios são desenhados em vetor, com fontes do sistema, e não há conteúdo licenciado de terceiros.

---

## Classificação etária (expectativa)

**4+** (expectativa, não é a resposta oficial). O app não tem conteúdo gerado por usuário visível a terceiros, rede social, chat, IA generativa, web aberta, conteúdo adulto, violência nem apostas. No questionário, responda "None" em todos os itens.

---

## Resultado da checagem de limites (`scripts/check_limits.py`)

```
Nome: 30/30 caracteres [OK]
Subtítulo: 26/30 caracteres [OK]
Texto promocional: 154/170 caracteres [OK]
Descrição: 2205/4000 caracteres [OK]
Keywords: 95/100 bytes [OK]
Notas da versão (What's New): 197/4000 caracteres [OK]
Notas de revisão (App Review): 2633/4000 caracteres [OK]
Nome de exibição do IAP: 26/30 caracteres [OK]
Descrição do IAP: 28/30 caracteres [OK]
```
