from django.urls import path
from .views import logs_info

urlpatterns = [
    path('info/', logs_info, name='logs-info'),
]
