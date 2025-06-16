#!/bin/bash
# push_and_build.sh — Build Python app on Shredder w/o installing or bundling .env

read -p "Enter the name of the app (folder name, e.g., radiotoot): " APP_NAME
read -p "Enter the main script filename (e.g., app.py): " MAIN_SCRIPT

REMOTE_HOST="shredder.sshjunkie.com"
REMOTE_BASE="/assets/clientapps"
LOCAL_PATH="/home/doc/$APP_NAME"
REMOTE_PATH="$REMOTE_BASE/$APP_NAME"

# Double-check local folder
if [ ! -d "$LOCAL_PATH" ]; then
  echo "[-] Local app path $LOCAL_PATH does not exist."
  exit 1
fi

echo "[*] Syncing $APP_NAME to $REMOTE_HOST (excluding .env and venv)..."
rsync -av --exclude 'venv' --exclude 'dist' --exclude '__pycache__' \
  --exclude '*.spec' --exclude '.env' \
  "$LOCAL_PATH/" "doc@$REMOTE_HOST:$REMOTE_PATH/"

echo "[*] Triggering remote build on $REMOTE_HOST..."
ssh doc@$REMOTE_HOST bash -c "'
  set -e
  cd $REMOTE_PATH
  echo \"[*] Rebuilding venv...\"
  python3 -m venv venv
  source venv/bin/activate
  pip install -r requirements.txt
  pip install pyinstaller
  echo \"[*] Building binary...\"
  pyinstaller --onefile --name=$APP_NAME \
    --add-data \"templates:templates\" \
    --add-data \"migrations:migrations\" \
    $MAIN_SCRIPT
  echo \"[+] Build complete. Binary available in: $REMOTE_PATH/dist/$APP_NAME\"
'"

echo "[✓] Done. You can test the binary at Shredder:$REMOTE_PATH/dist/$APP_NAME"
