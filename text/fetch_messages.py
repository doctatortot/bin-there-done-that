from flask import Flask, request, jsonify
import psycopg2
import logging
from dotenv import load_dotenv
import os

# Load environment variables from .env file
load_dotenv()

# Set up logging
logging.basicConfig(level=logging.DEBUG)

app = Flask(__name__)

# Database configuration
DB_HOST = os.getenv('DB_HOST')
DB_NAME = os.getenv('DB_NAME')
DB_USER = os.getenv('DB_USER')
DB_PASSWORD = os.getenv('DB_PASSWORD')

# Log environment variables
logging.debug(f"DB_HOST: {DB_HOST}, DB_NAME: {DB_NAME}, DB_USER: {DB_USER}")

# Connect to the database
def get_db_connection():
    try:
        conn = psycopg2.connect(dbname=DB_NAME, user=DB_USER, password=DB_PASSWORD, host=DB_HOST)
        logging.debug("Database connection established")
        return conn
    except psycopg2.Error as e:
        logging.error(f"Error connecting to the database: {e}")
        return None

@app.route('/api/messages', methods=['GET'])
def get_messages():
    logging.debug("Handling /api/messages request")
    conn = get_db_connection()
    if not conn:
        return jsonify({"error": "Failed to connect to the database"}), 500

    try:
        cur = conn.cursor()
        cur.execute("SELECT sender, message FROM messages ORDER BY id DESC")
        messages = cur.fetchall()
        cur.close()

        # Log the fetched rows with types and values
        for msg in messages:
            logging.debug(f"Fetched message: {msg}, types: {[type(field) for field in msg]}")

        # Ensure conversion to JSON-safe format
        messages_list = [{"sender": msg[0], "message": msg[1]} for msg in messages]
        logging.debug(f"Processed messages: {messages_list}")
        return jsonify(messages_list)
    except Exception as e:
        logging.error(f"Error fetching messages: {e}")
        return jsonify({"error": "Failed to fetch messages"}), 500
    finally:
        conn.close()

if __name__ == '__main__':
    logging.debug("Starting Flask API server")
    app.run(debug=True, host='0.0.0.0', port=5000)
