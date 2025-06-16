# fz_ip_validator.py
from flask import Flask, request, jsonify
from datetime import datetime
import logging

app = Flask(__name__)

# Configure logging
logging.basicConfig(filename='/home/doc/ip_validator.log', level=logging.INFO)

# Sample in-memory abuse list (replace with file/db lookup in production)
abuse_list = set([
    '1.2.3.4',  # example flagged IP
    '5.6.7.8'
])

@app.route('/validate', methods=['GET'])
def validate():
    ip = request.args.get('ip', request.remote_addr)
    now = datetime.utcnow().isoformat()

    # Log the IP
    logging.info(f"{now} - IP validation request from {ip}")

    # Check if IP is in abuse list
    is_abusive = ip in abuse_list

    return jsonify({
        "ip": ip,
        "valid": not is_abusive,
        "reason": "Flagged for abuse" if is_abusive else "OK"
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5024)
