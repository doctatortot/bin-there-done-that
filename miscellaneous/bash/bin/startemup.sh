#!/usr/bin/env bash
# Launches Python virtual environments in separate screen sessions or manages their status

declare -A VENV_APPS=(
  [archivecontrol]="recordit2.py"
  [archivelist]="recordit2.py"
  [recordtheshow]="app.py"
  [radiotoot]="app.py"
  [hostingtoot]="app.py"
  [radiotoot]="live.py"
)

SCRIPT_BASE="/home/doc/genesis-tools"
VENV_BASE="/home/doc"

if [[ "$1" == "--check" ]]; then
  echo "🔍 Checking screen session health..."
  for name in "${!VENV_APPS[@]}"; do
    if screen -list | grep -q "\.${name}[[:space:]]"; then
      echo "📦 $name	✅ Running"
    else
      echo "📦 $name	❌ Not running"
    fi
  done
  exit 0
fi

if [[ "$1" == "--stop" ]]; then
  echo "🛑 Stopping all screen sessions..."
  for name in "${!VENV_APPS[@]}"; do
    if screen -list | grep -q "\.${name}[[:space:]]"; then
      screen -S "$name" -X quit && echo "🛑 $name stopped"
    else
      echo "⚠️  $name not running"
    fi
  done
  exit 0
fi

if [[ "$1" == "--restart" ]]; then
  echo "🔄 Restarting all apps..."
  "$0" --stop
  sleep 2
  "$0"
  exit 0
fi

for name in "${!VENV_APPS[@]}"; do
  script_name="${VENV_APPS[$name]}"
  script_path="$SCRIPT_BASE/$name/$script_name"

  # Use 'toot' venv for both radiotoot and hostingtoot
  if [[ "$name" == "radiotoot" || "$name" == "hostingtoot" ]]; then
    venv_activate="$VENV_BASE/toot/bin/activate"
  else
    venv_activate="$VENV_BASE/$name/bin/activate"
  fi

  if [[ -f "$script_path" && -f "$venv_activate" ]]; then
    echo "🚀 Launching $name in screen session..."
    screen -S "$name" -dm bash -c "source '$venv_activate'; cd '$SCRIPT_BASE/$name'; python3 '$script_name'"
  else
    echo "⚠️  Script or venv not found for $name"
  fi
done

echo "✅ All venv apps launched in screen sessions."
