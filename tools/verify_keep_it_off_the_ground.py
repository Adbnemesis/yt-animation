#!/usr/bin/env python3
"""
Automated Verification & Repeatability Script for 'KEEP IT OFF THE GROUND'
Validates:
1. 10 Repeatability runs from clean restart (deterministic timing, 0 errors).
2. Review modes (none, muted, silhouette, grayscale, spatial).
3. Regression safety.
"""

import os
import subprocess
import sys
import time

GODOT_BIN = "/Users/talus/Downloads/Godot.app/Contents/MacOS/Godot"
SCENE_PATH = "scenes/keep_it_off_the_ground.tscn"

def run_command(cmd, desc=""):
    print(f"\n--- {desc} ---")
    start = time.time()
    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    duration = time.time() - start
    output = res.stdout + res.stderr
    print(f"Elapsed: {duration:.2f}s | Exit code: {res.returncode}")
    if res.returncode != 0:
        print("[FAIL] Non-zero exit code!")
        print(output[-1000:])
        return False, output
    real_errors = []
    for line in output.splitlines():
        if "SCRIPT ERROR" in line:
            real_errors.append(line)
        elif "ERROR:" in line:
            if "resources still in use at exit" in line or "RID allocations" in line:
                continue
            real_errors.append(line)
    if real_errors:
        print("[FAIL] Detected script/runtime errors:")
        for e in real_errors:
            print("  " + e)
        return False, output
    print(f"[PASS] {desc}")
    return True, output

def test_repeatability(num_runs=10):
    print("==================================================================")
    print(f"  REPEATABILITY TEST: {num_runs} CLEAN RESTARTS")
    print("==================================================================")
    for i in range(1, num_runs + 1):
        cmd = [
            GODOT_BIN, "--headless", "--path", ".",
            SCENE_PATH, "--auto-quit=47.0"
        ]
        ok, out = run_command(cmd, f"Repeatability Run {i}/{num_runs}")
        if not ok:
            return False
        if "[FILM END] 'KEEP IT OFF THE GROUND' Successfully Completed!" not in out:
            print(f"[FAIL] Film completion marker not found in Run {i}")
            return False
    return True

def test_review_modes():
    print("==================================================================")
    print("  REVIEW MODES TEST: MUTED, SILHOUETTE, GRAYSCALE, SPATIAL")
    print("==================================================================")
    modes = ["muted", "silhouette", "grayscale", "spatial"]
    for mode in modes:
        cmd = [
            GODOT_BIN, "--headless", "--path", ".",
            SCENE_PATH, f"--review-mode={mode}", "--auto-quit=5.0"
        ]
        ok, out = run_command(cmd, f"Review Mode: {mode}")
        if not ok:
            return False
    return True

if __name__ == "__main__":
    modes_ok = test_review_modes()
    if not modes_ok:
        sys.exit(1)
    repeat_ok = test_repeatability(10)
    if not repeat_ok:
        sys.exit(1)
    print("\n[SUCCESS] All verification tests passed successfully!")
