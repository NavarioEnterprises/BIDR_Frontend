"""
Import Helper Module

This module provides helper functions to ensure correct imports across the project,
especially when running Django management commands that might have different Python paths.

Usage:
    from import_helper import setup_imports
    setup_imports()
    
    # Now you can import from any app in the project
    from user.models import AppUser
"""

import os
import sys


def setup_imports():
    """
    Add the project root directory to the Python path to ensure
    imports work correctly regardless of where the code is executed from.
    """
    project_root = os.path.dirname(os.path.abspath(__file__))
    if project_root not in sys.path:
        sys.path.append(project_root)