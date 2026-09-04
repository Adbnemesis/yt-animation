#!/usr/bin/env bash
# ==============================================================================
# Godot Production Movie Maker & FFmpeg YouTube-Ready Video Encoding Script
# ==============================================================================
# Usage:
#   tools/render_video.sh [options]
#
# Options:
#   --scene <path>         Godot scene to render (default: res://scenes/walk_test.tscn)
#   --duration <seconds>   Render duration in seconds (default: 5.0)
#   --fps <number>         Fixed render framerate (default: 60)
#   --output-dir <path>    Directory for rendered videos (default: renders)
#   --output-name <name>   Base name for output video (default derived from scene + timestamp)
#   --godot-bin <path>     Path to Godot executable (default: $GODOT_BIN or auto-detect)
#   --format <avi|png>     Intermediate format (default: avi)
#   --crf <number>         H.264 CRF quality, 0-51 (default: 18)
#   --extra-args <args>    Extra scene arguments passed to Godot
#   --keep-intermediate    Do not delete intermediate render file
#   --help                 Show this help message
# ==============================================================================

set -euo pipefail

# Default Parameters
SCENE="res://scenes/walk_test.tscn"
DURATION="5.0"
FPS="60"
OUTPUT_DIR="renders"
OUTPUT_NAME=""
GODOT_BIN="${GODOT_BIN:-}"
FORMAT="avi"
CRF="18"
EXTRA_ARGS=""
KEEP_INTERMEDIATE=false

# Auto-detect Godot Binary if not set
if [ -z "$GODOT_BIN" ]; then
    if [ -x "/Users/talus/Downloads/Godot.app/Contents/MacOS/Godot" ]; then
        GODOT_BIN="/Users/talus/Downloads/Godot.app/Contents/MacOS/Godot"
    elif command -v godot &> /dev/null; then
        GODOT_BIN="$(command -v godot)"
    else
        echo "[ERROR] Godot binary not found. Please set GODOT_BIN or pass --godot-bin <path>." >&2
        exit 1
    fi
fi

# Parse Command-Line Arguments (supports flags and positional arguments)
POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --scene)
            SCENE="$2"
            shift 2
            ;;
        --duration)
            DURATION="$2"
            shift 2
            ;;
        --fps)
            FPS="$2"
            shift 2
            ;;
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --output-name)
            OUTPUT_NAME="$2"
            shift 2
            ;;
        --godot-bin)
            GODOT_BIN="$2"
            shift 2
            ;;
        --format)
            FORMAT="$2"
            shift 2
            ;;
        --crf)
            CRF="$2"
            shift 2
            ;;
        --extra-args)
            EXTRA_ARGS="$2"
            shift 2
            ;;
        --keep-intermediate)
            KEEP_INTERMEDIATE=true
            shift
            ;;
        --help|-h)
            sed -ne '/^#/!q;s/^# //;p' "$0"
            exit 0
            ;;
        -*)
            echo "[ERROR] Unknown option: $1" >&2
            exit 1
            ;;
        *)
            POSITIONAL_ARGS+=("$1")
            shift
            ;;
    esac
done

