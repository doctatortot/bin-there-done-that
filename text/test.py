from flask import Flask, jsonify
import requests
import logging
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

# Set up logging
logging.basicConfig(level=logging.DEBUG)

app = Flask(__name__)

API_URL = 'http://localhost:5001/api/messages'

def create_session():
    # Create a session with connection pooling
    session = requests.Session()

    # Define retry strategy
    retry_strategy = Retry(
        total=3,  # Total number of retries
        status_forcelist=[429, 500, 502, 503, 504],  # Retry on these status codes
        allowed_methods=["HEAD", "GET", "OPTIONS"],  # Retry only on these methods
        backoff_factor=1  # Backoff factor for sleep between retries
    )

    # Mount the session with HTTPAdapter
    adapter = HTTPAdapter(max_retries=retry_strategy, pool_connections=10, pool_maxsize=10)
    session.mount("http://", adapter)
    session.mount("https://", adapter)

    return session

@app.route('/')
def index():
    session = create_session()
    try:
        response = session.get(API_URL)
        response.raise_for_status()
        messages = response.json()
        logging.debug(f"Fetched messages: {messages}")
        return jsonify(messages)
    except requests.RequestException as e:
        logging.error(f"Error fetching messages: {e}")
        # Reset the session to clear connection issues
        session = create_session()
        return f"Error fetching messages: {e}", 500

if __name__ == '__main__':
    logging.debug("Starting minimal Flask client server")
    app.run(debug=True, host='0.0.0.0', port=5002)

