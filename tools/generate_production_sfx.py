#!/usr/bin/env python3
"""
Procedural Sound Effect Generator for 'Leon and the Runaway Star'
Generates 16-bit 44.1kHz mono WAV files for:
- Footsteps on grass (walk & run variations)
- Runaway Star sound effects (whoosh, hover, dart, pulse, jump, boop, burst)
- Subtle outdoor meadow breeze ambience
Zero external dependencies (uses standard math, wave, struct, random).
"""

import os
import math
import struct
import random

SAMPLE_RATE = 44100

def write_wav(filepath: str, samples: list[float]):
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    with wave.open(filepath, "w") as wav_file:
        wav_file.setnchannels(1)        # mono
        wav_file.setsampwidth(2)        # 16-bit
        wav_file.setframerate(SAMPLE_RATE)
        
        raw_bytes = bytearray()
        for s in samples:
            # clamp to [-1.0, 1.0]
            val = max(-1.0, min(1.0, s))
            int_val = int(val * 32767.0)
            raw_bytes.extend(struct.pack("<h", int_val))
            
        wav_file.writeframes(raw_bytes)
    print(f"Generated: {filepath} ({len(samples)} samples, {len(samples)/SAMPLE_RATE:.3f}s)")

import wave

def generate_grass_footstep(is_run: bool, seed: int = 1) -> list[float]:
    random.seed(seed)
    duration = 0.08 if is_run else 0.09
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    
    # Grass contact: high-frequency filtered noise rustle + low-mid muffled thump
    low_freq = 110.0 if is_run else 90.0
    
    # Simple lowpass / bandpass state
    lp_noise = 0.0
    alpha = 0.25 if is_run else 0.18
    
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-t * (42.0 if is_run else 48.0))
        
        # White noise component for grass blade rustle
        noise = (random.random() * 2.0 - 1.0)
        lp_noise = lp_noise + alpha * (noise - lp_noise)
        
        # Low body contact thump
        body = math.sin(2.0 * math.pi * low_freq * (1.0 - t * 5.0) * t) * math.exp(-t * 55.0)
        
        # Combine
        s = (lp_noise * 0.65 + body * 0.55) * env
        if is_run:
            s *= 1.2
        samples.append(s)
        
    return samples

def generate_star_whoosh() -> list[float]:
    duration = 1.4
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        # Envelope: rise then decay
        if t < 0.4:
            env = (t / 0.4) ** 2
        else:
            env = math.exp(-(t - 0.4) * 3.2)
            
        # Descending whoosh frequency
        freq = 1400.0 - 900.0 * (t / duration)
        sine1 = math.sin(2.0 * math.pi * freq * t)
        sine2 = math.sin(2.0 * math.pi * (freq * 1.5) * t) * 0.3
        sine3 = math.sin(2.0 * math.pi * (freq * 0.5) * t) * 0.2
        
        # Soft noise shimmer
        noise = (random.random() * 2.0 - 1.0) * 0.15
        
        s = (sine1 + sine2 + sine3 + noise) * env * 0.65
        samples.append(s)
        
    return samples

def generate_star_hover() -> list[float]:
    duration = 1.2
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        # Seamless loop envelope
        fade = math.sin(math.pi * t / duration)
        
        # Pulsing dual crystalline sines (warm fairy chime)
        wobble = math.sin(2.0 * math.pi * 5.5 * t) * 15.0
        f1 = 880.0 + wobble
        f2 = 1320.0 + wobble * 1.5
        f3 = 1760.0
        
        s1 = math.sin(2.0 * math.pi * f1 * t) * 0.4
        s2 = math.sin(2.0 * math.pi * f2 * t) * 0.25
        s3 = math.sin(2.0 * math.pi * f3 * t) * 0.15
        
        samples.append((s1 + s2 + s3) * fade * 0.45)
        
    return samples

def generate_star_dart() -> list[float]:
    duration = 0.16
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = math.sin(math.pi * (t / duration)) ** 1.5
        
        # Fast upward zip frequency chirp
        freq = 600.0 + 2200.0 * (t / duration) ** 2
        s = math.sin(2.0 * math.pi * freq * t) * env * 0.75
        samples.append(s)
        
    return samples

