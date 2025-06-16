#!/bin/bash

# Define the paths to the virtual environments and the Python scripts
VENV_ACTIVATION_PATHS=(
    "text/bin/activate"
    "text/bin/activate"
    "text/bin/activate"
)

PYTHON_SCRIPTS=(
    "/root/projects/text/server.py"
    "/root/projects/text/sms_client/client_app.py"
    "/root/projects/text/app.py"
)

# Define names for screen sessions
SCREEN_NAMES=(
    "server_session"
    "sms_client_session"
    "app_session"
)

# Function to activate a virtual environment and run a Python script in a screen session
run_script_in_screen() {
    ACTIVATE_PATH=$1
    SCRIPT_PATH=$2
    SCREEN_NAME=$3
    echo "Starting screen session: $SCREEN_NAME"
    screen -dmS "$SCREEN_NAME" bash -c "
        echo 'Activating virtual environment: $ACTIVATE_PATH';
        source $ACTIVATE_PATH;
        echo 'Running script: $SCRIPT_PATH';
        python $SCRIPT_PATH;
        exec bash"
    if [ $? -eq 0 ]; then
        echo "Screen session $SCREEN_NAME started successfully."
    else
        echo "Failed to start screen session $SCREEN_NAME."
    fi
}

# Iterate over the virtual environments and scripts, running each script in a screen session
for i in "${!VENV_ACTIVATION_PATHS[@]}"; do
    ACTIVATE_PATH="${VENV_ACTIVATION_PATHS[$i]}"
    SCRIPT_PATH="${PYTHON_SCRIPTS[$i]}"
    SCREEN_NAME="${SCREEN_NAMES[$i]}"
    run_script_in_screen "$ACTIVATE_PATH" "$SCRIPT_PATH" "$SCREEN_NAME"
done

echo "All scripts have been executed in separate screen sessions."

