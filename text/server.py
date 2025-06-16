from flask import Flask, request, jsonify
import psycopg2
from psycopg2 import sql
from flask_cors import CORS
from twilio.twiml.messaging_response import MessagingResponse
import logging
import os

# Set up logging
logging.basicConfig(level=logging.DEBUG)

app = Flask(__name__, static_url_path='', static_folder='static')
CORS(app, resources={r"/*": {"origins": "*"}})

# Database configuration from environment variables
DB_HOST = os.getenv('DB_HOST', '38.102.124.126')
DB_NAME = os.getenv('DB_NAME', 'sms_app')
DB_USER = os.getenv('DB_USER', 'sms_user')
DB_PASS = os.getenv('DB_PASS', 'rusty2281')

def get_db_connection():
    try:
        conn = psycopg2.connect(dbname=DB_NAME, user=DB_USER, password=DB_PASS, host=DB_HOST)
        return conn
    except Exception as e:
        logging.error(f"Database connection failed: {e}")
        raise

@app.route('/sms', methods=['POST'])
def sms_reply():
    try:
        sender = request.form['From']
        body = request.form['Body']
        logging.debug(f"Received SMS from {sender}: {body}")

        conn = get_db_connection()
        with conn.cursor() as cur:
            cur.execute("INSERT INTO messages (sender, body) VALUES (%s, %s)", (sender, body))
            conn.commit()
        conn.close()
        logging.debug("Message saved to database")

        # Respond to the sender
        resp = MessagingResponse()
        resp.message("Message received")
        return str(resp)
    except Exception as e:
        logging.error(f"Error saving message: {e}")
        return str(e), 500

@app.route('/api/messages', methods=['GET'])
def get_messages():
    try:
        logging.debug("Fetching messages from database")
        conn = get_db_connection()
        with conn.cursor() as cur:
            cur.execute("SELECT sender, body, received FROM messages ORDER BY received DESC")
            messages = cur.fetchall()
        conn.close()
        logging.debug(f"Fetched messages: {messages}")
        return jsonify(messages)
    except Exception as e:
        logging.error(f"Error fetching messages: {e}")
        return str(e), 500

@app.route('/')
def index():
    try:
        logging.debug("Serving index.html")
        return app.send_static_file('index.html')
    except Exception as e:
        logging.error(f"Error serving index.html: {e}")
        return str(e), 500

if __name__ == '__main__':
    logging.debug("Starting Flask server")
    app.run(debug=True, host='0.0.0.0', port=5001)
