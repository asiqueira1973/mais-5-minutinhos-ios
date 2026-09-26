#!/usr/bin/env python3
"""Sintetiza os sons próprios do app por código (regra 11.3).

Os sons são originais, gerados matematicamente, sem amostras de terceiros.
Saída: WAV mono 16-bit 44,1 kHz em <pasta>/<nome>.wav; converta para .caf
Linear PCM com:
    afconvert -f caff -d LEI16@44100 -c 1 x.wav x.caf

Uso: python3 scripts/make-sounds.py <pasta_wav>

Status: PLACEHOLDER até Alexandre aprovar ou trocar cada som (pergunta 25.2).
"""
import math
import random
import struct
import sys
import wave

SR = 44100
random.seed(5)  # determinístico: o mesmo script gera sempre os mesmos arquivos


def silence(seconds):
    return [0.0] * int(SR * seconds)


def mix(dst, src, start):
    """Soma `src` em `dst` a partir da amostra `start`, estendendo se preciso."""
    end = start + len(src)
    if end > len(dst):
        dst.extend([0.0] * (end - len(dst)))
    for i, v in enumerate(src):
        dst[start + i] += v


def partial_tone(freq, seconds, partials, decay, attack=0.002):
    """Tom com parciais (razão, amplitude, fator de decaimento) e envelope exponencial."""
    n = int(SR * seconds)
    out = [0.0] * n
    for i in range(n):
        t = i / SR
        env = min(1.0, t / attack) if attack > 0 else 1.0
        s = 0.0
        for ratio, amp, dk in partials:
            s += amp * math.exp(-t * decay * dk) * math.sin(2 * math.pi * freq * ratio * t)
        out[i] = s * env
    return out


def fade_edges(buf, seconds=0.02):
    """Rampas curtas no início e no fim para o loop não estalar."""
    k = int(SR * seconds)
    for i in range(min(k, len(buf))):
        g = i / k
        buf[i] *= g
        buf[-1 - i] *= g
    return buf


def normalize(buf, peak=0.85):
    m = max(abs(v) for v in buf) or 1.0
    return [v * peak / m for v in buf]


def write(path, buf):
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, v)) * 32767)) for v in buf))


# --- Sons -------------------------------------------------------------------

def campainha_classica():
    """Campainha mecânica: martelo batendo rápido entre duas campânulas metálicas.
    2 s tocando, 1 s de pausa, 4 ciclos (12 s)."""
    metal = [(1.0, 1.0, 1.0), (2.76, 0.5, 1.6), (5.40, 0.25, 2.2), (8.93, 0.12, 3.0)]
    bell_a = partial_tone(1750, 0.5, metal, decay=6)
    bell_b = partial_tone(1960, 0.5, metal, decay=6)
    out = []
    for _ in range(4):
        start = len(out)
        for k in range(int(2.0 * 18)):  # ~18 batidas por segundo
            mix(out, bell_a if k % 2 == 0 else bell_b, start + int(k * SR / 18))
        out.extend(silence(1.0))
        out = out[: start + int(3.0 * SR)]
    return out


def sino():
    """Sino grave e suave, uma badalada a cada 2,5 s, parciais de sino de igreja (12,5 s)."""
    church = [(0.5, 0.6, 0.6), (1.0, 1.0, 1.0), (1.19, 0.5, 1.3), (1.56, 0.4, 1.6),
              (2.0, 0.35, 2.0), (2.51, 0.2, 2.6), (3.01, 0.12, 3.2)]
    strike = partial_tone(523.25, 3.5, church, decay=1.3)
    out = silence(12.5)
    for k in range(5):
        mix(out, strike, int(k * 2.5 * SR))
    return out[: int(12.5 * SR)]


def despertar_suave():
    """Arpejo de marimba em pentatônica maior, crescente de ~10% a 100% em 20 s (regra 11.3)."""
    marimba = [(1.0, 1.0, 1.0), (4.0, 0.25, 3.5), (9.2, 0.06, 6.0)]
    notes = [523.25, 659.25, 783.99, 880.00, 1046.50, 880.00, 783.99, 659.25]
    total = 20.0
    out = silence(total)
    step = 0.3
    k = 0
    t = 0.0
    while t < total - 0.8:
        note = partial_tone(notes[k % len(notes)], 0.9, marimba, decay=5)
        mix(out, note, int(t * SR))
        t += step
        k += 1
    out = out[: int(total * SR)]
    for i in range(len(out)):
        # Curva de volume: começa baixo e chega ao máximo no fim dos 20 s.
        g = 0.1 + 0.9 * (i / len(out)) ** 1.6
        out[i] *= g
    return out


