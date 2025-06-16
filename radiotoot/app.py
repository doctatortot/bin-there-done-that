import os
import uuid
import threading
import logging
from flask import Flask, request, render_template, redirect, url_for, flash
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from flask_login import LoginManager, UserMixin, login_user, login_required, logout_user, current_user
from werkzeug.security import generate_password_hash, check_password_hash
from dotenv import load_dotenv
import psycopg2
from mastodon import Mastodon
import schedule as sch
import time as t
from forms import LoginForm, RegistrationForm
from models import db, User, Toot
from sqlalchemy.orm import Session
from flask_wtf import CSRFProtect

# Load env from /etc/radiotoot.env unless overridden
env_path = os.getenv("ENV_PATH", "/etc/radiotoot.env")
load_dotenv(dotenv_path=env_path)

# Environment validation
def validate_env():
    required_vars = {
        "SECRET_KEY": "used to secure session cookies and forms",
        "DATABASE_URL": "PostgreSQL connection string",
        "MASTODON_ACCESS_TOKEN": "Token for posting to Mastodon"
    }
    missing = []
    for var, reason in required_vars.items():
        if not os.getenv(var):
            logging.error(f"Missing required environment variable: {var} — {reason}")
            missing.append(var)
    if missing:
        raise RuntimeError(f"Missing environment variables: {', '.join(missing)}")

validate_env()

# Initialize logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Securely configure the app secret key
app.secret_key = os.getenv("SECRET_KEY")

# Initialize CSRF Protection
csrf = CSRFProtect()
csrf.init_app(app)

# Configure app SERVER_NAME to support url_for outside requests
app.config['SERVER_NAME'] = 'toot.themediahub.org:5010'
app.config['APPLICATION_ROOT'] = '/'
app.config['PREFERRED_URL_SCHEME'] = 'http'

# Database configuration
DATABASE_URL = os.getenv("DATABASE_URL")
logger.debug(f"Using database: {DATABASE_URL}")

def create_db_session():
    app.config['SQLALCHEMY_DATABASE_URI'] = DATABASE_URL
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
    try:
        db.init_app(app)
        conn = psycopg2.connect(DATABASE_URL)
        conn.close()
        return db
    except Exception as error:
        logger.error(f"Database connection failed at {DATABASE_URL}: {error}")
        raise

db = create_db_session()
migrate = Migrate(app, db)

# Flask-Login configuration
login_manager = LoginManager()
login_manager.init_app(app)
login_manager.login_view = 'login'

# Mastodon instance URL and access token
api_base_url = 'https://chatwithus.live'
access_token = os.getenv('MASTODON_ACCESS_TOKEN')
logger.info(f"Using Mastodon access token: {access_token[:6]}...")

# Initialize Mastodon API
mastodon = Mastodon(
    access_token=access_token,
    api_base_url=api_base_url
)

@login_manager.user_loader
def load_user(user_id):
    with app.app_context():
        session = db.session
        logger.debug(f"Loading user with ID: {user_id}")
        return session.get(User, user_id)

def post_toot(toot):
    try:
        if toot.suspended:
            logger.info(f"Toot '{toot.message}' is suspended. Skipping post.")
            return

        logger.info(f"Attempting to post toot: {toot.message}")
        mastodon.status_post(toot.message)
        logger.info(f"Successfully posted toot: {toot.message}")
    except Exception as e:
        logger.error(f"Failed to post toot: {toot.message} due to {e}")

@app.route('/')
@login_required
def index():
    logger.debug("Rendering index page")
    toots = Toot.query.all()
    logger.debug(f"Retrieved {len(toots)} toots from the database")
    return render_template('index.html', toots=toots)

@app.route('/add', methods=['POST'])
@login_required
def add_toot():
    message = request.form['message']
    toot_time = request.form['toot_time']
    day = request.form['day'].lower()

    logger.debug(f"Adding new toot with message: {message}, time: {toot_time}, day: {day}")

    new_toot = Toot(
        id=str(uuid.uuid4()),
        message=message,
        toot_time=toot_time,
        day=day
    )

    db.session.add(new_toot)
    db.session.commit()

    schedule_toot(new_toot)

    return redirect(url_for('index'))

@app.route('/delete/<toot_id>', methods=['POST'])
@login_required
def delete_toot(toot_id):
    logger.debug(f"Deleting toot with ID: {toot_id}")
    toot = Toot.query.get(toot_id)
    if toot:
        db.session.delete(toot)
        db.session.commit()
        sch.clear(toot_id)
        logger.info(f"Deleted toot with ID: {toot_id}")
    else:
        logger.warning(f"Toot with ID {toot_id} not found")

    return redirect(url_for('index'))

