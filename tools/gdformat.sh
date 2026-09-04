#!/usr/bin/env bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -x "$DIR/.venv/bin/gdformat" ]; then
    exec "$DIR/.venv/bin/gdformat" "$@"
elif command -v gdformat &> /dev/null; then
    exec gdformat "$@"
else
    echo "[ERROR] gdformat not found in $DIR/.venv/bin or system PATH" >&2
    exit 1
fi