def passaros():
    """Pios sintéticos: varreduras rápidas de frequência (2,5–6 kHz) em frases aleatórias (12 s)."""
    total = 12.0
    out = silence(total)
    t = 0.2
    while t < total - 1.0:
        phrase = random.randint(2, 5)
        base = random.uniform(2500, 4200)
        for _ in range(phrase):
            dur = random.uniform(0.06, 0.14)
            n = int(SR * dur)
            chirp = []
            phase = 0.0
            up = random.random() < 0.6
            for i in range(n):
                x = i / n
                f = base * (1 + (0.45 * x if up else 0.45 * (1 - x)))
                f *= 1 + 0.04 * math.sin(2 * math.pi * 38 * i / SR)  # trinado
                phase += 2 * math.pi * f / SR
                env = math.sin(math.pi * x) ** 2
                chirp.append(env * math.sin(phase))
            mix(out, chirp, int(t * SR))
            t += dur + random.uniform(0.03, 0.08)
        t += random.uniform(0.4, 1.2)
    return out[: int(total * SR)]


def piano_manha():
    """Melodia curta e alegre em dó maior com timbre de piano aditivo, tocada 2 vezes
    sobre o baixo (8 s, sem silêncio no fim para o loop não ter buraco)."""
    piano = [(1.0, 1.0, 1.0), (2.0, 0.5, 1.5), (3.0, 0.25, 2.2), (4.01, 0.12, 3.0), (5.02, 0.06, 3.8)]
    c4 = 261.63
    semis = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}

    def f(name, octave):
        return c4 * 2 ** (semis[name] / 12 + (octave - 4))

    melody = [("E", 5, 0.5), ("G", 5, 0.5), ("C", 6, 1.0), ("B", 5, 0.5), ("G", 5, 0.5), ("A", 5, 1.0),
              ("G", 5, 0.5), ("E", 5, 0.5), ("F", 5, 0.5), ("D", 5, 0.5), ("C", 5, 2.0)]
    bass = [("C", 3, 2.0), ("F", 3, 2.0), ("G", 3, 2.0), ("C", 3, 2.0)]
    total = 8.0
    out = silence(total)
    t = 0.0
    for _ in range(2):  # a melodia dura 4 s; duas passadas enchem os 8 s
        for name, octave, beats in melody:
            mix(out, partial_tone(f(name, octave), 2.0, piano, decay=2.2), int(t * SR))
            t += beats * 0.5
    t = 0.0
    for name, octave, beats in bass:
        tone = [v * 0.5 for v in partial_tone(f(name, octave), 2.5, piano, decay=1.4)]
        mix(out, tone, int(t * SR))
        t += beats * 0.5 * 2
    return out[: int(total * SR)]


def radio_relogio():
    """Buzzer de rádio-relógio: onda quadrada suavizada, 4 bipes rápidos + pausa (8 s)."""
    total = 8.0
    out = silence(total)
    beep_len = 0.12
    for cycle in range(8):
        base = cycle * 1.0
        for k in range(4):
            start = base + k * 0.16
            n = int(SR * beep_len)
            tone = []
            for i in range(n):
                t = i / SR
                # Soma das 4 primeiras harmônicas ímpares ≈ quadrada sem aspereza.
                s = sum(math.sin(2 * math.pi * 880 * h * t) / h for h in (1, 3, 5, 7))
                env = min(1.0, i / 90, (n - i) / 90)
                tone.append(s * env)
            mix(out, tone, int(start * SR))
    return out[: int(total * SR)]


SOUNDS = {
    "campainha_classica": campainha_classica,
    "sino": sino,
    "despertar_suave": despertar_suave,
    "passaros": passaros,
    "piano_manha": piano_manha,
    "radio_relogio": radio_relogio,
}

if __name__ == "__main__":
    folder = sys.argv[1]
    for name, make in SOUNDS.items():
        buf = normalize(fade_edges(make()))
        write(f"{folder}/{name}.wav", buf)
        print(f"{name}: {len(buf) / SR:.1f} s")
