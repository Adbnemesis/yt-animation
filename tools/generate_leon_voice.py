#!/usr/bin/env python3
"""
Generate Original Leon Character Voice Lines
Synthesizes 9 short performance lines for Leon using Kokoro TTS (am_puck profile)
with pitch tailored to an energetic 10-12 year-old kid ninja.
"""

import os
import subprocess
import numpy as np
import soundfile as sf
from kokoro import KPipeline

OUT_DIR = "assets/audio/voices/leon"
os.makedirs(OUT_DIR, exist_ok=True)

VOICE_LINES = {
    "leon_vo_what": ("...What?", 1.0),
    "leon_vo_hey": ("Hey!", 1.15),
    "leon_vo_get_back_here": ("Get back here!", 1.1),
    "leon_vo_weird": ("Okay... that's weird.", 1.05),
    "leon_vo_seriously": ("Seriously?", 1.08),
    "leon_vo_copying_me": ("You're copying me...", 0.98),
    "leon_vo_alright": ("Alright.", 1.02),
    "leon_vo_got_you": ("Got you!", 1.12),
    "leon_vo_come_on": ("Oh, come on...", 0.95),
}

def generate_voices():
    print(f"[VOICE GEN] Initializing Kokoro TTS pipeline with 'am_puck' profile...")
    pipeline = KPipeline(lang_code='a')

    for vo_id, (text, speed) in VOICE_LINES.items():
        raw_path = f"/tmp/{vo_id}_raw.wav"
        final_wav = os.path.join(OUT_DIR, f"{vo_id}.wav")

        print(f"[VOICE GEN] Synthesizing '{vo_id}': \"{text}\" (speed={speed})...")
        generator = pipeline(text, voice='am_puck', speed=speed)
        audio_chunks = []
        for _, _, audio in generator:
            audio_chunks.append(audio)

        if not audio_chunks:
            print(f"[ERROR] No audio generated for {vo_id}")
            continue

        full_audio = np.concatenate(audio_chunks)
        sf.write(raw_path, full_audio, 24000)

        # Pitch shift slightly up (+12% sample rate resample) to give Leon his authentic youthful boy ninja register
        cmd = [
            "ffmpeg", "-y", "-loglevel", "warning",
            "-i", raw_path,
            "-af", "asetrate=24000*1.12,aresample=24000",
            final_wav
        ]
        subprocess.run(cmd, check=True)

        # Check duration
        info = subprocess.run(
            ["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "default=noprint_wrappers=1:nokey=1", final_wav],
            capture_output=True, text=True, check=True
        )
        dur = float(info.stdout.strip())
        print(f"  -> Generated: {final_wav} ({dur:.2f}s)")

    print("[VOICE GEN] All Leon performance lines synthesized successfully!")

if __name__ == "__main__":
    generate_voices()
