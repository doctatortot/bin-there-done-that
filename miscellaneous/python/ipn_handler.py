from flask import Flask, request
import requests
import os
from datetime import datetime

app = Flask(__name__)
LOGFILE = "/home/doc/alerts/ipn.log"

TELEGRAM_BOT_TOKEN = "8178867489:AAH0VjN7VnZSCIWasSz_y97iBLLjPJA751k"
TELEGRAM_CHAT_ID = "1559582356"

def send_telegram_alert(message):
    url = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/sendMessage"
    data = {"chat_id": TELEGRAM_CHAT_ID, "text": message}
    try:
        requests.post(url, data=data)
    except Exception as e:
        print(f"Telegram error: {e}")

@app.route("/ipn", methods=["POST"])
def handle_ipn():
    ipn_data = request.form.to_dict()
    now = datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S UTC")

    payer_email = ipn_data.get("payer_email", "unknown")
    item_name = ipn_data.get("item_name", "unspecified")
    payment_status = ipn_data.get("payment_status", "unknown")
    amount = ipn_data.get("mc_gross", "n/a")
    txn_id = ipn_data.get("txn_id", "n/a")

    summary = f"""
PayPal IPN Alert
Item: {item_name}
Email: {payer_email}
Amount: ${amount}
Status: {payment_status}
Txn ID: {txn_id}
Time: {now}
""".strip()

    with open(LOGFILE, "a") as log:
        log.write(summary + "\n")

    if payment_status.lower() == "completed":
        send_telegram_alert(summary)

    return "OK", 200

if __name__ == "__main__":
    os.makedirs(os.path.dirname(LOGFILE), exist_ok=True)
    app.run(host="0.0.0.0", port=8090)
