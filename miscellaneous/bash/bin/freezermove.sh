#!/bin/bash

SRC_ROOT="/home/doc"
TARGET_DIR="/home/doc/genesis-tools/venvrequirements"
DRY_RUN=0

if [[ "$1" == "--dry-run" ]]; then
    DRY_RUN=1
    echo "Dry run mode enabled: No files will be created or copied."
fi

echo "Scanning for venvs in $SRC_ROOT ..."

found_any=0
for dir in "$SRC_ROOT"/*/; do
    venv_name=$(basename "$dir")
    req_file="${dir}requirements.txt"
    dest_file="$TARGET_DIR/requirements_${venv_name}.txt"

    # Only proceed if it's a directory and requirements.txt exists
    if [[ -d "$dir" && -f "$req_file" ]]; then
        found_any=1
        echo "Found: $req_file"
        echo "→ Would copy to: $dest_file"

        if [[ -f "$dest_file" ]]; then
            echo "  [SKIP] $dest_file already exists. Skipping."
        else
            if [[ "$DRY_RUN" -eq 1 ]]; then
                echo "  [DRY RUN] Would copy $req_file → $dest_file"
            else
                cp "$req_file" "$dest_file"
                echo "  [OK] Copied $req_file → $dest_file"
            fi
        fi
        echo ""
    fi
done

if [[ "$found_any" -eq 0 ]]; then
    echo "No requirements.txt files found in $SRC_ROOT!"
fi

if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "All requirements processed. (Dry run mode)"
else
    echo "All requirements copied and organized."
fi
