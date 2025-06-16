#!/bin/bash
# Find all venvs, freeze their packages to requirements.txt

BASE_DIR="$HOME"  # Or wherever your projects are

echo "Scanning for venvs under $BASE_DIR ..."

find "$BASE_DIR" -type f -name "pyvenv.cfg" 2>/dev/null | while read cfg; do
    venv_dir="$(dirname "$cfg")"
    reqfile="$venv_dir/requirements.txt"
    echo "🔒 Freezing $venv_dir → $reqfile"
    "$venv_dir/bin/python" -m pip freeze > "$reqfile"
    if [ $? -eq 0 ]; then
        echo "✅ Done: $reqfile"
    else
        echo "❌ Failed to freeze $venv_dir"
    fi
done

echo "All venvs processed!"
