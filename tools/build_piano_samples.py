#!/usr/bin/env python3
"""
Build bundled piano samples from the University of Iowa MIS Steinway recordings.

Downloads Piano.mf.<note>.aiff for A1-C5, then per note:
  - converts to 48 kHz stereo WAV (afconvert)
  - downmixes to mono, trims leading silence to ~2 ms pre-attack
  - keeps up to 6 s of natural decay
  - applies a 1 ms fade-in (preserve hammer transient) and a 250 ms fade tail
  - peak-normalizes to -3 dBFS
  - writes <Stem><Octave>_pno.caf (Int16 mono 48 kHz) into the app's Samples dir

Usage: python3 tools/build_piano_samples.py
Requires: network access, afconvert (macOS).
"""

import math
import pathlib
import shutil
import struct
import subprocess
import sys
import tempfile
import urllib.request
import wave

BASE_URL = "https://theremin.music.uiowa.edu/sound%20files/MIS/Piano_Other/piano"
DYNAMIC = "mf"
SAMPLE_RATE = 48_000
MAX_SECONDS = 6.0
# Keep only a couple of ms before the hammer so scheduled onsets feel immediate.
PRE_ATTACK_SECONDS = 0.002
# Tiny fade-in only — longer ramps dull the felt-hammer transient.
FADE_IN_SECONDS = 0.001
FADE_OUT_SECONDS = 0.250
TARGET_PEAK = 10 ** (-3.0 / 20.0)  # -3 dBFS
ONSET_THRESHOLD_RATIO = 0.02

REPO_ROOT = pathlib.Path(__file__).resolve().parent.parent
SAMPLES_DIR = REPO_ROOT / "Functional Harmony" / "Audio" / "Samples"
CACHE_DIR = REPO_ROOT / "tools" / ".iowa_cache"

SHARP_STEMS = ["C", "Cs", "D", "Ds", "E", "F", "Fs", "G", "Gs", "A", "As", "B"]
# Iowa files use flat spellings for accidentals.
IOWA_NAMES = {"Cs": "Db", "Ds": "Eb", "Fs": "Gb", "Gs": "Ab", "As": "Bb"}

MIN_MIDI = 33  # A1
MAX_MIDI = 72  # C5


def sample_key(midi: int) -> str:
    octave = midi // 12 - 1
    stem = SHARP_STEMS[midi % 12]
    return f"{stem}{octave}"


def iowa_note_name(midi: int) -> str:
    octave = midi // 12 - 1
    stem = SHARP_STEMS[midi % 12]
    return f"{IOWA_NAMES.get(stem, stem)}{octave}"


def download(midi: int) -> pathlib.Path:
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    name = iowa_note_name(midi)
    dest = CACHE_DIR / f"Piano.{DYNAMIC}.{name}.aiff"
    if dest.exists() and dest.stat().st_size > 100_000:
        return dest
    url = f"{BASE_URL}/Piano.{DYNAMIC}.{name}.aiff"
    print(f"  downloading {url}")
    with urllib.request.urlopen(url, timeout=120) as response, open(dest, "wb") as out:
        shutil.copyfileobj(response, out)
    if dest.stat().st_size < 100_000:
        raise RuntimeError(f"suspiciously small download for {name}")
    return dest


def afconvert(args: list[str]) -> None:
    subprocess.run(["afconvert", *args], check=True, capture_output=True)


def read_wav_mono(path: pathlib.Path) -> list[float]:
    with wave.open(str(path), "rb") as wav:
        channels = wav.getnchannels()
        width = wav.getsampwidth()
        rate = wav.getframerate()
        frames = wav.getnframes()
        if width != 2 or rate != SAMPLE_RATE:
            raise RuntimeError(f"unexpected wav format {width * 8}-bit {rate} Hz for {path}")
        raw = wav.readframes(frames)
    total = len(raw) // 2
    ints = struct.unpack(f"<{total}h", raw)
    if channels == 1:
        return [s / 32768.0 for s in ints]
    mono = []
    for i in range(0, total - channels + 1, channels):
        mono.append(sum(ints[i:i + channels]) / channels / 32768.0)
    return mono


def process(samples: list[float]) -> list[float]:
    peak = max(abs(s) for s in samples)
    if peak <= 0:
        raise RuntimeError("silent source")

    threshold = peak * ONSET_THRESHOLD_RATIO
    onset = next(i for i, s in enumerate(samples) if abs(s) >= threshold)
    start = max(0, onset - int(PRE_ATTACK_SECONDS * SAMPLE_RATE))
    end = min(len(samples), start + int(MAX_SECONDS * SAMPLE_RATE))
    out = samples[start:end]

    fade_in = int(FADE_IN_SECONDS * SAMPLE_RATE)
    for i in range(min(fade_in, len(out))):
        out[i] *= i / fade_in

    fade_out = min(int(FADE_OUT_SECONDS * SAMPLE_RATE), len(out))
    total = len(out)
    for i in range(fade_out):
        t = (i + 1) / fade_out
        gain = 0.5 * (1 + math.cos(math.pi * t))
        out[total - fade_out + i] *= gain
    out[-1] = 0.0

    peak = max(abs(s) for s in out)
    gain = TARGET_PEAK / peak
    return [s * gain for s in out]


def write_wav_mono(path: pathlib.Path, samples: list[float]) -> None:
    ints = [max(-32768, min(32767, int(round(s * 32767.0)))) for s in samples]
    with wave.open(str(path), "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(SAMPLE_RATE)
        wav.writeframes(struct.pack(f"<{len(ints)}h", *ints))


def build_note(midi: int, tmp: pathlib.Path) -> pathlib.Path:
    key = sample_key(midi)
    aiff = download(midi)

    wav_48k = tmp / f"{key}_48k.wav"
    afconvert(["-f", "WAVE", "-d", f"LEI16@{SAMPLE_RATE}", str(aiff), str(wav_48k)])

    mono = read_wav_mono(wav_48k)
    processed = process(mono)

    mono_wav = tmp / f"{key}_mono.wav"
    write_wav_mono(mono_wav, processed)

    caf = SAMPLES_DIR / f"{key}_pno.caf"
    afconvert(["-f", "caff", "-d", "LEI16", str(mono_wav), str(caf)])
    seconds = len(processed) / SAMPLE_RATE
    print(f"  {key}: {seconds:.2f}s -> {caf.name} ({caf.stat().st_size // 1024} KB)")
    return caf


def main() -> int:
    SAMPLES_DIR.mkdir(parents=True, exist_ok=True)
    built = []
    with tempfile.TemporaryDirectory() as tmpdir:
        tmp = pathlib.Path(tmpdir)
        for midi in range(MIN_MIDI, MAX_MIDI + 1):
            print(f"[{sample_key(midi)}] midi {midi}")
            built.append(build_note(midi, tmp))
    print(f"\nBuilt {len(built)} samples in {SAMPLES_DIR}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
