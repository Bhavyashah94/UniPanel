# deploy_db.py
import psycopg # Import psycopg (v3)
import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

def execute_sql_file(cursor, filepath):
    """Reads and executes SQL commands from a file."""
    try:
        with open(os.path.join(os.path.dirname(os.path.abspath(__file__)),filepath), 'r') as f:
            sql_commands = f.read()
    
        # Psycopg (v3) can handle multiple statements in one execute() call by default
        # For very large or complex files, you might still want to split by semicolon
        # and execute one by one, but for DDL, executing the whole file is often fine.
        cursor.execute(sql_commands)
        print(f"Successfully executed {filepath}")
    except Exception as e:
        print(f"Error executing {filepath}: {e}")
        raise

def deploy_database_schema():
    """Connects to PostgreSQL and deploys the schema and triggers."""
    db_host = os.getenv("DB_HOST")
    db_name = os.getenv("DB_NAME")
    db_user = os.getenv("DB_USER")
    db_password = os.getenv("DB_PASSWORD")
    db_port = os.getenv("DB_PORT")

    conn = None
    try:
        # Establish connection using psycopg (v3)
        conn = psycopg.connect(
            host=db_host,
            dbname=db_name, # Note: psycopg3 uses dbname, not database
            user=db_user,
            password=db_password,
            port=db_port
        )
        conn.autocommit = False # We'll manage transactions manually with BEGIN/COMMIT in SQL files

        # Use a context manager for the cursor for cleaner resource management
        with conn.cursor() as cursor:
            # Execute schema.sql
            print("Deploying schema...")
            execute_sql_file(cursor, 'schema.sql')
            
            # Execute triggers.sql
            print("Deploying triggers...")
            execute_sql_file(cursor, 'triggers.sql')
            
            conn.commit() # Commit the transaction if everything succeeded
        print("Database schema and triggers deployed successfully!")

    except psycopg.Error as e: # Catch psycopg.Error
        print(f"Database connection or execution error: {e}")
        if conn:
            conn.rollback() # Rollback on error
            print("Transaction rolled back.")
    except Exception as e:
        print(f"An unexpected error occurred: {e}")
    finally:
        if conn:
            conn.close()
            print("Database connection closed.")

if __name__ == "__main__":
    deploy_database_schema()