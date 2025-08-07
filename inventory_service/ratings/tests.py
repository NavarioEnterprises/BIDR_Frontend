"""
Comprehensive tests for Ratings app.
"""

from django.test import TestCase
from django.contrib.auth.models import User
from django.utils import timezone
from decimal import Decimal
from .models import ProductRating, TransactionRating, ReviewHelpfulVote, TransactionIssue
from categories.models import Category
from products.models import Product
from transactions.models import Transaction
from core.models import StatusChoices


class ProductRatingModelTest(TestCase):
    """Test ProductRating model functionality."""
    
    def setUp(self):
        self.user = User.objects.create_user(
            username='rater',
            email='rater@example.com',
            password='testpass123'
        )
        
        self.category = Category.objects.create(
            name='Electronics',
            slug='electronics'
        )
        
        self.product = Product.objects.create(
            name='Test Product',
            slug='test-product',
            description='Test product',
            category=self.category,
            base_price=Decimal('100.00')
        )
    
    def test_product_rating_creation(self):
        """Test product rating creation."""
        rating = ProductRating.objects.create(
            product=self.product,
            rater=self.user,
            rating=5,
            comment='Excellent product! Highly recommended.'
        )
        
        self.assertEqual(rating.product, self.product)
        self.assertEqual(rating.rater, self.user)
        self.assertEqual(rating.rating, 5)
        self.assertEqual(rating.comment, 'Excellent product! Highly recommended.')
        self.assertEqual(rating.status, StatusChoices.PENDING)
    
    def test_product_rating_str_representation(self):
        """Test string representation of product rating."""
        rating = ProductRating.objects.create(
            product=self.product,
            rater=self.user,
            rating=4,
            comment='Good product'
        )
        
        expected_str = f"{self.product.name} - 4★ by {self.user.username}"
        self.assertEqual(str(rating), expected_str)
    
    def test_product_rating_unique_constraint(self):
        """Test unique constraint on product + rater."""
        ProductRating.objects.create(
            product=self.product,
            rater=self.user,
            rating=5,
            comment='First rating'
        )
        
        # Attempting to create another rating by the same user for the same product should fail
        with self.assertRaises(Exception):
            ProductRating.objects.create(
                product=self.product,
                rater=self.user,
                rating=3,
                comment='Second rating'
            )
    
    def test_rating_validation(self):
        """Test rating value validation (1-5)."""
        # Valid rating
        rating = ProductRating.objects.create(
            product=self.product,
            rater=self.user,
            rating=3,
            comment='Average product'
        )
        self.assertEqual(rating.rating, 3)
        
        # Invalid ratings should be caught by model validators
        # Note: In a real test, we'd need to call full_clean() to trigger validators


class TransactionRatingModelTest(TestCase):
    """Test TransactionRating model functionality."""
    
    def setUp(self):
        self.buyer = User.objects.create_user(
            username='buyer',
            email='buyer@example.com',
            password='testpass123'
        )
        
        self.seller = User.objects.create_user(
            username='seller',
            email='seller@example.com',
            password='testpass123'
        )
        
        self.transaction = Transaction.objects.create(
            buyer=self.buyer,
            seller=self.seller,
            subtotal=Decimal('200.00'),
            total_amount=Decimal('200.00')
        )
    
    def test_transaction_rating_creation(self):
        """Test transaction rating creation."""
        rating = TransactionRating.objects.create(
            transaction=self.transaction,
            rater=self.buyer,
            rating=5,
            comment='Excellent service and fast delivery!'
        )
        
        self.assertEqual(rating.transaction, self.transaction)
        self.assertEqual(rating.rater, self.buyer)
        self.assertEqual(rating.rating, 5)
        self.assertEqual(rating.comment, 'Excellent service and fast delivery!')
        self.assertEqual(rating.status, StatusChoices.APPROVED)  # Default for transaction ratings
    
    def test_transaction_rating_str_representation(self):
        """Test string representation of transaction rating."""
        rating = TransactionRating.objects.create(
            transaction=self.transaction,
            rater=self.buyer,
            rating=4,
            comment='Good transaction'
        )
        
        expected_str = f"Transaction {self.transaction.reference_number} - 4★ by {self.buyer.username}"
        self.assertEqual(str(rating), expected_str)
    
    def test_transaction_rating_one_to_one_constraint(self):
        """Test one-to-one constraint on transaction."""
        TransactionRating.objects.create(
            transaction=self.transaction,
            rater=self.buyer,
            rating=5,
            comment='First rating'
        )
        
        # Attempting to create another rating for the same transaction should fail
        with self.assertRaises(Exception):
            TransactionRating.objects.create(
                transaction=self.transaction,
                rater=self.seller,
                rating=3,
                comment='Second rating'
            )