def generate_star_pulse() -> list[float]:
    duration = 0.45
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 8.5)
        
        # Bell harmonic combination (fundamental 1046 Hz - C6, plus harmonics)
        f1 = 1046.5
        f2 = 2093.0
        f3 = 3139.5
        
        s1 = math.sin(2.0 * math.pi * f1 * t)
        s2 = math.sin(2.0 * math.pi * f2 * t) * 0.4
        s3 = math.sin(2.0 * math.pi * f3 * t) * 0.15
        
        samples.append((s1 + s2 + s3) * env * 0.6)
        
    return samples

def generate_star_jump() -> list[float]:
    duration = 0.22
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = math.sin(math.pi * (t / duration))
        
        # Upward bouncy chirp
        freq = 450.0 + 950.0 * (t / duration)
        s = math.sin(2.0 * math.pi * freq * t) * env * 0.7
        samples.append(s)
        
    return samples

def generate_star_boop() -> list[float]:
    duration = 0.14
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 32.0)
        
        # Cute soft boop: 750 Hz dropping slightly
        freq = 780.0 - 200.0 * (t / duration)
        s = math.sin(2.0 * math.pi * freq * t) * env * 0.8
        samples.append(s)
        
    return samples

def generate_star_burst() -> list[float]:
    duration = 1.1
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    
    # Sparkle chime chord (C major 7th: C6, E6, G6, B6)
    freqs = [1046.5, 1318.5, 1568.0, 1975.5, 2637.0]
    
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 3.8)
        
        chord = 0.0
        for idx, f in enumerate(freqs):
            # slight detuning and twinkle modulation
            twinkle = 1.0 + 0.08 * math.sin(2.0 * math.pi * (12.0 + idx * 3.0) * t)
            chord += math.sin(2.0 * math.pi * f * twinkle * t) * (1.0 / (idx + 1))
            
        noise = (random.random() * 2.0 - 1.0) * math.exp(-t * 22.0) * 0.25
        s = (chord * 0.35 + noise) * env
        samples.append(s)
        
    return samples

def generate_meadow_breeze() -> list[float]:
    duration = 4.0
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    
    # Pinkish low noise for outdoor field breeze
    b0 = b1 = b2 = b3 = b4 = b5 = b6 = 0.0
    
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        # Loop fade at ends
        fade = math.sin(math.pi * t / duration)
        
        white = random.random() * 2.0 - 1.0
        b0 = 0.99886 * b0 + white * 0.0555179
        b1 = 0.99332 * b1 + white * 0.0750759
        b2 = 0.96900 * b2 + white * 0.1538520
        b3 = 0.86650 * b3 + white * 0.3104856
        b4 = 0.55000 * b4 + white * 0.5329522
        b5 = -0.7616 * b5 - white * 0.0168980
        pink = b0 + b1 + b2 + b3 + b4 + b5 + b6 + white * 0.5362
        b6 = white * 0.115926
        
        # Soft swell
        swell = 0.5 + 0.5 * math.sin(2.0 * math.pi * 0.25 * t)
        s = (pink * 0.04) * swell * fade
        samples.append(s)
        
    return samples

def main():
    base_dir = "assets/audio/sfx"
    
    # 1. Footsteps
    write_wav(f"{base_dir}/footsteps/footstep_walk_01.wav", generate_grass_footstep(False, 101))
    write_wav(f"{base_dir}/footsteps/footstep_walk_02.wav", generate_grass_footstep(False, 202))
    write_wav(f"{base_dir}/footsteps/footstep_run_01.wav", generate_grass_footstep(True, 303))
    write_wav(f"{base_dir}/footsteps/footstep_run_02.wav", generate_grass_footstep(True, 404))
    
    # 2. Star SFX
    write_wav(f"{base_dir}/star/star_whoosh.wav", generate_star_whoosh())
    write_wav(f"{base_dir}/star/star_hover.wav", generate_star_hover())
    write_wav(f"{base_dir}/star/star_dart.wav", generate_star_dart())
    write_wav(f"{base_dir}/star/star_pulse.wav", generate_star_pulse())
    write_wav(f"{base_dir}/star/star_jump.wav", generate_star_jump())
    write_wav(f"{base_dir}/star/star_boop.wav", generate_star_boop())
    write_wav(f"{base_dir}/star/star_burst.wav", generate_star_burst())
    
    # 3. Environment Ambience
    write_wav(f"{base_dir}/env/meadow_breeze.wav", generate_meadow_breeze())
    
    print("All production SFX generated successfully!")

if __name__ == "__main__":
    main()
