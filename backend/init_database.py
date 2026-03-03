"""
Database Initialization Script for Attendify
--------------------------------------------
Sets up PostgreSQL database and initializes with demo data.
"""

import os
import sys
from pathlib import Path

# Add the backend directory to Python path
backend_dir = Path(__file__).parent
sys.path.insert(0, str(backend_dir))

from app import app, initialize_database_with_demo_data
from extensions import db

def init_database():
    """
    Initialize the database with tables and demo data.
    """
    with app.app_context():
        print("Creating database tables...")
        db.create_all()
        
        print("Checking if demo data exists...")
        from models import User
        
        if User.query.count() == 0:
            print("Initializing demo data...")
            initialize_database_with_demo_data()
            print("Demo data initialized successfully!")
        else:
            print("Demo data already exists.")
        
        print("Database initialization complete!")

if __name__ == "__main__":
    init_database()
