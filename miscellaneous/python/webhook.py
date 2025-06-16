from flask import Flask, request, jsonify
from datetime import datetime
import subprocess
import os

app = Flask(__name__)
LOG_DIR = "/home/doc/vpslogs"
os.makedirs(LOG_DIR, exist_ok=True)

@app.route("/genesislog", methods=["POST"])
def genesis_log():
    data = request.get_json()
    if not data or "host" not in data or "ip" not in data:
        return jsonify({"error": "Invalid data"}), 400

    host = data["host"]
    ip = data["ip"]
    timestamp = data.get("timestamp", datetime.utcnow().isoformat())
    logfile = os.path.join(LOG_DIR, f"{host}.log")

    with open(logfile, "a") as f:
        f.write(f"{timestamp} - {host} ({ip}) deployed and hardened.\n")

    return jsonify({"status": "logged"}), 200

@app.route("/provision", methods=["GET"])
def provision_vps():
    custom = request.args.get("custom")
    if not custom or "|" not in custom:
        return jsonify({"error": "Missing or invalid custom param"}), 400

    type_, label = custom.split("|", 1)

    try:
        subprocess.Popen(["/usr/local/bin/genesisctl", type_, label])
        return jsonify({"status": f"Provisioning started for {type_} {label}"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
