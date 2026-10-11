#!/usr/bin/env python3
"""Generates assets/audio/battle_loop.ogg: an original, instrumental,
cyber/synthwave arcade loop for the BrainSpeed IQ battle screen.

Every sound is synthesized here from sine/saw/square oscillators, filtered
noise, and envelopes. No samples, recordings, or third-party melodies are used,
so the output is an original work dedicated to the public domain (CC0 1.0).
See assets/audio/LICENSE.md.

Usage (developer machine only; the app does not run this script):

    python3 -m venv .venv-audio
    .venv-audio/bin/pip install numpy soundfile
    .venv-audio/bin/python tools/audio/generate_battle_loop.py

The output is deterministic: the same script always writes the same file.
The loop is built on a periodic buffer, so note tails wrap around and the
loop point has no click or gap.
"""

from __future__ import annotations

import math
from pathlib import Path

import numpy as np
import soundfile as sf

SAMPLE_RATE = 44_100
BPM = 100.0
BEATS_PER_BAR = 4
BARS = 16
OUTPUT = Path(__file__).resolve().parents[2] / "assets" / "audio" / "battle_loop.ogg"

BEAT = 60.0 / BPM
LOOP_SECONDS = BARS * BEATS_PER_BAR * BEAT
N = int(round(LOOP_SECONDS * SAMPLE_RATE))

# A minor: i - VI - III - VII, then a variation for bars 9-16.
CHORDS = [
    ("Am", [57, 60, 64]),  # A3 C4 E4
    ("F", [53, 57, 60]),  # F3 A3 C4
    ("C", [60, 64, 67]),  # C4 E4 G4
    ("G", [55, 59, 62]),  # G3 B3 D4
]
PROGRESSION = [0, 1, 2, 3, 0, 3, 1, 3, 0, 1, 2, 3, 0, 3, 2, 1]


def midi_hz(note: float) -> float:
    return 440.0 * 2.0 ** ((note - 69) / 12.0)


def time_axis(length: int) -> np.ndarray:
    return np.arange(length) / SAMPLE_RATE


def envelope(length: int, attack: float, decay_rate: float) -> np.ndarray:
    t = time_axis(length)
    attack_env = np.minimum(1.0, t / max(attack, 1e-4))
    return attack_env * np.exp(-decay_rate * t)


def saw(freq: float, length: int, harmonics: int = 10) -> np.ndarray:
    """Band-limited sawtooth built from its first harmonics."""
    t = time_axis(length)
    out = np.zeros(length)
    for k in range(1, harmonics + 1):
        if freq * k >= SAMPLE_RATE / 2:
            break
        out += np.sin(2 * math.pi * freq * k * t) / k
    return out * (2.0 / math.pi)


def square(freq: float, length: int, harmonics: int = 9) -> np.ndarray:
    """Band-limited square built from odd harmonics."""
    t = time_axis(length)
    out = np.zeros(length)
    for k in range(1, harmonics * 2, 2):
        if freq * k >= SAMPLE_RATE / 2:
            break
        out += np.sin(2 * math.pi * freq * k * t) / k
    return out * (4.0 / math.pi)


def one_pole_lowpass(signal: np.ndarray, cutoff_hz: float) -> np.ndarray:
    """Simple one-pole lowpass for softening saws and noise."""
    alpha = 1.0 - math.exp(-2.0 * math.pi * cutoff_hz / SAMPLE_RATE)
    out = np.empty_like(signal)
    state = 0.0
    for i, x in enumerate(signal):
        state += alpha * (x - state)
        out[i] = state
    return out


def add_wrapped(buffer: np.ndarray, start_sample: int, clip: np.ndarray) -> None:
    """Adds `clip` at `start_sample` on a periodic buffer (wraps at loop end)."""
    idx = (np.arange(len(clip)) + start_sample) % N
    np.add.at(buffer, idx, clip)


def kick(length: int = int(0.32 * SAMPLE_RATE)) -> np.ndarray:
    t = time_axis(length)
    freq = 46 + 74 * np.exp(-t * 28)
    phase = 2 * math.pi * np.cumsum(freq) / SAMPLE_RATE
    return np.sin(phase) * np.exp(-t * 9.0)


def snare(rng: np.random.Generator, length: int = int(0.18 * SAMPLE_RATE)) -> np.ndarray:
    noise = rng.uniform(-1.0, 1.0, length)
    body = np.sin(2 * math.pi * 185 * time_axis(length)) * 0.35
    return (one_pole_lowpass(noise, 5200) * 0.8 + body) * envelope(length, 0.001, 22)


