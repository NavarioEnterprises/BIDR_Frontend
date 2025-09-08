from django.contrib.auth.backends import BaseBackend
from django.contrib.auth import get_user_model
from django.db.models import Q

User = get_user_model()


class CaseInsensitiveEmailBackend(BaseBackend):
    """
    Custom authentication backend that allows case-insensitive email login
    """
    
    def authenticate(self, request, email=None, password=None, **kwargs):
        """
        Authenticate user with case-insensitive email
        """
        if email is None or password is None:
            return None
        
        # Convert email to lowercase for case-insensitive lookup
        email = email.lower().strip()
        
        try:
            # Use iexact for case-insensitive email lookup
            user = User.objects.get(email__iexact=email)
            
            # Check if password is correct
            if user.check_password(password):
                return user
                
        except User.DoesNotExist:
            # Run the default password hasher once to reduce timing difference
            User().set_password(password)
            return None
        
        return None
    
    def get_user(self, user_id):
        """
        Get user by ID
        """
        try:
            return User.objects.get(pk=user_id)
        except User.DoesNotExist:
            return None