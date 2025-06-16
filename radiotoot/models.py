from flask_sqlalchemy import SQLAlchemy
from flask_login import UserMixin  # Import UserMixin for Flask-Login integration

db = SQLAlchemy()

class User(UserMixin, db.Model):  # Inherit from UserMixin!
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(100), unique=True, nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.String(255), nullable=False)

    def check_password(self, password):
        from werkzeug.security import check_password_hash
        return check_password_hash(self.password_hash, password)

class Toot(db.Model):
    id = db.Column(db.String(36), primary_key=True)
    message = db.Column(db.String(255), nullable=False)
    toot_time = db.Column(db.String(5), nullable=False)
    day = db.Column(db.String(9), nullable=False)
    suspended = db.Column(db.Boolean, default=False)
