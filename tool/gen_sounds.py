"""Generates the game's sound effects (small synthesized WAV files).

Run from the project root: python3 tool/gen_sounds.py
"""
import math
import struct
import wave

RATE = 44100


def tone(freqs, dur, attack=0.006, decay=6.0, vol=0.5, harmonics=(1.0, 0.3, 0.12),
         release=0.02):
    """A note with a smooth start and a smooth end that reaches exactly zero.

    A sound that starts or stops abruptly (a straight ramp up, or a decay
    cut off before it is silent) clicks on the speaker: the "estalinho"
    players heard when placing a piece.
    """
    n = int(RATE * dur)
    release = min(release, dur / 3)
    out = []
    for i in range(n):
        t = i / RATE
        # Raised-cosine attack and release (no corners in the envelope).
        a = 0.5 * (1 - math.cos(math.pi * min(1.0, t / attack)))
        left = dur - t
        r = 1.0 if left >= release else 0.5 * (1 - math.cos(math.pi * max(0.0, left) / release))
        env = a * r * math.exp(-decay * t)
        s = 0.0
        for f in freqs:
            for k, h in enumerate(harmonics, start=1):
                s += h * math.sin(2 * math.pi * f * k * t)
        out.append(s * env * vol / (len(freqs) * sum(harmonics)))
    out[0] = 0.0
    out[-1] = 0.0
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
# Praise stingers: brighter and longer as the move gets bigger.
save("praise2", seq([([note(s)], 0.3) for s in (10, 15, 19)], 0.05))
save("praise3", seq([([note(s), note(s + 4)], 0.4) for s in (7, 12, 15, 19)], 0.07))
save("praise4", seq([([note(s), note(s + 7)], 0.55) for s in (3, 7, 10, 15, 19, 22, 27)], 0.06))
