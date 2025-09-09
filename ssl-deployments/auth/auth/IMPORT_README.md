# Import Helper Documentation

## Problem

The Django project structure in this application can cause import issues when running certain Django management commands like `startapp`. This happens because the Python path is different when running these commands compared to normal application operation.

Specifically, imports that use the pattern `from authentication_service.user.models import AppUser` work during normal operation but fail during management commands with errors like:

```
ModuleNotFoundError: No module named 'authentication_service.user'
```

## Solution

We've implemented an `import_helper.py` module that ensures the Python path is correctly set up regardless of how the code is executed.

### How to Use

1. At the top of your file, import the helper:

```python
from import_helper import setup_imports
```

2. Call the setup function before any app imports:

```python
setup_imports()
```

3. Then import from other apps directly:

```python
from user.models import AppUser
```

### Example

```python
from django.db import models

# Import the helper and set up the path
from import_helper import setup_imports
setup_imports()

# Now you can import from any app in the project
from user.models import AppUser

class MyModel(models.Model):
    user = models.ForeignKey(AppUser, on_delete=models.CASCADE)
    # ...
```

## Files Using This Pattern

The following files have been updated to use this import pattern:

- otp/models.py
- buyer/models.py
- analytics/models.py
- api_management/models.py
- buyer/serializer.py
- otp/serializers.py
- otp/views.py
- security/models.py

## When to Use This Pattern

Use this pattern whenever you need to import from another app in the project, especially in model files that might be loaded during Django management commands.