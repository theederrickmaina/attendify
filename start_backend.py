"""
Backend Startup Script for Attendify
------------------------------------
Starts the Flask backend server with proper configuration.
"""

import os
import sys
from pathlib import Path

# Add the backend directory to Python path
backend_dir = Path(__file__).parent / "backend"
sys.path.insert(0, str(backend_dir))

# Change to backend directory
os.chdir(backend_dir)

if __name__ == "__main__":
    from app import app
    
    print("Starting Attendify Backend Server...")
    print("Face recognition service will be initialized on first use")
    print("API will be available at: http://localhost:5000")
    print("Health check: http://localhost:5000/health")
    print("\nPress Ctrl+C to stop the server")
    
    # Run the Flask app
    app.run(
        host="0.0.0.0",
        port=5000,
        debug=True,
        use_reloader=False  # Prevent issues with face recognition initialization
    )
