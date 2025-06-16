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

# Load environment variables from .env file
load_dotenv()

# Initialize logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Securely configure the app secret key
app.secret_key = os.urandom(24)

# Database configuration
db_user = os.getenv('DB_USER', 'your_db_user')
db_password = os.getenv('DB_PASSWORD', 'your_db_password')
db_name = os.getenv('DB_NAME', 'tootdb')
db_host_primary = os.getenv('DB_HOST_PRIMARY', 'db3.cluster.doctatortot.com')
db_host_failover = os.getenv('DB_HOST_FAILOVER', 'db4.cluster.doctatortot.com')

def get_database_uri(host):
    return f'postgresql://{db_user}:{db_password}@{host}/{db_name}'

def create_db_session():
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
    for host in [db_host_primary, db_host_failover]:
        try:
            app.config['SQLALCHEMY_DATABASE_URI'] = get_database_uri(host)
            db.init_app(app)
            conn = psycopg2.connect(get_database_uri(host))
            conn.close()
            return db
        except Exception as error:
            logger.error(f"Database connection failed at {host}: {error}")
    raise Exception("Both primary and failover database connections failed.")

db = create_db_session()
migrate = Migrate(app, db)

# Flask-Login configuration
login_manager = LoginManager()
login_manager.init_app(app)
login_manager.login_view = 'login'

# Mastodon instance URL and access token
api_base_url = 'https://mastodon.social'
access_token = os.getenv('MASTODON_ACCESS_TOKEN')

if not access_token:
    raise ValueError("Please set the MASTODON_ACCESS_TOKEN environment variable.")
else:
    logger.info(f"Using Mastodon access token: {access_token[:6]}...")

# Initialize Mastodon API
mastodon = Mastodon(
    access_token=access_token,
    api_base_url=api_base_url
)

@login_manager.user_loader
def load_user(user_id):
    return User.query.get(user_id)

def post_toot(toot):
    try:
        logger.info(f"Attempting to post toot: {toot.message}")
        mastodon.status_post(toot.message)
        logger.info(f"Successfully posted toot: {toot.message}")
    except Exception as e:
        logger.error(f"Failed to post toot: {toot.message} due to {e}")

@app.route('/')
@login_required
def index():
    toots = Toot.query.all()
    return render_template('index.html', toots=toots)

@app.route('/add', methods=['POST'])
@login_required
def add_toot():
    message = request.form['message']
    toot_time = request.form['toot_time']
    day = request.form['day'].lower()

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
    toot = Toot.query.get(toot_id)
    if toot:
        db.session.delete(toot)
        db.session.commit()
        sch.clear(toot_id)
    
    return redirect(url_for('index'))

@app.route('/register', methods=['GET', 'POST'])
def register():
    form = RegistrationForm()
    if form.validate_on_submit():
        user = User(
            id=str(uuid.uuid4()),
            username=form.username.data,
            email=form.email.data
        )
        user.set_password(form.password.data)
        db.session.add(user)
        db.session.commit()
        flash('Congratulations, you are now a registered user!')
        return redirect(url_for('login'))
    return render_template('register.html', form=form)

@app.route('/login', methods=['GET', 'POST'])
def login():
    form = LoginForm()
    if form.validate_on_submit():
        user = User.query.filter_by(username=form.username.data).first()
        if user is None or not user.check_password(form.password.data):
            flash('Invalid username or password')
            return redirect(url_for('login'))
        login_user(user)
        return redirect(url_for('index'))
    return render_template('login.html', form=form)

@app.route('/logout', methods=['GET', 'POST'])
@login_required
def logout():
    logout_user()
    return redirect(url_for('login'))


scheduler_lock = threading.Lock()

def schedule_toot(toot):
    try:
        with scheduler_lock:
            # Check if the toot is already scheduled
            jobs = sch.get_jobs(tag=toot.id)
            if jobs:
                logger.info(f"Toot with ID {toot.id} is already scheduled. Skipping scheduling.")
                return

            # Clear any existing schedule for this toot ID
            sch.clear(toot.id)

            day_schedule = {
                'monday': sch.every().monday,
                'tuesday': sch.every().tuesday,
                'wednesday': sch.every().wednesday,
                'thursday': sch.every().thursday,
                'friday': sch.every().friday,
                'saturday': sch.every().saturday,
                'sunday': sch.every().sunday,
                'everyday': sch.every().day  # New case for everyday scheduling
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

        # Schedule existing toots when the app starts
        sch.clear()  # Clear all scheduled tasks initially
        for toot in Toot.query.all():
            schedule_toot(toot)

if __name__ == '__main__':
    # Initialize the scheduler once, outside the debug mode restart
    if os.getenv("FLASK_ENV") != "development" or os.environ.get("WERKZEUG_RUN_MAIN") == "true":
        initialize_scheduler()
        # Run the scheduler in a separate thread
        scheduler_thread = threading.Thread(target=run_scheduler, daemon=True)
        scheduler_thread.start()

    app.run(debug=False, host='0.0.0.0', port=5011)

