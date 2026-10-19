"""Generates the game's sound effects (small synthesized WAV files).

Run from the project root: python3 tool/gen_sounds.py
"""
import math
import struct
import wave

RATE = 22050


def tone(freqs, dur, attack=0.005, decay=6.0, vol=0.5, harmonics=(1.0, 0.3, 0.12)):
    n = int(RATE * dur)
    out = []
    for i in range(n):
        t = i / RATE
        env = min(1.0, t / attack) * math.exp(-decay * t)
        s = 0.0
        for f in freqs:
            for k, h in enumerate(harmonics, start=1):
                s += h * math.sin(2 * math.pi * f * k * t)
        out.append(s * env * vol / (len(freqs) * sum(harmonics)))
    return out


def seq(notes, gap):
    out = []
    for i, (freqs, dur) in enumerate(notes):
        start = int(i * gap * RATE)
        part = tone(freqs, dur)
        if len(out) < start + len(part):
            out.extend([0.0] * (start + len(part) - len(out)))
        for j, v in enumerate(part):
            out[start + j] += v
    return out


def save(name, samples):
    peak = max(1e-6, max(abs(s) for s in samples))
    scale = min(1.0, 0.9 / peak)
    with wave.open(f"assets/audio/{name}.wav", "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(s * scale * 32767)) for s in samples))


def note(semitones_from_a4):
    return 440.0 * 2 ** (semitones_from_a4 / 12)


save("pick", tone([note(3)], 0.06, decay=40, vol=0.35, harmonics=(1.0, 0.2)))
save("place", tone([note(-9), note(-2)], 0.12, decay=30, vol=0.6, harmonics=(1.0, 0.5, 0.2)))
save("click", tone([note(7)], 0.05, decay=50, vol=0.3, harmonics=(1.0,)))
# Clears rise along a major pentatonic scale with the combo.
for i, st in enumerate([3, 5, 7, 10, 12], start=1):
    save(f"clear{i}", seq([([note(st)], 0.35), ([note(st + 7)], 0.45)], 0.07))
save("win", seq([([note(s)], 0.5) for s in (3, 7, 10, 15)], 0.11))
save("lose", seq([([note(s)], 0.45) for s in (7, 3, -2)], 0.16))
save("revive", seq([([note(s)], 0.35) for s in (-2, 3, 7, 12)], 0.06))
