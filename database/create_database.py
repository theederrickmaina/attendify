"""
Automated PostgreSQL Database Setup for Attendify
-----------------------------------------------
This script helps create the PostgreSQL database and user automatically.
"""

import psycopg2
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT
import sys
import getpass
from pathlib import Path

def create_database_and_user():
    """Create database and user for Attendify."""
    
    # Get PostgreSQL admin credentials
    print("PostgreSQL Database Setup for Attendify")
    print("=" * 50)
    
    try:
        # Connect to PostgreSQL default database (postgres) with your specific config
        admin_user = input("Enter PostgreSQL admin username (usually 'postgres'): ").strip() or "postgres"
        admin_password = getpass.getpass("Enter PostgreSQL admin password: ")
        
        # Connect to PostgreSQL server on port 5433
        conn = psycopg2.connect(
            host="localhost",
            port="5433",  # Your specific port
            database="postgres",
            user=admin_user,
            password=admin_password
        )
        conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
        cursor = conn.cursor()
        
        print("\n✓ Connected to PostgreSQL server on port 5433")
        
        # Create database
        try:
            cursor.execute("CREATE DATABASE attendify_db")
            print("✓ Created database 'attendify_db'")
        except psycopg2.errors.DuplicateDatabase:
            print("⚠ Database 'attendify_db' already exists")
        
        # Create user with your specific password - using postgres superuser
        try:
            # No need to create postgres user as it's the superuser
            print("✓ Using 'postgres' superuser (no additional user creation needed)")
        except Exception as e:
            print("⚠ Postgres superuser already exists")
        
        # Grant privileges - postgres already has all privileges
        try:
            # No need to grant privileges to postgres superuser
            print("✓ Postgres superuser has all privileges")
        except Exception as e:
            print("⚠ Privilege grant not needed for superuser")
        
        conn.close()
        
        # Connect to new database and create schema using the same admin credentials
        conn = psycopg2.connect(
            host="localhost",
            port="5433",  # Your specific port
            database="attendify_db",
            user=admin_user,
            password=admin_password
        )
        cursor = conn.cursor()
        
        # Read and execute schema
        with open('setup_postgresql.sql', 'r') as f:
            schema_sql = f.read()
        
        # Remove the database creation parts since we already did that
        lines = schema_sql.split('\n')
        filtered_lines = []
        skip_lines = False
        
        for line in lines:
            if 'CREATE DATABASE' in line:
                skip_lines = True
            elif line.strip() == '' and skip_lines:
                skip_lines = False
                continue
            elif not skip_lines:
                filtered_lines.append(line)
        
        schema_sql = '\n'.join(filtered_lines)
        cursor.execute(schema_sql)
        
        print("✓ Created database schema with pgvector support")
        print("✓ Created HNSW index for fast face matching")
        
        conn.commit()
        conn.close()
        
        print("\n🎉 Database setup completed successfully!")
        print("\nConnection details:")
        print("  Host: localhost")
        print("  Port: 5433")
        print("  Database: attendify_db")
        print(f"  User: {admin_user}")
        print("  Password: (as entered)")
        
        # Update .env file with correct connection string
        update_env_file(admin_user, admin_password)
        
        print("\n✅ Your .env file has been updated!")
        print("You can now start the backend server with:")
        print("  python start_backend.py")
        
    except psycopg2.OperationalError as e:
        print(f"❌ Connection failed: {e}")
        print("\nPlease check:")
        print("1. PostgreSQL is running on port 5433")
        print("2. Connection details are correct")
        print("3. User has necessary permissions")
        return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False
    
    return True

def update_env_file(db_user: str, db_password: str):
    """Update the .env file with the correct PostgreSQL connection string."""
    import urllib.parse
    env_path = Path(__file__).resolve().parent.parent / '.env'
    
    # URL-encode the password so special chars (like @) don't break the URI
    encoded_password = urllib.parse.quote_plus(db_password)
    
    env_content = f"""# Database Configuration
SQLALCHEMY_DATABASE_URI=postgresql://{db_user}:{encoded_password}@localhost:5433/attendify_db

# Security Keys (Generate new ones for production)
ATTENDIFY_SECRET_KEY=attendify-secret-key-change-in-production-2024
ATTENDIFY_JWT_SECRET=attendify-jwt-secret-change-in-production-2024
ATTENDIFY_FERNET_KEY=

# CORS Configuration
ATTENDIFY_CORS_ORIGINS=http://localhost:3000,http://localhost:8080,http://localhost:5000
"""
    
    with open(env_path, 'w') as f:
        f.write(env_content)
    
    print("✓ Updated .env file with PostgreSQL connection details")

if __name__ == "__main__":
    create_database_and_user()