@app.route('/suspend/<toot_id>', methods=['POST'])
@login_required
def suspend_toot(toot_id):
    logger.debug(f"Suspending toot with ID: {toot_id}")
    toot = Toot.query.get(toot_id)
    if toot:
        toot.suspended = True
        db.session.commit()
        sch.clear(toot_id)
        flash(f"Toot '{toot.message}' has been suspended.")
        logger.info(f"Suspended toot with ID: {toot_id}")
    else:
        flash("Toot not found.")
        logger.warning(f"Toot with ID {toot_id} not found")
    return redirect(url_for('index'))

@app.route('/resume/<toot_id>', methods=['POST'])
@login_required
def resume_toot(toot_id):
    logger.debug(f"Resuming toot with ID: {toot_id}")
    toot = Toot.query.get(toot_id)
    if toot and toot.suspended:
        toot.suspended = False
        db.session.commit()
        schedule_toot(toot)
        flash(f"Toot '{toot.message}' has been resumed.")
        logger.info(f"Resumed toot with ID: {toot_id}")
    else:
        flash("Toot not found or already active.")
        logger.warning(f"Toot with ID {toot_id} not found or not suspended")
    return redirect(url_for('index'))

@app.route('/logout', methods=['POST'])
@login_required
def logout():
    logger.debug("Logging out user")
    logout_user()
    return redirect(url_for('login'))

@app.route('/login', methods=['GET', 'POST'])
def login():
    logger.debug("Rendering login page")
    form = LoginForm()
    logger.debug(f"CSRF token: {form.csrf_token.data}")
    if form.validate_on_submit():
        logger.debug(f"Login form submitted with username: {form.username.data}")
        user = User.query.filter_by(username=form.username.data).first()
        if user and user.check_password(form.password.data):
            logger.info(f"User {form.username.data} authenticated successfully")
            login_user(user)
            return redirect(url_for('index'))
        logger.warning(f"Authentication failed for user {form.username.data}")
        flash('Invalid username or password')
    return render_template('login.html', form=form)

@app.route('/register', methods=['GET', 'POST'])
def register():
    form = RegistrationForm()
    if form.validate_on_submit():
        username = form.username.data
        email = form.email.data
        password = form.password.data
        hashed_password = generate_password_hash(password)

        new_user = User(
            username=username,
            email=email,
            password=hashed_password
        )

        db.session.add(new_user)
        db.session.commit()

        flash('Your account has been created! You can now log in.', 'success')
        return redirect(url_for('login'))

    return render_template('register.html', form=form)

scheduler_lock = threading.Lock()

def schedule_toot(toot):
    try:
        if toot.suspended:
            logger.info(f"Toot '{toot.message}' is suspended. Skipping scheduling.")
            return

        with scheduler_lock:
            sch.clear(toot.id)
            day_schedule = {
                'monday': sch.every().monday,
                'tuesday': sch.every().tuesday,
                'wednesday': sch.every().wednesday,
                'thursday': sch.every().thursday,
                'friday': sch.every().friday,
                'saturday': sch.every().saturday,
                'sunday': sch.every().sunday,
                'everyday': sch.every().day
            }

            if toot.day in day_schedule:
                logger.info(f"Scheduling toot: {toot.message} for {toot.day} at {toot.toot_time}")
                day_schedule[toot.day].at(toot.toot_time).do(post_toot, toot).tag(toot.id)
            else:
                logger.error(f"Unknown day: {toot.day}. Unable to schedule toot.")
    except Exception as e:
        logger.error(f"Error scheduling toot: {str(e)}")

def run_scheduler():
    try:
        while True:
            sch.run_pending()
            t.sleep(1)
    except Exception as e:
        logger.error(f"Scheduler error: {str(e)}")

def initialize_scheduler():
    with app.app_context():
        db.create_all()
        sch.clear()
        for toot in Toot.query.all():
            schedule_toot(toot)

if __name__ == '__main__':
    if os.getenv("FLASK_ENV") != "development" or os.environ.get("WERKZEUG_RUN_MAIN") == "true":
        initialize_scheduler()
        scheduler_thread = threading.Thread(target=run_scheduler, daemon=True)
        scheduler_thread.start()

    app.run(debug=False, host='0.0.0.0', port=5010)
