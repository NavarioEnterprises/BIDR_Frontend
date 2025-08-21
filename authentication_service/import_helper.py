"""
Import helper module for managing Django app imports.
This is a helper utility to handle import path setup for local development.
"""

def setup_imports():
    """Set up import paths for local development."""
    import sys
    import os
    
    # Get the current directory (authentication_service)
    current_dir = os.path.dirname(os.path.abspath(__file__))
    
    # Add the current directory to Python path if not already present
    if current_dir not in sys.path:
        sys.path.insert(0, current_dir)
