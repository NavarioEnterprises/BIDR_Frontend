"""
Custom admin configuration to handle URL prefix properly
"""
from django.contrib import admin
from django.contrib.admin import AdminSite
from django.urls import reverse
from django.http import HttpResponseRedirect
from django.contrib.auth.views import LoginView
from django.contrib.auth.forms import AuthenticationForm


class ProductManagementAdminSite(AdminSite):
    """Custom admin site that handles URL prefixing correctly"""
    
    def login(self, request, extra_context=None):
        """
        Display the login form for the given HttpRequest.
        """
        if request.method == 'GET' and self.has_permission(request):
            # Already authenticated, redirect to index
            index_path = reverse('admin:index', current_app=self.name)
            return HttpResponseRedirect(index_path)

        from django.contrib.admin.forms import AdminAuthenticationForm
        from django.contrib.auth import authenticate, login
        from django.contrib.admin.views.decorators import staff_member_required
        
        # Use the standard Django admin login logic but ensure redirects work
        context = {
            'title': 'Log in',
            'app_path': request.get_full_path(),
            'username': request.user.get_username() if hasattr(request, 'user') else '',
        }
        
        if extra_context:
            context.update(extra_context)

        defaults = {
            'extra_context': context,
            'authentication_form': AdminAuthenticationForm,
            'template_name': 'admin/login.html',
        }
        
        # Create a custom login view that handles the URL prefix
        class CustomAdminLoginView(LoginView):
            def get_success_url(self):
                url = self.get_redirect_url()
                if url:
                    return url
                else:
                    # Ensure we redirect to the prefixed admin URL
                    return '/products/admin/'
            
            def form_valid(self, form):
                """Security check complete. Log the user in."""
                login(self.request, form.get_user())
                return HttpResponseRedirect(self.get_success_url())
        
        return CustomAdminLoginView.as_view(**defaults)(request)


# Create custom admin site instance
admin_site = ProductManagementAdminSite(name='product_admin')

# Register all the models that were registered with the default admin
for model, model_admin in admin.site._registry.items():
    admin_site.register(model, model_admin.__class__)
