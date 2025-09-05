from django.contrib.auth import get_user_model
User = get_user_model()
email = 'thulanimoyo@example.com'
password = 'Navario@544'
try:
    user = User.objects.get(email=email)
    user.is_staff = True
    user.is_superuser = True
    user.first_name = 'Thulani'
    user.last_name = 'Moyo'
    user.set_password(password)
    user.save()
    print('Updated existing user to superuser')
except User.DoesNotExist:
    user = User.objects.create_superuser(email=email, password=password, first_name='Thulani', last_name='Moyo')
    print('Created new superuser')
print('Superuser setup complete!')