# Assign positional arguments if provided
if [ ${#POSITIONAL_ARGS[@]} -ge 1 ]; then
    SCENE="${POSITIONAL_ARGS[0]}"
fi
if [ ${#POSITIONAL_ARGS[@]} -ge 2 ]; then
    DURATION="${POSITIONAL_ARGS[1]}"
fi
if [ ${#POSITIONAL_ARGS[@]} -ge 3 ]; then
    OUTPUT_NAME="${POSITIONAL_ARGS[2]}"
fi


# Ensure FFmpeg is available
if ! command -v ffmpeg &> /dev/null; then
    echo "[ERROR] ffmpeg is not installed or not in PATH." >&2
    exit 1
fi

# Ensure Output Directory exists
mkdir -p "$OUTPUT_DIR"

# Generate Output Filename
if [ -z "$OUTPUT_NAME" ]; then
    SCENE_SLUG=$(basename "$SCENE" .tscn | tr -cd '[:alnum:]_-')
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    OUTPUT_NAME="${SCENE_SLUG}_${TIMESTAMP}"
fi

INTERMEDIATE_FILE="${OUTPUT_DIR}/${OUTPUT_NAME}.${FORMAT}"
FINAL_MP4="${OUTPUT_DIR}/${OUTPUT_NAME}.mp4"

echo "=================================================================="
echo "  GODOT PRODUCTION VIDEO RENDER PIPELINE"
echo "=================================================================="
echo "  Source Scene:      $SCENE"
echo "  Duration:          ${DURATION}s"
echo "  Target Framerate:  ${FPS} FPS"
echo "  Intermediate File: $INTERMEDIATE_FILE"
echo "  Final MP4 Output:  $FINAL_MP4"
echo "  Godot Binary:      $GODOT_BIN"
echo "=================================================================="

# 1. Run Godot Movie Maker Mode
echo -e "\n[STEP 1/2] Capturing frames via Godot Movie Maker Mode..."
START_TIME=$(date +%s)

# Prepare scene arguments
CMD_ARGS=(
    "--write-movie" "$INTERMEDIATE_FILE"
    "--fixed-fps" "$FPS"
    "--path" "."
    "$SCENE"
    "--auto-quit=$DURATION"
)

if [ -n "$EXTRA_ARGS" ]; then
    # shellcheck disable=SC2206
    EXTRA_ARR=($EXTRA_ARGS)
    CMD_ARGS+=("${EXTRA_ARR[@]}")
fi

"$GODOT_BIN" "${CMD_ARGS[@]}"

if [ ! -f "$INTERMEDIATE_FILE" ]; then
    echo "[ERROR] Godot Movie Maker failed to generate intermediate file: $INTERMEDIATE_FILE" >&2
    exit 1
fi

INTERMEDIATE_SIZE=$(du -h "$INTERMEDIATE_FILE" | cut -f1)
echo "  [OK] Intermediate capture completed: $INTERMEDIATE_FILE ($INTERMEDIATE_SIZE)"

# 2. Encode to YouTube-Ready MP4 via FFmpeg
echo -e "\n[STEP 2/2] Encoding YouTube-ready MP4 (H.264/AAC, FastStart) via FFmpeg..."

# FFmpeg encoding optimized for YouTube upload:
# - Video: H.264, yuv420p color format, high profile, CRF 18 (visually lossless)
# - Audio: AAC stereo, 48kHz, 192kbps
# - Container: MP4 with +faststart for instant web streaming
ffmpeg -y -hide_banner -loglevel warning \
    -i "$INTERMEDIATE_FILE" \
    -t "$DURATION" \
    -c:v libx264 -pix_fmt yuv420p -profile:v high -crf "$CRF" -preset fast \
    -c:a aac -b:a 192k -ar 48000 -ac 2 \
    -movflags +faststart \
    "$FINAL_MP4"

if [ ! -f "$FINAL_MP4" ]; then
    echo "[ERROR] FFmpeg encoding failed to produce: $FINAL_MP4" >&2
    exit 1
fi

END_TIME=$(date +%s)
TOTAL_ELAPSED=$((END_TIME - START_TIME))
FINAL_SIZE=$(du -h "$FINAL_MP4" | cut -f1)

# Cleanup intermediate file unless requested to keep
if [ "$KEEP_INTERMEDIATE" = false ]; then
    rm -f "$INTERMEDIATE_FILE"
    echo "  [OK] Removed intermediate file: $INTERMEDIATE_FILE"
fi

# Print Final Summary Report
echo ""
echo "=================================================================="
echo "  RENDER SUCCESSFUL!"
echo "=================================================================="
echo "  Output MP4:        $FINAL_MP4"
echo "  File Size:         $FINAL_SIZE"
echo "  Render Duration:   ${DURATION}s"
echo "  Wall Clock Time:   ${TOTAL_ELAPSED}s"
echo "  Video Specs:       H.264 / 60 FPS / YUV420p / CRF $CRF"
echo "  Audio Specs:       AAC Stereo / 48 kHz / 192 kbps"
echo "  Web Optimization:  +faststart (moov atom at front)"
echo "=================================================================="
