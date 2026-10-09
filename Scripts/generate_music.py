#!/usr/bin/env python3
"""Synthesises DinoDash's calm background loop (original composition, no samples).

Slow pads over a D-major progression, a soft bass, and sparse bell-like melody notes with echo
and a touch of reverb. Everything is rendered into a *circular* buffer (notes and effect tails
wrap around the end), so the loop is seamless.

    python3 Scripts/generate_music.py out.wav
    afconvert -f m4af -d aac -b 80000 out.wav DinoDash/Resources/Sounds/music.m4a
"""
import sys
import wave
import numpy as np

SR = 32000
BPM = 54
BEAT = 60 / BPM
BARS_PER_CHORD = 2
CHORD_LEN = BARS_PER_CHORD * 4 * BEAT          # ~8.9 s
rng = np.random.default_rng(7)

def midi(n):
    return 440.0 * 2 ** ((n - 69) / 12)

# (bass root, pad voicing) — D, Bm, G, A, D, F#m, G, Em  (ends one step from D so the loop turns over)
CHORDS = [
    (38, [57, 61, 64, 66]),    # Dmaj9-ish: A C# E F#
    (35, [54, 59, 62, 66]),    # Bm: F# B D F#
    (31, [55, 59, 62, 66]),    # Gmaj7: G B D F#
    (33, [56, 61, 64, 68]),    # A: G# C# E G#  (soft A major colour)
    (38, [57, 62, 66, 69]),    # D: A D F# A
    (30, [57, 61, 64, 69]),    # F#m7 (A C# E A) over F#
    (31, [55, 59, 62, 66]),    # Gmaj7
    (28, [55, 59, 62, 67]),    # Em7/G
]
# Note: voicings are loose on purpose — everything sits in D major so any overlap stays consonant.

N_CHORDS = len(CHORDS)
TOTAL = int(N_CHORDS * CHORD_LEN * SR)
buf_l = np.zeros(TOTAL)
buf_r = np.zeros(TOTAL)
wet_l = np.zeros(TOTAL)
wet_r = np.zeros(TOTAL)

def add(buf, sig, start):
    """Add `sig` at `start` into a circular buffer."""
    n = len(sig)
    idx = (start + np.arange(n)) % TOTAL
    np.add.at(buf, idx, sig)

def env_pad(n, a, r):
    t = np.arange(n) / SR
    e = np.minimum(1, t / a) * np.minimum(1, (n / SR - t) / r)
    return np.clip(e, 0, 1) ** 1.5

def pad_note(freq, dur, pan):
    n = int(dur * SR)
    t = np.arange(n) / SR
    sig = np.zeros(n)
    for detune, amp in [(-0.004, 0.5), (0.0, 0.8), (0.004, 0.5)]:
        f = freq * (1 + detune)
        lfo = 1 + 0.003 * np.sin(2 * np.pi * (0.1 + rng.random() * 0.1) * t + rng.random() * 6)
        sig += amp * np.sin(2 * np.pi * f * t * lfo)
        sig += amp * 0.25 * np.sin(2 * np.pi * 2 * f * t)
    sig *= env_pad(n, a=2.2, r=3.0) * 0.045
    return sig * (1 - pan), sig * pan

def bass_note(freq, dur):
    n = int(dur * SR)
    t = np.arange(n) / SR
    sig = np.sin(2 * np.pi * freq * t) + 0.2 * np.sin(2 * np.pi * 2 * freq * t)
    return sig * env_pad(n, a=0.8, r=2.0) * 0.12

def bell(freq, dur=3.5):
    n = int(dur * SR)
    t = np.arange(n) / SR
    sig = (np.sin(2 * np.pi * freq * t) * np.exp(-t * 1.6)
           + 0.35 * np.sin(2 * np.pi * 2.01 * freq * t) * np.exp(-t * 3.2)
           + 0.12 * np.sin(2 * np.pi * 3.97 * freq * t) * np.exp(-t * 5))
    attack = np.minimum(1, t / 0.012)
    return sig * attack * 0.07

# --- pads + bass -----------------------------------------------------------------------------
for i, (root, voicing) in enumerate(CHORDS):
    start = int(i * CHORD_LEN * SR)
    dur = CHORD_LEN + 2.5                              # overlap into next chord for a smooth blend
    for k, note in enumerate(voicing):
        pan = 0.3 + 0.4 * (k / max(1, len(voicing) - 1))
        l, r = pad_note(midi(note), dur, pan)
        add(buf_l, l, start); add(buf_r, r, start)
        add(wet_l, l * 0.8, start); add(wet_r, r * 0.8, start)
    b = bass_note(midi(root), dur)
    add(buf_l, b, start); add(buf_r, b, start)

# --- sparse melody (D major pentatonic: D E F# A B) -------------------------------------------
PENT = [62, 64, 66, 69, 71, 74, 76, 78, 81]
MOTIFS = [
    [(0, 74), (3, 71), (5, 69)],
    [(1, 69), (4, 71)],
    [(0, 66), (2, 69), (6, 74)],
    [(2, 76), (5, 74)],
    [(0, 74), (2, 78), (6, 76)],
    [(1, 71), (3, 69), (7, 66)],
    [(0, 69), (4, 71), (6, 74)],
    [(2, 66), (5, 64)],
]
for i, motif in enumerate(MOTIFS):
    base = i * CHORD_LEN
    for beat, note in motif:
        t0 = base + beat * BEAT * (BARS_PER_CHORD * 4 / 8) + 0.5 * BEAT
        sig = bell(midi(note))
        pan = 0.25 + 0.5 * rng.random()
        s = int(t0 * SR)
        add(buf_l, sig * (1 - pan), s); add(buf_r, sig * pan, s)
        add(wet_l, sig * (1 - pan) * 1.5, s); add(wet_r, sig * pan * 1.5, s)

# --- circular echo on the melody-ish content -----------------------------------------------
def echo(x, delay_s, fb, taps):
    out = x.copy()
    for k in range(1, taps + 1):
        out += (fb ** k) * np.roll(x, int(delay_s * SR * k))
    return out

buf_l = echo(buf_l, BEAT * 0.75, 0.38, 5)
buf_r = echo(buf_r, BEAT * 1.0, 0.38, 5)

# --- reverb: circular convolution with a decaying, darkened noise impulse ----------------------
def impulse(seed):
    g = np.random.default_rng(seed)
    n = int(3.2 * SR)
    t = np.arange(n) / SR
    ir = g.standard_normal(n) * np.exp(-t * 1.9)
    k = np.ones(24) / 24                                # crude low-pass to keep it warm
    ir = np.convolve(ir, k, mode="same")
    ir[: int(0.02 * SR)] *= np.linspace(0, 1, int(0.02 * SR))
    return ir / np.sqrt(np.sum(ir ** 2))

def reverb(x, seed):
    ir = np.zeros(TOTAL)
    ir[: int(3.2 * SR)] = impulse(seed)
    return np.fft.irfft(np.fft.rfft(x) * np.fft.rfft(ir), n=TOTAL)

out_l = buf_l + 0.55 * reverb(wet_l, 1)
out_r = buf_r + 0.55 * reverb(wet_r, 2)

stereo = np.stack([out_l, out_r], axis=1)
stereo -= stereo.mean(axis=0)
stereo *= 0.6 / np.max(np.abs(stereo))                  # leave headroom; the app also lowers volume
pcm = (stereo * 32767).astype("<i2")

with wave.open(sys.argv[1] if len(sys.argv) > 1 else "music.wav", "wb") as w:
    w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR)
    w.writeframes(pcm.tobytes())
print(f"{TOTAL / SR:.1f}s loop written")
