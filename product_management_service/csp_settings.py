# Content Security Policy Settings for Django
# Add these to your settings.py if you want to configure CSP

# First, install django-csp:
# pip install django-csp

# Add to INSTALLED_APPS:
# 'csp',

# Add to MIDDLEWARE (should be early in the list):
# 'csp.middleware.CSPMiddleware',

# CSP Configuration
CSP_DEFAULT_SRC = ("'self'", "data:", "https:", "'unsafe-inline'", "'unsafe-eval'")
CSP_CONNECT_SRC = (
    "'self'", 
    "https:", 
    "wss:",
    "ws:",
    # Allow localhost connections for development
    "http://localhost:*",
    "https://localhost:*",
    "ws://localhost:*",
    "wss://localhost:*",
)

CSP_SCRIPT_SRC = (
    "'self'",
    "'unsafe-inline'", 
    "'unsafe-eval'",
    "https:",
    # Allow localhost for development scripts
    "http://localhost:*",
    "https://localhost:*",
)

CSP_STYLE_SRC = (
    "'self'",
    "'unsafe-inline'",
    "https:",
    # Allow localhost stylesheets
    "http://localhost:*",
    "https://localhost:*",
)

CSP_IMG_SRC = (
    "'self'",
    "data:",
    "https:",
    "http:",
    # Allow localhost images
    "http://localhost:*",
    "https://localhost:*",
)

CSP_FONT_SRC = (
    "'self'",
    "data:",
    "https:",
    # Allow localhost fonts
    "http://localhost:*",
    "https://localhost:*",
)

# Allow frames from localhost (for development tools)
CSP_FRAME_SRC = (
    "'self'",
    "https:",
    "http://localhost:*",
    "https://localhost:*",
)

# Allow web workers
CSP_WORKER_SRC = (
    "'self'",
    "blob:",
    "https:",
    "http://localhost:*",
    "https://localhost:*",
)

# Report violations in development
CSP_REPORT_ONLY = True  # Set to False in production
CSP_EXCLUDE_URL_PREFIXES = ('/admin/',)  # Exclude admin from CSP

# Development-friendly settings
if DEBUG:
    CSP_CONNECT_SRC += (
        "http://localhost:61978",  # Specific port from your error
        "ws://localhost:61978",
        "wss://localhost:61978",
    )
