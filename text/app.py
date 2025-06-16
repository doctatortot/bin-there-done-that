from flask import Flask, render_template, redirect, url_for, request, flash, jsonify
from flask_login import LoginManager, login_user, logout_user, login_required, current_user, UserMixin
import psycopg2
import logging
from dotenv import load_dotenv
import os
from werkzeug.security import generate_password_hash, check_password_hash
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address

# Load environment variables from .env file
load_dotenv()

# Set up logging
logging.basicConfig(level=logging.DEBUG)

app = Flask(__name__)
app.secret_key = os.getenv('SECRET_KEY') or 'supersecretkey'

# Flask-Login configuration
login_manager = LoginManager()
login_manager.init_app(app)
login_manager.login_view = "login"

# Rate Limiting configuration
limiter = Limiter(get_remote_address, app=app)

# Database configuration
DB_HOST = os.getenv('DB_HOST')
DB_NAME = os.getenv('DB_NAME')
DB_USER = os.getenv('DB_USER')
DB_PASSWORD = os.getenv('DB_PASSWORD')
TWILIO_PHONE_NUMBER = os.getenv('TWILIO_PHONE_NUMBER')

# Log environment variables
logging.debug(f"DB_HOST: {DB_HOST}, DB_NAME: {DB_NAME}, DB_USER: {DB_USER}, TWILIO_PHONE_NUMBER: {TWILIO_PHONE_NUMBER}")

class User(UserMixin):
    def __init__(self, id, username, password):
        self.id = id
        self.username = username
        self.password_hash = password

    @staticmethod
    def get_by_username(username):
        conn = get_db_connection()
        if not conn:
            return None
        try:
            cur = conn.cursor()
            cur.execute("SELECT id, username, password FROM users WHERE username = %s", (username,))
            user = cur.fetchone()
            cur.close()
            return User(user[0], user[1], user[2]) if user else None
        except Exception as e:
            logging.error(f"Error in get_by_username: {e}")
            return None
        finally:
            conn.close()

    @staticmethod
    def get_by_id(user_id):
        conn = get_db_connection()
        if not conn:
            return None
        try:
            cur = conn.cursor()
            cur.execute("SELECT id, username, password FROM users WHERE id = %s", (user_id,))
            user = cur.fetchone()
            cur.close()
            return User(user[0], user[1], user[2]) if user else None
        except Exception as e:
            logging.error(f"Error in get_by_id: {e}")
            return None
        finally:
            conn.close()

    @staticmethod
    def create(username, password):
        password_hash = generate_password_hash(password)
        logging.debug(f"Creating user: {username}")
        conn = get_db_connection()
        if not conn:
            return None
        try:
            cur = conn.cursor()
            cur.execute("INSERT INTO users (username, password) VALUES (%s, %s) RETURNING id", (username, password_hash))
            user_id = cur.fetchone()[0]
            conn.commit()
            cur.close()
            return User(user_id, username, password_hash)
        except Exception as e:
            logging.error(f"Error creating user: {e}")
            return None
        finally:
            conn.close()

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

@login_manager.user_loader
def load_user(user_id):
    return User.get_by_id(user_id)

# Connect to the database
def get_db_connection():
    try:
        conn = psycopg2.connect(dbname=DB_NAME, user=DB_USER, password=DB_PASSWORD, host=DB_HOST)
        logging.debug("Database connection established")
        return conn
    except psycopg2.Error as e:
        logging.error(f"Error connecting to the database: {e}")
        return None

@app.errorhandler(404)
def page_not_found(e):
    return render_template('404.html'), 404

@app.errorhandler(500)
def internal_server_error(e):
    logging.error(f"Server error: {e}")
    return "Internal server error occurred", 500

@app.route('/api/messages', methods=['GET'])
def get_messages():
    conn = get_db_connection()
    if not conn:
        return jsonify({"error": "Failed to connect to the database"}), 500
    try:
        cur = conn.cursor()
        cur.execute("SELECT sender, recipient, message FROM messages ORDER BY id DESC")
        messages = cur.fetchall()
        cur.close()
        messages_list = [{"sender": msg[0].strip() if msg[0] else None, "recipient": msg[1], "message": msg[2]} for msg in messages]
        return jsonify(messages_list)
    except Exception as e:
        logging.error(f"Error fetching messages: {e}")
        return jsonify({"error": "Failed to fetch messages"}), 500
    finally:
        conn.close()

@app.route('/sms', methods=['POST'])
def handle_sms():
    data = request.form
    sender = data.get('From').strip()
    body = data.get('Body')
    recipient = TWILIO_PHONE_NUMBER

    conn = get_db_connection()
    if not conn:
        return "Failed to connect to the database", 500

    try:
        cur = conn.cursor()
        cur.execute(
            "INSERT INTO messages (sender, recipient, message) VALUES (%s, %s, %s)",
            [sender, recipient, body]
        )
        conn.commit()
        cur.close()
        return "SMS received", 200
    except psycopg2.Error as e:
        logging.error(f"Error inserting message: {e}")
        return "Failed to save SMS", 500
    finally:
        conn.close()

@app.route('/messages', methods=['GET'])
@login_required
def messages_page():
    search_query = request.args.get('search', '')
    conn = get_db_connection()
    if not conn:
        return "Failed to connect to the database", 500

    try:
        cur = conn.cursor()
        if search_query:
            cur.execute(
                "SELECT sender, recipient, message FROM messages WHERE sender ILIKE %s OR recipient ILIKE %s OR message ILIKE %s ORDER BY id DESC",
                (f'%{search_query}%', f'%{search_query}%', f'%{search_query}%')
            )
        else:
            cur.execute("SELECT sender, recipient, message FROM messages ORDER BY id DESC")
        messages = cur.fetchall()
        cur.close()
        messages_list = [{"sender": msg[0].strip() if msg[0] else None, "recipient": msg[1], "message": msg[2]} for msg in messages]
        return render_template('messages.html', messages=messages_list)
    except Exception as e:
        logging.error(f"Error fetching messages for rendering: {e}")
        return "Failed to fetch messages", 500
    finally:
        conn.close()

@app.route('/login', methods=['GET', 'POST'])
@limiter.limit("5 per minute")
def login():
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        user = User.get_by_username(username)
        if user and user.check_password(password):
            login_user(user)
            flash('Logged in successfully.')
            return redirect(url_for('messages_page'))
        else:
            flash('Invalid username or password.')
    return render_template('login.html')

@app.route('/register', methods=['GET', 'POST'])
def register():
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        if User.get_by_username(username):
            flash('Username already exists.')
        else:
            user = User.create(username, password)
            if user:
                flash('User created successfully.')
                return redirect(url_for('login'))
            else:
                flash('Error creating user.')
    return render_template('register.html')

@app.route('/logout')
@login_required
def logout():
    logout_user()
    flash('Logged out successfully.')
    return redirect(url_for('login'))

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
