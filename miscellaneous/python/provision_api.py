from flask import Flask, request, jsonify
from flask_cors import CORS
import subprocess

app = Flask(__name__)
CORS(app)  # Enables cross-origin requests

# Package mappings
PACKAGE_COMMANDS = {
    "safe": "safe",
    "ultra": "ultra",
    "micro": "micro",
    "mastodon": "mastodon",
}

@app.route('/ping')
def ping():
    return "pong"

@app.route('/api/create_vm', methods=['POST'])
def create_vm():
    data = request.json or {}
    label = data.get("label", "").strip()
    package = data.get("package", "").strip()

    print(f"[DEBUG] Incoming create_vm request: label={label}, package={package}")

    if not label or package not in PACKAGE_COMMANDS:
        return jsonify({"status": "error", "stderr": "Invalid label or package"}), 400

    cmd = ["./genesisctl.sh", PACKAGE_COMMANDS[package], label]

    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, timeout=600, cwd="/home/doc/failzero")
        print(f"[DEBUG] Subprocess stdout:\n{proc.stdout}")
        print(f"[DEBUG] Subprocess stderr:\n{proc.stderr}")

        if proc.returncode == 0:
            return jsonify({"status": "success", "stdout": proc.stdout})
        else:
            return jsonify({"status": "error", "stdout": proc.stdout, "stderr": proc.stderr}), 500
    except Exception as e:
        print(f"[ERROR] Exception: {e}")
        return jsonify({"status": "error", "stderr": str(e)}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5030)
