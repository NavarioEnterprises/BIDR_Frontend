from django.test import TestCase

from rest_framework import status
from rest_framework.test import APITestCase
from django.urls import reverse
from django.contrib.auth import get_user_model
from .models import Seller, CompanyInfo

User = get_user_model()


class SellerAPITests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(email='seller@example.com', password='password', role='seller', first_name='Test', last_name='User', phone_number='0123456789')
        self.client.force_authenticate(user=self.user)

    def test_seller_registration(self):
        url = reverse('seller-register')
        data = {
            'email': 'new_seller@example.com',
            'fullname': 'New Seller',
            'phone_number': '0987654321',
            'password': 'NewStrong@Password123',
            'confirm_password': 'NewStrong@Password123'
        }
        response = self.client.post(url, data)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertIn('user_id', response.data)

    def test_business_registration(self):
        url = reverse('seller-business-registration')
        data = {
            'company_details': {
                'registered_company_name': 'Test Company',
                'vat_number': '123456789'
            },
            'address_details': {
                'physical_address': '123 Test St',
                'city': 'Testville',
                'postal_code': '12345',
                'country': 'Testland',
                'contact_person_name': 'Contact Person',
                'contact_person_telephone': '0123456789',
                'contact_person_email_address': 'contact@example.com',
                'platform_workflow_email_address': 'workflow@example.com'
            },
            'bank_details': {
                'bank_name': 'Test Bank',
                'bank_account_number': '0123456789',
                'bank_branch_code': '123456',
                'bank_account_type': 'Business'
            }
        }
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertTrue(Seller.objects.filter(user=self.user).exists())
        # Check if seller was updated with company details
        seller = Seller.objects.get(user=self.user)
        self.assertEqual(seller.registered_company_name, 'Test Company')

    def test_seller_registration_invalid_password(self):
        """Test seller registration with invalid password"""
        url = reverse('seller-register')
        data = {
            'email': 'new_seller@example.com',
            'fullname': 'New Seller',
            'phone_number': '0987654321',
            'password': 'weak',
            'confirm_password': 'weak'
        }
        response = self.client.post(url, data)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_seller_registration_password_mismatch(self):
        """Test seller registration with password mismatch"""
        url = reverse('seller-register')
        data = {
            'email': 'new_seller@example.com',
            'fullname': 'New Seller',
            'phone_number': '0987654321',
            'password': 'NewStrong@Password123',
            'confirm_password': 'DifferentPassword123'
        }
        response = self.client.post(url, data)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('password', str(response.data).lower())

    def test_business_registration_requires_authentication(self):
        """Test that business registration requires authentication"""
        self.client.force_authenticate(user=None)  # Remove authentication
        url = reverse('seller-business-registration')
        data = {'company_details': {'registered_company_name': 'Test Company'}}
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_business_registration_non_seller_role(self):
        """Test business registration with non-seller role"""
        # Create a buyer user
        buyer_user = User.objects.create_user(
            email='buyer@example.com', 
            password='password', 
            role='buyer',
            first_name='Buyer', 
            last_name='User', 
            phone_number='0111222333'
        )
        self.client.force_authenticate(user=buyer_user)
        
        url = reverse('seller-business-registration')
        data = {'company_details': {'registered_company_name': 'Test Company'}}
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_document_upload_requires_seller_role(self):
        """Test document upload requires seller role"""
        buyer_user = User.objects.create_user(
            email='buyer2@example.com', 
            password='password', 
            role='buyer',
            first_name='Buyer2', 
            last_name='User', 
            phone_number='0111222334'
        )
        self.client.force_authenticate(user=buyer_user)
        
        url = reverse('seller-document-upload')
        data = {'certificate_of_incorporation_status': 'pending'}
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_document_upload_seller_not_found(self):
        """Test document upload when seller profile doesn't exist"""
        # Create a seller user but no corresponding Seller object
        seller_user = User.objects.create_user(
            email='noseller@example.com', 
            password='password', 
            role='seller',
            first_name='NoSeller', 
            last_name='User', 
            phone_number='0111222335'
        )
        self.client.force_authenticate(user=seller_user)
        
        url = reverse('seller-document-upload')
        data = {'certificate_of_incorporation_status': 'pending'}
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_seller_profile_viewset_permissions(self):
        """Test seller profile viewset permissions"""
        # Create a seller profile first
        seller = Seller.objects.create(user=self.user, registered_company_name='Test Company')
        from .models import SellerProfile
        profile = SellerProfile.objects.create(seller=seller)
        
        url = reverse('seller-profile-list')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Test unauthenticated access
        self.client.force_authenticate(user=None)
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
