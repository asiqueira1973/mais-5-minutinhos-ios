# Prompt de implementação — Claude Code

```
O app se chama "Mais 5 Minutinhos" (CFBundleDisplayName "5 Minutinhos"). Leia o documento SDD-mais-5-minutinhos.md na raiz do repositório e a pasta mais5-design-system/ (referência definitiva de UI). Não escreva código antes de montar o plano e a lista de tarefas e me mostrar para aprovação.

Ordem de implementação (por seção do spec):
1. Épico 8.1 — spike técnico do AlarmKit. É um portão: implemente só o app mínimo do spike, pare e me peça para testar no iPhone físico. Registre o resultado em docs/spike-alarmkit.md. Só siga com minha confirmação. Se o som próprio falhar, aplique o fallback customSoundsEnabled = false (regra 11.3).
2. 8.2 Fundação (XcodeGen, SwiftData versionado, singleton de preferencias, CLAUDE.md, Widget extension).
3. 8.3 Lista e edição + AlarmScheduler + reconciliação 11.6.
4. 8.4 Seletor de som. 5. 8.5 Modo cabeceira. 6. 8.6 Alarme tocando + Live Activity de soneca. 7. 8.7 Ajustes. 8. 8.8 Compra única.

Escopo: só o MVP da seção 3. NÃO implemente nada da seção 28 (som importado pelo usuário, Apple Watch, fade-in), nem clima, lanterna, sons para dormir ou iPad.

Regras:
- Os princípios da seção 0 são a regra de desempate.
- Confira as assinaturas das APIs do AlarmKit na documentação do SDK instalado, não de memória (premissa P4).
- Modelos SwiftData em português, snake_case no armazenamento, exatamente como na seção 7; código, variáveis e arquivos em inglês.
- Toda função e tipo com comentário de cabeçalho em português: o que faz, entradas, saídas e a regra do spec que implementa (com número). Lógica não óbvia com comentário inline.
- Siga literalmente as tabelas de regras (seção 11) e a copy (seção 15). Não invente valores nem textos.
- Valide cada épico contra seus critérios de aceite antes de seguir; AlarmKit só se valida em aparelho físico — nesses critérios, me peça o teste.
- Diante de qualquer item da seção 25 (perguntas abertas), pergunte em vez de assumir. Para os sons próprios, use placeholders marcados até eu entregar os arquivos.
- Ao final, gere DOCUMENTACAO-TECNICA.md com os seis itens da seção 19, a partir do que foi realmente implementado, e atualize CLAUDE.md e README.
```
