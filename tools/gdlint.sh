#!/usr/bin/env bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -x "$DIR/.venv/bin/gdlint" ]; then
    exec "$DIR/.venv/bin/gdlint" "$@"
elif command -v gdlint &> /dev/null; then
    exec gdlint "$@"
else
    echo "[ERROR] gdlint not found in $DIR/.venv/bin or system PATH" >&2
    exit 1
fi
