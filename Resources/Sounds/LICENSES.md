# Licenças dos sons (regra 11.3)

Os 7 sons próprios são **sintetizados por código** para o Mais 5 Minutinhos. Não usam gravações nem amostras de terceiros e não imitam toques da Apple. São obra original do projeto, sem restrição de uso.

Decisão de 26/09/2026 (pergunta 25.2): Alexandre aprovou os sons sintéticos como sons do app, porque combinam com a proposta "vintage" de despertador de mesa. Algum som pode ser trocado depois de ouvir na prévia (tela 10.3).

Formato: `.caf`, Linear PCM 16-bit, 44,1 kHz, mono, ≤ 30 s, com rampas de 20 ms nas pontas para repetir sem estalo. Build 3 (27/09/2026): compressão suave (tanh) e pico de 98% para soarem mais alto no volume de toque.

| Arquivo | Duração | Como foi gerado | Licença |
|---|---|---|---|
| `bipe_digital.caf` | 4 s | 4 bipes de 2 kHz × 4 | original do projeto |
| `campainha_classica.caf` | 12 s | Martelo a 18 batidas/s entre duas campânulas com parciais metálicas; 2 s tocando, 1 s de pausa | original do projeto |
| `sino.caf` | 12,5 s | Badalada a cada 2,5 s com parciais de sino (dó 5) | original do projeto |
| `despertar_suave.caf` | 20 s | Arpejo de marimba em pentatônica, volume crescente de 10% a 100% em 20 s | original do projeto |
| `passaros.caf` | 12 s | Pios por varredura de frequência 2,5–6 kHz com trinado, frases aleatórias (semente fixa) | original do projeto |
| `piano_manha.caf` | 8 s | Melodia em dó maior, piano por síntese aditiva, 2 passadas sobre baixo | original do projeto |
| `radio_relogio.caf` | 8 s | Buzzer de 880 Hz (quadrada suavizada), 4 bipes por segundo | original do projeto |

Para regerar: `python3 scripts/make-sounds.py <pasta>` e depois `afconvert -f caff -d LEI16@44100 -c 1 <x>.wav Resources/Sounds/<x>.caf`.
