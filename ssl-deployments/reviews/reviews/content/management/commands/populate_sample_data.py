from django.core.management.base import BaseCommand
from django.contrib.auth.models import User
from django.utils import timezone
from datetime import date
from content.models import FAQ, Blog, Policy, ContactSubmission


class Command(BaseCommand):
    help = 'Populate database with sample FAQs, Blogs, and Policies'

    def handle(self, *args, **options):
        self.stdout.write('Populating sample data...')
        
        # Create admin user for blogs
        admin_user, created = User.objects.get_or_create(
            username='admin',
            defaults={
                'email': 'admin@bidr.com',
                'is_staff': True,
                'is_superuser': True,
                'first_name': 'Admin',
                'last_name': 'User'
            }
        )
        if created:
            admin_user.set_password('admin123')
            admin_user.save()
            self.stdout.write('Created admin user')
        
        # Sample FAQs
        faqs_data = [
            {
                'question': "What is BIDR?",
                'answer': "BIDR is a next-generation marketplace platform that revolutionizes buyer-seller connections through competitive bidding mechanisms. We support vehicle spare parts, tyres & rims, and consumer electronics marketplaces.",
                'category': "general",
                'order': 1
            },
            {
                'question': "How does the PIN verification system work?",
                'answer': "When a transaction is initiated, both buyer and seller receive unique 6-digit PINs. During physical product exchange, both parties exchange PINs to verify the transaction. This dual PIN verification ensures secure transactions and releases payment from escrow.",
                'category': "security",
                'order': 1
            },
            {
                'question': "What categories of products can I buy/sell on BIDR?",
                'answer': "BIDR supports three main categories:\n• Vehicle Spare Parts - New and used auto parts\n• Tyres & Rims - All specifications and brands\n• Consumer Electronics - Wide range of electronic products",
                'category': "products",
                'order': 1
            },
            {
                'question': "How long is my payment held in escrow?",
                'answer': "Payment hold periods vary by category:\n• Vehicle Parts: 7 days from PIN exchange\n• Electronics: 14 days from PIN exchange\n• Custom/High-value items: 21 days from PIN exchange",
                'category': "payments",
                'order': 1
            },
            {
                'question': "How do I create a product request as a buyer?",
                'answer': "1. Navigate to 'Create Request'\n2. Select your product category\n3. Fill in product specifications\n4. Set your budget and timeline\n5. Specify location and travel distance\n6. Submit request for sellers to quote",
                'category': "buying",
                'order': 1
            },
            {
                'question': "How do sellers submit quotes?",
                'answer': "Sellers can:\n1. Browse active product requests\n2. Filter by category and location\n3. Review buyer requirements\n4. Submit competitive quotes with pricing, delivery terms, and warranty information\n5. Engage with buyers through the chat system",
                'category': "selling",
                'order': 1
            },
            {
                'question': "What happens if I'm not satisfied with my purchase?",
                'answer': "You can initiate a return within the escrow period. You'll need to:\n1. Document the issue with photos\n2. Specify the return reason\n3. Coordinate return shipping with the seller\n4. The seller evaluates the return and decides on the refund",
                'category': "returns",
                'order': 1
            },
            {
                'question': "Is communication between buyers and sellers secure?",
                'answer': "Yes! All communication happens through our integrated chat platform. Chat history is maintained for dispute resolution, and personal contact information is protected until you choose to share it.",
                'category': "security",
                'order': 2
            },
            {
                'question': "What payment methods are accepted?",
                'answer': "BIDR supports secure payment processing through PayFast and Stripe. All payments are held in escrow until successful transaction completion, protecting both buyers and sellers.",
                'category': "payments",
                'order': 2
            },
            {
                'question': "How do I verify my business as a seller?",
                'answer': "During profile completion, sellers must:\n1. Provide business registration details\n2. Submit tax information\n3. Complete business verification process\n4. Upload required documentation\nVerified sellers get a verification badge visible to buyers.",
                'category': "selling",
                'order': 2
            },
        ]
        
        # Create FAQs
        for faq_data in faqs_data:
            FAQ.objects.get_or_create(
                question=faq_data['question'],
                defaults=faq_data
            )
        self.stdout.write(f'Created {len(faqs_data)} FAQs')
        
        # Sample Blogs
        blogs_data = [
            {
                'title': 'Essential Auto Spares for a Smooth Ride',
                'description': 'Quality parts keep your car safe and running longer. Find top spares on BIDR!',
                'content': '''Is your car not performing at its best? It might be time for a parts upgrade. From brake pads to spark plugs, replacing key components at the right time can save you from costly breakdowns.

This guide covers must-have auto spares, signs of wear, and how to find top-quality parts without overspending. With BIDR making competitive pricing convenient, you get the best deals on reliable auto spares.

## Essential Auto Spares Every Driver Should Know

### 1. Brake Pads and Discs
Your safety depends on these critical components. Replace brake pads every 25,000-70,000 miles depending on your driving style.

### 2. Air Filters
A clean air filter improves fuel efficiency and engine performance. Replace every 12,000-15,000 miles.

### 3. Spark Plugs
These ignite the fuel in your engine. Replace every 30,000-100,000 miles depending on the type.

### 4. Battery
Most car batteries last 3-5 years. Watch for slow engine cranking or dim headlights.

### 5. Tyres
Check tread depth regularly and replace when worn. Good tyres are essential for safe driving.

## Why Choose BIDR for Auto Spares?

- **Competitive Bidding**: Get the best prices from multiple sellers
- **Quality Assurance**: Verified sellers and genuine parts
- **Wide Selection**: From common parts to rare components
- **Secure Transactions**: Protected payment system

Start shopping smarter for auto spares today on BIDR!''',
                'section': 'auto_transport',
                'author': admin_user,
                'tags': 'auto parts, car maintenance, vehicle spares, BIDR',
                'likes': 247,
                'views': 1250,
                'is_published': True,
                'is_featured': True,
                'image_url': 'https://example.com/images/auto-spares.jpg'
            },
            {
                'title': 'Upgrade Your Tyres & Rims Today',
                'description': 'Better performance starts with the right fit. Get top deals on BIDR!',
                'content': '''Your car's performance, safety, and appearance all depend significantly on your choice of tyres and rims. Whether you're looking for improved fuel efficiency, better handling, or a sportier look, upgrading your wheels can make a dramatic difference.

## Understanding Tyre Specifications

### Tyre Size and Type
- **All-Season Tyres**: Great for most driving conditions
- **Summer Tyres**: Maximum performance in warm weather
- **Winter Tyres**: Essential for cold and snowy conditions
- **Performance Tyres**: For sports cars and high-performance vehicles

### Reading Tyre Markings
Learn to read tyre sidewall markings like 225/45R17 to ensure you get the right fit for your vehicle.

## Choosing the Right Rims

### Material Options
- **Alloy Wheels**: Lightweight and stylish
- **Steel Wheels**: Durable and cost-effective
- **Carbon Fiber**: Ultra-lightweight for racing

### Size Considerations
Larger rims can improve handling but may reduce ride comfort. Consider your driving needs carefully.

## BIDR Advantage for Tyres & Rims

- **Compare Prices**: Multiple sellers compete for your business
- **Expert Sellers**: Knowledgeable dealers with years of experience
- **Authentic Products**: Genuine brands and quality assurance
- **Local Pickup**: Find sellers near you for easy collection

Upgrade your ride today with BIDR's extensive selection of tyres and rims!''',
                'section': 'auto_transport',
                'author': admin_user,
                'tags': 'tyres, rims, wheels, car upgrades, BIDR',
                'likes': 189,
                'views': 890,
                'is_published': True,
                'is_featured': True,
                'image_url': 'https://example.com/images/tyres-rims.jpg'
            },
            {
                'title': 'Stay Ahead with Top Electronics',
                'description': 'From gadgets to home tech, find the best deals on BIDR now!',
                'content': '''Technology moves fast, and staying current with the latest electronics doesn't have to break the bank. BIDR's electronics marketplace connects you with sellers offering competitive prices on everything from smartphones to home automation systems.

## Popular Electronics Categories on BIDR

### Mobile Devices
- **Smartphones**: Latest models and budget-friendly options
- **Tablets**: For work, entertainment, and creativity
- **Accessories**: Cases, chargers, and wireless devices

### Computing
- **Laptops**: From ultrabooks to gaming machines
- **Desktop Computers**: Custom builds and pre-configured systems
- **Components**: CPUs, GPUs, RAM, and storage

### Home Electronics
- **Smart Home**: Speakers, lights, and security systems
- **Entertainment**: TVs, sound systems, and streaming devices
- **Kitchen Appliances**: Smart refrigerators, coffee makers, and more

## Why BIDR for Electronics?

### Competitive Marketplace
Our bidding system ensures you get the best possible prices on quality electronics.

### Verified Sellers
All electronics sellers are verified for authenticity and reliability.

### Secure Transactions
Protected payments and dispute resolution give you peace of mind.

### Warranty Information
Clear warranty details and return policies from each seller.

## Smart Shopping Tips

1. **Research First**: Know market prices before bidding
2. **Check Specifications**: Ensure compatibility with your needs
3. **Read Reviews**: Learn from other buyers' experiences
4. **Ask Questions**: Contact sellers for detailed information

Join thousands of smart shoppers who save on electronics through BIDR's competitive marketplace!''',
                'section': 'electronics',
                'author': admin_user,
                'tags': 'electronics, gadgets, smartphones, laptops, BIDR',
                'likes': 156,
                'views': 720,
                'is_published': True,
                'is_featured': False,
                'image_url': 'https://example.com/images/electronics.jpg'
            }
        ]
        
        # Create Blogs
        for blog_data in blogs_data:
            Blog.objects.get_or_create(
                title=blog_data['title'],
                defaults=blog_data
            )
        self.stdout.write(f'Created {len(blogs_data)} blog posts')
        
        # Sample Policies
        policies_data = [
            {
                'title': 'Privacy Policy',
                'policy_type': 'privacy',
                'content': '''# Privacy Policy

**Effective Date**: January 1, 2024
**Version**: 1.0

## Information We Collect

BIDR collects information you provide directly to us, such as when you create an account, make a purchase, or contact us for support.

### Personal Information
- Name and contact information
- Payment and billing information
- Communications with us
- Profile information

### Automatically Collected Information
- Device information and identifiers
- Usage data and analytics
- Location information (with permission)
- Cookies and similar technologies

## How We Use Your Information

We use the information we collect to:
- Provide, maintain, and improve our services
- Process transactions and send related information
- Send you technical notices and support messages
- Respond to your comments and questions
- Monitor and analyze trends and usage

## Information Sharing

We may share your information in the following circumstances:
- With your consent
- To comply with legal obligations
- To protect rights, property, and safety
- In connection with business transfers

## Data Security

We implement appropriate security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.

## Your Rights

Depending on your location, you may have certain rights regarding your personal information:
- Access to your data
- Correction of inaccurate data
- Deletion of your data
- Data portability
- Objection to processing

## Contact Us

If you have questions about this Privacy Policy, please contact us at privacy@bidr.com.''',
                'version': '1.0',
                'effective_date': date.today()
            },
            {
                'title': 'Terms of Service',
                'policy_type': 'terms',
                'content': '''# Terms of Service

**Effective Date**: January 1, 2024
**Version**: 1.0

## Acceptance of Terms

By accessing and using BIDR, you accept and agree to be bound by the terms and provision of this agreement.

## Use of the Service

### Eligibility
You must be at least 18 years old to use BIDR services.

### Account Registration
- Provide accurate and complete information
- Maintain the security of your account
- Accept responsibility for all activities under your account

### Prohibited Uses
- Illegal or unauthorized activities
- Fraudulent transactions
- Harassment or abuse of other users
- Intellectual property infringement

## Marketplace Rules

### For Buyers
- Make legitimate purchase requests
- Pay for accepted bids promptly
- Provide accurate delivery information
- Treat sellers with respect

### For Sellers
- List genuine products and services
- Honor accepted bids
- Provide accurate descriptions
- Ship items promptly and safely

## Payment Terms

- All transactions are processed securely
- Payments are held in escrow until completion
- Fees apply as outlined in our fee schedule
- Refunds processed according to our return policy

## Dispute Resolution

- Initial resolution through our support system
- Escalation to mediation if necessary
- Binding arbitration for unresolved disputes
- Legal action as a last resort

## Limitation of Liability

BIDR's liability is limited to the maximum extent permitted by law. We are not responsible for indirect, incidental, or consequential damages.

## Termination

We reserve the right to terminate accounts that violate these terms or applicable laws.

## Contact Information

For questions about these terms, contact us at legal@bidr.com.''',
                'version': '1.0',
                'effective_date': date.today()
            },
            {
                'title': 'Return Policy',
                'policy_type': 'return',
                'content': '''# Return Policy

**Effective Date**: January 1, 2024
**Version**: 1.0

## Return Window

Returns must be initiated within the escrow period:
- **Vehicle Parts**: 7 days from PIN exchange
- **Electronics**: 14 days from PIN exchange
- **Custom/High-value items**: 21 days from PIN exchange

## Eligible Returns

### Items that can be returned:
- Items not as described
- Defective or damaged products
- Wrong items shipped
- Items with undisclosed damage

### Items that cannot be returned:
- Consumable products
- Personalized or custom items
- Items damaged by buyer
- Products past return window

## Return Process

1. **Initiate Return**: Contact seller through BIDR platform
2. **Document Issues**: Provide photos and detailed description
3. **Seller Response**: Seller has 48 hours to respond
4. **Return Authorization**: If approved, seller provides return instructions
5. **Ship Back**: Package securely and use trackable shipping
6. **Inspection**: Seller inspects returned item
7. **Refund**: If accepted, refund processed within 5 business days

## Return Shipping

- **Seller's Error**: Seller pays return shipping
- **Buyer's Choice**: Buyer pays return shipping
- **Defective Items**: Seller pays return shipping

## Refund Processing

- Refunds processed to original payment method
- Processing time: 3-5 business days
- Partial refunds may apply for damaged returns

## Dispute Escalation

If seller denies legitimate return:
1. Contact BIDR support
2. Provide evidence and documentation
3. BIDR mediates resolution
4. Final decision binding

## Contact Support

For return assistance: returns@bidr.com''',
                'version': '1.0',
                'effective_date': date.today()
            }
        ]
        
        # Create Policies
        for policy_data in policies_data:
            Policy.objects.get_or_create(
                policy_type=policy_data['policy_type'],
                defaults=policy_data
            )
        self.stdout.write(f'Created {len(policies_data)} policies')
        
        self.stdout.write(self.style.SUCCESS('Successfully populated sample data!'))
        self.stdout.write('You can now access:')
        self.stdout.write('- FAQs via: /api/faqs/')
        self.stdout.write('- Blogs via: /api/blogs/')
        self.stdout.write('- Policies via: /api/policies/')
        self.stdout.write('- Contact form via: /api/contact/')
        self.stdout.write('- Newsletter signup via: /api/newsletter/')
        self.stdout.write('- Support tickets via: /api/tickets/')
