"""
User Middleware for BIDR Authentication Service

Custom middleware for user-related functionality.
"""


class UserMiddleware:
    """
    Custom middleware for user handling
    """
    
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        # Code to be executed for each request before the view is called
        response = self.get_response(request)
        # Code to be executed for each request/response after the view is called
        return response
