"""
Shared Flask extensions for Attendify.
Defines the SQLAlchemy instance to avoid circular imports between app and models.
"""

from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()

