#!/usr/bin/env bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -x "$DIR/.venv/bin/gdparse" ]; then
    exec "$DIR/.venv/bin/gdparse" "$@"
elif command -v gdparse &> /dev/null; then
    exec gdparse "$@"
else
    echo "[ERROR] gdparse not found in $DIR/.venv/bin or system PATH" >&2
    exit 1
fi