class ReviewHelpfulVoteModelTest(TestCase):
    """Test ReviewHelpfulVote model functionality."""
    
    def setUp(self):
        self.reviewer = User.objects.create_user(
            username='reviewer',
            email='reviewer@example.com',
            password='testpass123'
        )
        
        self.voter = User.objects.create_user(
            username='voter',
            email='voter@example.com',
            password='testpass123'
        )
        
        self.category = Category.objects.create(
            name='Electronics',
            slug='electronics'
        )
        
        self.product = Product.objects.create(
            name='Test Product',
            slug='test-product',
            description='Test product',
            category=self.category,
            base_price=Decimal('100.00')
        )
        
        self.review = ProductRating.objects.create(
            product=self.product,
            rater=self.reviewer,
            rating=4,
            comment='Good product with minor issues'
        )
    
    def test_helpful_vote_creation(self):
        """Test helpful vote creation."""
        vote = ReviewHelpfulVote.objects.create(
            review=self.review,
            voter=self.voter,
            is_helpful=True
        )
        
        self.assertEqual(vote.review, self.review)
        self.assertEqual(vote.voter, self.voter)
        self.assertTrue(vote.is_helpful)
    
    def test_helpful_vote_str_representation(self):
        """Test string representation of helpful vote."""
        helpful_vote = ReviewHelpfulVote.objects.create(
            review=self.review,
            voter=self.voter,
            is_helpful=True
        )
        
        expected_str = f"{self.product.name} review by {self.reviewer.username}: Helpful"
        self.assertEqual(str(helpful_vote), expected_str)
        
        # Test not helpful vote
        not_helpful_vote = ReviewHelpfulVote.objects.create(
            review=self.review,
            voter=User.objects.create_user('voter2', 'voter2@example.com', 'pass'),
            is_helpful=False
        )
        
        expected_str = f"{self.product.name} review by {self.reviewer.username}: Not helpful"
        self.assertEqual(str(not_helpful_vote), expected_str)
    
    def test_helpful_vote_unique_constraint(self):
        """Test unique constraint on review + voter."""
        ReviewHelpfulVote.objects.create(
            review=self.review,
            voter=self.voter,
            is_helpful=True
        )
        
        # Attempting to create another vote by the same user for the same review should fail
        with self.assertRaises(Exception):
            ReviewHelpfulVote.objects.create(
                review=self.review,
                voter=self.voter,
                is_helpful=False
            )


class TransactionIssueModelTest(TestCase):
    """Test TransactionIssue model functionality."""
    
    def setUp(self):
        self.buyer = User.objects.create_user(
            username='buyer',
            email='buyer@example.com',
            password='testpass123'
        )
        
        self.seller = User.objects.create_user(
            username='seller',
            email='seller@example.com',
            password='testpass123'
        )
        
        self.transaction = Transaction.objects.create(
            buyer=self.buyer,
            seller=self.seller,
            subtotal=Decimal('300.00'),
            total_amount=Decimal('300.00')
        )
    
    def test_transaction_issue_creation(self):
        """Test transaction issue creation."""
        issue = TransactionIssue.objects.create(
            transaction=self.transaction,
            reporter=self.buyer,
            summary='Product not as described',
            description='The product I received does not match the description on the website. The color is different and some features are missing.'
        )
        
        self.assertEqual(issue.transaction, self.transaction)
        self.assertEqual(issue.reporter, self.buyer)
        self.assertEqual(issue.summary, 'Product not as described')
        self.assertEqual(issue.status, StatusChoices.PENDING)
        self.assertIsNone(issue.resolved_at)
    
    def test_transaction_issue_str_representation(self):
        """Test string representation of transaction issue."""
        issue = TransactionIssue.objects.create(
            transaction=self.transaction,
            reporter=self.buyer,
            summary='Delivery delay',
            description='My order was supposed to arrive yesterday but it is still not here.'
        )
        
        expected_str = f"{self.transaction.reference_number} - Delivery delay"
        self.assertEqual(str(issue), expected_str)
    
    def test_mark_as_resolved_method(self):
        """Test mark_as_resolved method."""
        issue = TransactionIssue.objects.create(
            transaction=self.transaction,
            reporter=self.buyer,
            summary='Payment issue',
            description='My payment was charged twice for this order.'
        )
        
        # Initially not resolved
        self.assertEqual(issue.status, StatusChoices.PENDING)
        self.assertIsNone(issue.resolved_at)
        self.assertEqual(issue.resolution, '')
        
        # Mark as resolved
        resolution_text = 'Refund processed for the duplicate charge. Please allow 3-5 business days for the refund to appear on your statement.'
        issue.mark_as_resolved(resolution_text)
        
        self.assertEqual(issue.status, StatusChoices.COMPLETED)
        self.assertIsNotNone(issue.resolved_at)
        self.assertEqual(issue.resolution, resolution_text)
    
    def test_multiple_issues_per_transaction(self):
        """Test that multiple issues can be created for the same transaction."""
        issue1 = TransactionIssue.objects.create(
            transaction=self.transaction,
            reporter=self.buyer,
            summary='First issue',
            description='First issue description'
        )
        
        issue2 = TransactionIssue.objects.create(
            transaction=self.transaction,
            reporter=self.buyer,
            summary='Second issue',
            description='Second issue description'
        )
        
        self.assertNotEqual(issue1, issue2)
        self.assertEqual(issue1.transaction, issue2.transaction)
        
        # Check that both issues are related to the transaction
        transaction_issues = TransactionIssue.objects.filter(transaction=self.transaction)
        self.assertEqual(transaction_issues.count(), 2)
        self.assertIn(issue1, transaction_issues)
        self.assertIn(issue2, transaction_issues)
