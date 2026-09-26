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
