# Installing pgvector Extension for PostgreSQL
============================================

## Windows Installation (for PostgreSQL on Windows)

### Option 1: Using pgvector Windows Binaries (Recommended)

1. **Download pgvector for Windows:**
   ```bash
   # Download the pre-compiled binary for your PostgreSQL version
   # Visit: https://github.com/pgvector/pgvector/releases
   # Download the appropriate Windows package
   ```

2. **Extract to PostgreSQL directory:**
   ```bash
   # Extract the downloaded package to your PostgreSQL lib directory
   # Usually: C:\Program Files\PostgreSQL\<version>\lib\
   # And include files to: C:\Program Files\PostgreSQL\<version>\include\
   ```

3. **Enable the extension:**
   ```sql
   -- Connect to your PostgreSQL database and run:
   CREATE EXTENSION IF NOT EXISTS vector;
   ```

### Option 2: Using Docker (Easiest)

1. **Use pgvector-enabled PostgreSQL container:**
   ```bash
   docker run -d \
     --name postgres-pgvector \
     -e POSTGRES_PASSWORD=123@Gatu. \
     -e POSTGRES_USER=postgres \
     -e POSTGRES_DB=attendify_db \
     -p 5433:5432 \
     pgvector/pgvector:pg16
   ```

2. **Update your .env file:**
   ```
   SQLALCHEMY_DATABASE_URI=postgresql://postgres:123@Gatu.@localhost:5433/attendify_db
   ```

### Option 3: Using WSL (Windows Subsystem for Linux)

1. **Install PostgreSQL with pgvector in WSL:**
   ```bash
   # In WSL Ubuntu/Debian:
   sudo apt update
   sudo apt install postgresql postgresql-contrib
   sudo apt install postgresql-16-pgvector  # or your PostgreSQL version
   ```

2. **Configure PostgreSQL to use port 5433:**
   ```bash
   sudo -u postgres psql
   ALTER SYSTEM SET port = 5433;
   SELECT pg_reload_conf();
   ```

## Verification

After installation, verify pgvector is available:

```sql
-- Connect to your database and run:
SELECT * FROM pg_available_extensions WHERE name = 'vector';
```

You should see 'vector' in the results.

## Alternative: Skip pgvector for Now

If you want to test the system without pgvector temporarily:

1. **Use the original BYTEA approach:**
   - Comment out vector-related code in models.py
   - Use the original encrypted storage method
   - System will work but with slower performance

2. **Install pgvector later:**
   - System is designed to work with both approaches
   - Simply install pgvector and uncomment vector code when ready

## Quick Test

Test if pgvector is working:

```sql
-- Test vector operations:
SELECT '[1,2,3]'::vector <=> '[1,2,4]'::vector as distance;
```

Should return a numeric distance value.
