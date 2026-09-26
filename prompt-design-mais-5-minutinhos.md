# Prompt para o Claude Design — Mais 5 Minutinhos

Cole o bloco abaixo no Claude Design.

```
Desenhe as telas de um app iOS nativo chamado "Mais 5 Minutinhos" (na App Store: "Mais 5 Minutinhos – Despertador"; sob o ícone: "5 Minutinhos"): um despertador de cabeceira para iPhone. À noite o iPhone fica deitado no carregador mostrando um relógio grande e escuro; de manhã o alarme toca e a pessoa, sonolenta e sem óculos, resolve com um toque em um botão enorme — Soneca ou Parar. Público: qualquer adulto, com atenção a idosos. Só iPhone, pt-BR.

PRINCÍPIOS (desempate de qualquer decisão)
1. Um toque para parar, um toque para soneca. Alvos enormes, nenhuma confirmação.
2. A noite é escura e calma: telas noturnas em preto puro (#000), sem nada claro ou chamativo.
3. Simplicidade antes de recurso.

O QUE EU QUERO DE VOCÊ
- Para as telas 4 (Modo cabeceira) e 5 (Alarme tocando), proponha 3 OPÇÕES VISUAIS DIFERENTES de cada, lado a lado, para eu escolher. São as telas que definem o produto.
- Para o relógio, desenhe os 4 temas: led_classico (dígitos de 7 segmentos com os segmentos apagados levemente visíveis), digital_fino (numerais finos e altos), grande_negrito (numerais pesados, máxima legibilidade), flip (placas de relógio flip). Mostre cada tema nas 5 cores: vermelho, âmbar, verde, azul, branco. Tudo original — não copie apps existentes.
- Para as demais telas, uma opção cada, seguindo os padrões nativos do iOS.
- Proponha uma direção visual coerente (não há direção visual definida no spec — a cor de destaque do app é a cor do relógio escolhida pela pessoa; default vermelho).
- Proponha também o ícone do app (2 opções). O nome tem humor — é o que todo mundo diz quando o alarme toca; o ícone pode brincar com isso (soneca, "+5", zzz), sem texto escrito no ícone. As telas noturnas continuam sóbrias.

VOCABULÁRIO OBRIGATÓRIO: IOS NATIVO, NÃO WEB
Descreva e desenhe com componentes do iOS: NavigationStack com título grande, List estilo inset grouped, Section com cabeçalho e rodapé, Toggle nativo, DatePicker em roda (wheel), Stepper/segmented control, sheet com detents, swipe actions, os estilos tipográficos semânticos do iOS (largeTitle, title, headline, body, footnote, caption), SF Symbols, barra inferior respeitando a área segura, Dynamic Type.
Reprovação automática: cards flutuantes com sombra, chips estilo web, gradientes de fundo, bordas grossas, cantos arredondados arbitrários, botões "pill" coloridos em série, emojis como ícone, texto em MAIÚSCULAS decorativas, qualquer tela que pareça um site responsivo ou "app gerado por IA".

TELAS (inventário completo — não crie telas fora desta lista)

1. Alarmes (tela inicial, retrato)
   - Título grande "Alarmes"; botão + no topo à direita; ícone de Ajustes (SF Symbol gearshape) no topo à esquerda.
   - Lista: cada alarme com a hora em tamanho grande, abaixo os dias ("Dias úteis", "Todos os dias", "Seg, Qua, Sex", "Uma vez") e o rótulo se houver; Toggle à direita. Alarme desligado fica com a hora esmaecida. Swipe para excluir.
   - Botão fixo na base: "Dormir" (entra no modo cabeceira), largo, na área segura.
   - Estados: vazio ("Nenhum alarme" / "Toque em + para criar o primeiro."); 10 alarmes com o + desabilitado e rodapé "Você chegou a 10 alarmes. Apague um para criar outro."

2. Editar alarme (sheet, retrato)
   - DatePicker de hora em roda, grande.
   - Section "Repetir": 7 botões circulares D S T Q Q S S + atalhos "Dias úteis" e "Todos os dias".
   - Section: Rótulo (campo de texto, máx. 30), Som (linha com o nome do som e chevron → tela 3).
   - Section "Soneca": Toggle + escolha 5 / 9 / 10 / 15 min (segmented control).
   - Barra superior: Cancelar / Salvar. Em edição, botão "Excluir alarme" vermelho do sistema no final.

3. Escolher som (push, retrato)
   - Lista com checkmark no selecionado: "Padrão do iPhone" (primeiro, com rodapé "Som de alarme do próprio iPhone"), Bipe digital, Campainha clássica, Sino, Despertar suave, Pássaros, Piano da manhã, Rádio-relógio.
   - Tocar num item toca prévia (indicar estado tocando com SF Symbol speaker.wave.2). Itens pagos (todos exceto Padrão do iPhone e Bipe digital) mostram lock.fill quando a compra não foi feita.

4. Modo cabeceira (paisagem, preto puro) — 3 OPÇÕES
   - Relógio ocupando a maior parte da tela no tema/cor escolhidos.
   - Linha inferior discreta: dia da semana e próximo alarme (ex.: SF Symbol alarm + "07:00 amanhã"); sem alarme: "Nenhum alarme ativo".
   - Estado "toque": brilho sobe e aparece um botão "Sair" discreto por 5 s.
   - Estado "em soneca": "Soneca até 07:09".
   - Estado "carregador desconectado": aviso discreto "O iPhone não está carregando".
   - Mostre como fica em brilho baixo (15%) — legível, sem estourar.

5. Alarme tocando (retrato E paisagem, preto puro) — 3 OPÇÕES
   - Hora atual grande no topo e o rótulo do alarme (ou "Alarme").
   - Botão "Soneca" GIGANTE (mínimo 55% da altura útil) em cima; botão "Parar" grande (mínimo 25%) embaixo. Área de toque mínima 88 pt. Nada mais na tela.
   - Variante sem soneca: só "Parar", ocupando 60%.
   - O botão deve ser óbvio para quem está sem óculos no escuro: contraste alto, texto grande, cor do relógio como destaque.

6. Ajustes (retrato)
   - No topo, prévia ao vivo do relógio num retângulo preto.
   - Section "Relógio": Tema (4 opções com miniatura), Cor (5 círculos), Formato 24 horas (Toggle), Mostrar segundos (Toggle).
   - Section "Modo cabeceira": Brilho (Slider com ícones sun.min / sun.max), Entrar automaticamente (Toggle, rodapé "Ao deitar o iPhone no carregador com um alarme ativo").
   - Section "Mais 5 Minutinhos completo": Comprar / Restaurar compra (ou "Comprado" com checkmark).
   - Section "Sobre": Privacidade ("Nenhum dado sai do seu iPhone"), versão.
   - Temas e cores pagos com lock.fill.

7. Paywall (sheet)
   - Título "Mais 5 Minutinhos completo"; texto "Todos os temas, cores e sons. Pague uma vez, use para sempre."
   - Mostre visualmente o que libera (miniaturas dos temas e lista dos sons). Botão de compra com o preço (R$ 19,90), link "Restaurar compra".
   - Estado sem rede: "Sem conexão. Tente de novo quando estiver online."

8. Permissão de alarme negada (sheet)
   - SF Symbol alarm com barra; título "Alarmes desligados"; texto "Para o Mais 5 Minutinhos tocar mesmo no silencioso, permita alarmes nos Ajustes do iPhone."; botão "Abrir Ajustes".

9. Apresentação do sistema (não é tela do app — só mostre como os textos ficam)
   - Tela bloqueada e Dynamic Island com o alarme tocando: título = rótulo ou "Alarme", botões "Parar" e "Soneca" (SF Symbol zzz), na cor do relógio.
   - Live Activity da soneca: contagem regressiva + botão "Parar".
   - Aqui o layout é da Apple; proponha apenas cor, textos e ícones.

FLUXO PRINCIPAL (desenhe as telas respeitando esta sequência)
Primeira abertura (1, vazio) → + → Editar (2) → Salvar → permissão do sistema (se negar: 8) → Lista com alarme → "Dormir" ou deitar o iPhone no carregador → Modo cabeceira (4) → na hora: Alarme tocando (5) → Soneca volta para (4) em soneca / Parar volta para (4).

COPY
Use exatamente os textos entre aspas acima; são finais. Onde faltar texto, use [placeholder: descrição] em vez de inventar.

ENTREGA
Exporte o design system (cores, tipografia, os 4 temas de relógio, componentes) e as telas escolhidas, para eu salvar na pasta mais5-design-system/ do repositório como referência definitiva para o Claude Code.
```
