#!/usr/bin/env python
"""
Test script to verify the PaymentTransaction model and payment gateways.
This is a simplified test that doesn't require Django setup.
"""

# Mock the Transaction class
class MockTransaction:
    def __init__(self, transaction_id="12345"):
        self.transaction_id = transaction_id
    
    def __str__(self):
        return f"Transaction {self.transaction_id}"

# Mock the PaymentTransaction class
class MockPaymentTransaction:
    def __init__(self, payment_id="67890", transaction_id=None, payment_gateway="PAYFAST", 
                 amount=100.00, currency="USD", payment_method="CREDIT_CARD", status="PENDING"):
        self.payment_id = payment_id
        self.transaction_id = transaction_id or MockTransaction()
        self.payment_gateway = payment_gateway
        self.amount = amount
        self.currency = currency
        self.payment_method = payment_method
        self.gateway_transaction_id = None
        self.gateway_response = None
        self.status = status
    
    def __str__(self):
        return f"Payment {self.payment_id} for {self.transaction_id}"

# Mock the payment gateway classes
class MockPaymentGateway:
    def __init__(self, config=None):
        self.config = config or {}
    
    def process_payment(self, payment_transaction):
        """Process a payment through the gateway."""
        raise NotImplementedError("Subclasses must implement process_payment")
    
    def verify_payment(self, payment_transaction):
        """Verify a payment's status with the gateway."""
        raise NotImplementedError("Subclasses must implement verify_payment")
    
    def refund_payment(self, payment_transaction, amount=None):
        """Refund a payment through the gateway."""
        raise NotImplementedError("Subclasses must implement refund_payment")

class MockPayFastGateway(MockPaymentGateway):
    def process_payment(self, payment_transaction):
        payment_transaction.status = 'PENDING'
        payment_transaction.gateway_response = {'status': 'pending', 'message': 'Payment initiated'}
        return payment_transaction
    
    def verify_payment(self, payment_transaction):
        return {'verified': True, 'status': payment_transaction.status}
    
    def refund_payment(self, payment_transaction, amount=None):
        refund_amount = amount or payment_transaction.amount
        payment_transaction.status = 'REFUNDED'
        payment_transaction.gateway_response = {
            'status': 'refunded',
            'refund_amount': str(refund_amount),
            'message': 'Payment refunded'
        }
        return payment_transaction

class MockStripeGateway(MockPaymentGateway):
    def process_payment(self, payment_transaction):
        payment_transaction.status = 'PENDING'
        payment_transaction.gateway_response = {'status': 'pending', 'message': 'Payment initiated'}
        return payment_transaction
    
    def verify_payment(self, payment_transaction):
        return {'verified': True, 'status': payment_transaction.status}
    
    def refund_payment(self, payment_transaction, amount=None):
        refund_amount = amount or payment_transaction.amount
        payment_transaction.status = 'REFUNDED'
        payment_transaction.gateway_response = {
            'status': 'refunded',
            'refund_amount': str(refund_amount),
            'message': 'Payment refunded'
        }
        return payment_transaction

class MockPayPalGateway(MockPaymentGateway):
    def process_payment(self, payment_transaction):
        payment_transaction.status = 'PENDING'
        payment_transaction.gateway_response = {'status': 'pending', 'message': 'Payment initiated'}
        return payment_transaction
    
    def verify_payment(self, payment_transaction):
        return {'verified': True, 'status': payment_transaction.status}
    
    def refund_payment(self, payment_transaction, amount=None):
        refund_amount = amount or payment_transaction.amount
        payment_transaction.status = 'REFUNDED'
        payment_transaction.gateway_response = {
            'status': 'refunded',
            'refund_amount': str(refund_amount),
            'message': 'Payment refunded'
        }
        return payment_transaction

def get_mock_payment_gateway(gateway_name):
    gateways = {
        'PAYFAST': MockPayFastGateway,
        'STRIPE': MockStripeGateway,
        'PAYPAL': MockPayPalGateway,
    }
    
    gateway_class = gateways.get(gateway_name.upper())
    if not gateway_class:
        raise ValueError(f"Unsupported payment gateway: {gateway_name}")
    
    return gateway_class()

def test_payment_transaction():
    """Test the PaymentTransaction model and payment gateways."""
    print("Testing PaymentTransaction model and payment gateways...")
    
    # Test 1: Create a payment transaction
    print("\nTest 1: Create a payment transaction")
    transaction = MockTransaction("12345")
    payment = MockPaymentTransaction(
        payment_id="67890",
        transaction_id=transaction,
        payment_gateway="PAYFAST",
        amount=100.00,
        currency="USD",
        payment_method="CREDIT_CARD",
        status="PENDING"
    )
    
    print(f"Created payment: {payment}")
    print(f"Payment details: gateway={payment.payment_gateway}, amount={payment.amount} {payment.currency}")
    print(f"Payment status: {payment.status}")
    
    # Test 2: Process payment through different gateways
    print("\nTest 2: Process payment through different gateways")
    
    for gateway_name in ["PAYFAST", "STRIPE", "PAYPAL"]:
        print(f"\nTesting {gateway_name} gateway:")
        gateway = get_mock_payment_gateway(gateway_name)
        
        # Process payment
        payment.payment_gateway = gateway_name
        payment = gateway.process_payment(payment)
        print(f"After processing: status={payment.status}, response={payment.gateway_response}")
        
        # Verify payment
        verification = gateway.verify_payment(payment)
        print(f"Verification result: {verification}")
        
        # Refund payment
        payment = gateway.refund_payment(payment)
        print(f"After refund: status={payment.status}, response={payment.gateway_response}")

if __name__ == "__main__":
    test_payment_transaction()