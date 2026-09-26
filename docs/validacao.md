# Validação dos épicos (critérios de aceite, seção 8)

A seção 26 exige todos os critérios de 8.1 a 8.8 verificados em iPhone físico antes do envio. Esta tabela mostra o que já foi verificado e onde.

| Épico | Status | Como foi verificado |
|---|---|---|
| 8.1 Spike AlarmKit | ✅ aprovado | iPhone 13 mini, iOS 26.6.2 (docs/spike-alarmkit.md) |
| 8.2 Fundação | ✅ aprovado | build limpo, testes, banco copiado do iPhone (1 linha de `preferencias`), ícone e nome na tela de início |
| 8.3 Lista e edição | ⚠️ parcial | Simulador: lista, estado vazio, edição, pedido de permissão ao salvar, recusa → alarme inativo + 10.8, toggle sem permissão → 10.8. Testes: texto de dias, próximo alarme, reconciliação 11.6. **Não verificado no iPhone** (Alexandre optou por pular em 26/09/2026): agendar/tocar, toggle cancelando, edição reagendando, exclusão, toque único → `ativo = false`, limite de 10. Cobrir no roteiro final antes do envio (seção 22). |