def hat(rng: np.random.Generator, length: int = int(0.05 * SAMPLE_RATE)) -> np.ndarray:
    noise = rng.uniform(-1.0, 1.0, length)
    highpassed = noise - one_pole_lowpass(noise, 7000)
    return highpassed * envelope(length, 0.0005, 80)


def pluck(note: float, length: int) -> np.ndarray:
    tone = square(midi_hz(note), length, harmonics=5)
    return tone * envelope(length, 0.002, 14)


def pad(chord: list[int], length: int) -> np.ndarray:
    voices = np.zeros(length)
    for note in chord:
        voices += saw(midi_hz(note), length, harmonics=8)
        voices += saw(midi_hz(note) * 1.004, length, harmonics=8)  # slight detune
    voices = one_pole_lowpass(voices, 900)
    return voices * envelope(length, 0.35, 0.8)


def bass(root_note: int, length: int) -> np.ndarray:
    tone = square(midi_hz(root_note - 12), length, harmonics=4)
    return one_pole_lowpass(tone, 380) * envelope(length, 0.005, 9)


def pan(mono: np.ndarray, position: float) -> np.ndarray:
    """Constant-power pan. position: -1 left .. +1 right."""
    angle = (position + 1.0) * math.pi / 4.0
    return np.stack([mono * math.cos(angle), mono * math.sin(angle)], axis=1)


def build() -> np.ndarray:
    rng = np.random.default_rng(20261010)
    pad_bus = np.zeros(N)
    bass_bus = np.zeros(N)
    drum_bus = np.zeros(N)
    arp_bus = np.zeros((N, 2))

    beat_samples = int(round(BEAT * SAMPLE_RATE))
    eighth = beat_samples // 2
    sixteenth = beat_samples // 4
    total_beats = BARS * BEATS_PER_BAR

    for bar in range(BARS):
        _, chord = CHORDS[PROGRESSION[bar]]
        bar_start = bar * BEATS_PER_BAR * beat_samples
        bar_len = BEATS_PER_BAR * beat_samples

        # Pad: one sustained chord per bar, quiet.
        add_wrapped(pad_bus, bar_start, pad(chord, bar_len) * 0.030)

        # Bass: eighth-note pulse on the chord root with an octave pop.
        root = chord[0]
        for step in range(BEATS_PER_BAR * 2):
            note = root + (12 if step % 4 == 3 else 0)
            add_wrapped(
                bass_bus,
                bar_start + step * eighth,
                bass(note, eighth) * 0.16,
            )

        # Arp: sixteenth-note cycle through the chord, panned left/right.
        arp_notes = [chord[0] + 12, chord[1] + 12, chord[2] + 12, chord[1] + 12]
        for step in range(BEATS_PER_BAR * 4):
            note = arp_notes[step % len(arp_notes)]
            clip = pluck(note, sixteenth * 2) * 0.030
            position = -0.55 if step % 2 == 0 else 0.55
            add_wrapped(arp_bus, bar_start + step * sixteenth, pan(clip, position))

        # Drums: kick on 1 and 3, clap-like snare on 2 and 4, closed hats on 8ths.
        for beat in range(BEATS_PER_BAR):
            beat_start = bar_start + beat * beat_samples
            if beat in (0, 2):
                add_wrapped(drum_bus, beat_start, kick() * 0.36)
            else:
                add_wrapped(drum_bus, beat_start, snare(rng) * 0.10)
            for half in range(2):
                hat_level = 0.040 if half == 0 else 0.026
                add_wrapped(drum_bus, beat_start + half * eighth, hat(rng) * hat_level)

    mix = np.zeros((N, 2))
    mix += pan(pad_bus, 0.0)
    mix += pan(bass_bus, 0.0)
    mix += pan(drum_bus, 0.0)
    mix += arp_bus

    # Gentle overall level: quiet by design, so quiz text stays the focus.
    peak = np.max(np.abs(mix))
    target_peak = 0.32  # about -10 dBFS
    mix *= target_peak / peak
    assert total_beats * beat_samples == N
    return mix.astype(np.float32)


def main() -> None:
    mix = build()
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    sf.write(
        str(OUTPUT),
        mix,
        SAMPLE_RATE,
        format="OGG",
        subtype="VORBIS",
    )
    rms = float(np.sqrt(np.mean(mix**2)))
    peak = float(np.max(np.abs(mix)))
    print(
        f"wrote {OUTPUT} | {LOOP_SECONDS:.2f}s loop | {BPM:.0f} BPM | "
        f"peak {20 * math.log10(peak):.1f} dBFS | rms {20 * math.log10(rms):.1f} dBFS"
    )


if __name__ == "__main__":
    main()
