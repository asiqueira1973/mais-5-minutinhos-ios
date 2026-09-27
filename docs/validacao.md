# Validação dos épicos (critérios de aceite, seção 8)

A seção 26 exige todos os critérios de 8.1 a 8.8 verificados em iPhone físico antes do envio. Esta tabela mostra o que já foi verificado e onde.

| Épico | Status | Como foi verificado |
|---|---|---|
| 8.1 Spike AlarmKit | ✅ aprovado | iPhone 13 mini, iOS 26.6.2 (docs/spike-alarmkit.md) |
| 8.2 Fundação | ✅ aprovado | build limpo, testes, banco copiado do iPhone (1 linha de `preferencias`), ícone e nome na tela de início |
| 8.3 Lista e edição | ⚠️ parcial | Simulador: lista, estado vazio, edição, pedido de permissão ao salvar, recusa → alarme inativo + 10.8, toggle sem permissão → 10.8. Testes: texto de dias, próximo alarme, reconciliação 11.6. **Não verificado no iPhone** (Alexandre optou por pular em 26/09/2026): agendar/tocar, toggle cancelando, edição reagendando, exclusão, toque único → `ativo = false`, limite de 10. Cobrir no roteiro final antes do envio (seção 22). |
| 8.4 Seletor de som | ⚠️ parcial | Simulador: tela 10.3 (padrão com rodapé, 7 sons, cadeado nos pagos), som pago → prévia + paywall. Testes: catálogo, arquivos no bundle, som efetivo sem compra. **A ouvir no iPhone:** as prévias (≤ 5 s, param ao sair ou ao tocar outro som) e a qualidade dos 7 sons sintéticos. |
| 8.5 Modo cabeceira | ⚠️ parcial | iPhone (spike): layout 4C, LED, brilho da noite, toque → 60% + Sair, alarme por cima com brilho a 60%, devolução do brilho ao sair. Simulador: 4 temas (LED, digital fino, grande negrito, flip), 12h com AM/PM, segundos, área segura em paisagem. Testes: regra 11.4 e classificação da posição. **A verificar no iPhone:** entrada automática (deitado/de lado no carregador com alarme nas próximas 14 h), seguir o lado da paisagem com bloqueio de rotação, aviso de carregador desconectado (15.5), deslocamento anti-marcação. |
| 8.6 Alarme tocando | ⚠️ parcial | iPhone (spike): 10.5 abre em 82 ms, Soneca/Parar cortam o som na hora, soneca volta após 5 min, Live Activity com contagem e Parar, Soneca legível na tela bloqueada. Simulador (gancho `-debugRinging`): 10.5 com Soneca 57% e Parar 26% da altura útil, relógio no tema. Simulador (`-debugSnooze`): "Soneca até" na cabeceira. **A verificar no iPhone** (Alexandre sem poder tocar alarme em 26/09): toque único parado → `ativo = false` na lista; alarme sem soneca → só Parar; "Soneca até" com soneca real; 10.5 em paisagem. |
| 8.7 Ajustes e temas | ✅ simulador | Tela 10.6 completa (prévia ao vivo, 4 temas com miniaturas, 5 cores, 24h, segundos, brilho com prévia, entrada automática, compra, sobre). Cadeado nos pagos → paywall. Testes da regra 11.7 e do tema/cor efetivos sem compra. Mudar a cor reagenda os alarmes para a apresentação do sistema usar a cor nova. **A ver no iPhone:** prévia do brilho ao arrastar o slider. |
| 8.8 Compra única | ✅ testes + simulador | StoreKitTest com `MaisCincoMinutinhos.storekit`: produto carrega com preço, compra libera na hora, reembolso retira o acesso, restaurar sem compra não trava. Simulador: paywall completo (miniaturas, cores, sons, "Comprar por" + `displayPrice`), preço nos Ajustes, "Comprado" após compra. Liberar/retirar reconcilia sons (11.6) e reagenda a cor. **A verificar antes do envio:** compra real em sandbox/TestFlight; "Restaurar compra" em aparelho novo; paywall sem rede no iPhone (modo avião → 15.7). |
| 10.10 Como usar | ✅ simulador | Copy 15.11 aprovada, link em Ajustes › Sobre. |

## Submissão

- 26/09/2026: build 1.0.0 (2), só iPhone, submetido à App Store ("Waiting for Review"). O build 1 saiu com iPad por engano e não foi usado.
- **Em aberto:** o roteiro em aparelho acima foi feito só em parte (spike 8.1 e testes visuais). Rodar pelo TestFlight durante a revisão; se algo falhar, cancelar a submissão e enviar build 3.
- 26/09/2026, TestFlight build 2 (iPhone 13 mini): compra em sandbox liberou tema/cor (flip âmbar), cabeceira com próximo alarme "hoje", alarme tocou com o app aberto (10.5 em paisagem), soneca → "Soneca até 17:31" → tocou de novo após 5 min → Parar. ✅ Observado: com o app aberto, o AlarmKit também mostra o banner do sistema ("5 Minutinhos / Alarme") por cima da 10.5; fora do controle do app.
- Ainda a conferir: Foco Dormir, alarme de toque único aparece desligado na lista depois de parar, entrada automática no carregador, "Restaurar compra".
- 27/09/2026, build 2: alarme diário 8:27 não tocou (causa: reagendamentos concorrentes do mesmo id, ver DOCUMENTACAO-TECNICA §6 item 19). Versão retirada da revisão.
- 27/09/2026, TestFlight build 3: alarme com som padrão e alarme com Rádio-relógio tocaram **com o app reaberto antes do horário** (o cenário que falhava no build 2). ✅ Correção validada no aparelho.
- 27/09/2026: build 1.0.0 (3) selecionado na versão 1.0.0 e reenviado à revisão.
