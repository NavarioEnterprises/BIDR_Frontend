# Generated manually to handle ForeignKey to UUIDField conversion
import uuid
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('product_requests', '0003_productrequest_auth_user_uid_and_more'),
    ]

    operations = [
        # Step 1: Remove indexes that reference the old fields
        migrations.RemoveIndex(
            model_name='requestmessage',
            name='product_req_sender__742078_idx',
        ),
        migrations.RemoveIndex(
            model_name='requestwatchlist',
            name='product_req_user_id_6898b0_idx',
        ),
        
        # Step 2: Remove unique constraints that reference old fields
        migrations.AlterUniqueTogether(
            name='requestwatchlist',
            unique_together=set(),  # Remove the unique constraint temporarily
        ),
        
        # Step 3: Remove the old ForeignKey fields
        migrations.RemoveField(
            model_name='requestmessage',
            name='sender',
        ),
        migrations.RemoveField(
            model_name='requestwatchlist',
            name='user',
        ),
        
        # Step 4: Add new UUID fields with default values
        migrations.AddField(
            model_name='requestmessage',
            name='sender_id',
            field=models.UUIDField(
                help_text='UUID of the message sender from authentication service',
                null=True,  # Allow null initially to avoid constraint issues
                blank=True,
            ),
        ),
        migrations.AddField(
            model_name='requestwatchlist',
            name='user_id',
            field=models.UUIDField(
                help_text='UUID of the user from authentication service',
                null=True,  # Allow null initially
                blank=True,
            ),
        ),
        
        # Step 5: Alter existing fields to UUID (for ProductRequest and Order)
        migrations.AlterField(
            model_name='productrequest',
            name='buyer_id',
            field=models.UUIDField(
                help_text='UUID of the buyer from authentication service',
                null=True,  # Make nullable to avoid constraint issues during transition
                blank=True,
            ),
        ),
        migrations.AlterField(
            model_name='order',
            name='buyer_id',
            field=models.UUIDField(
                help_text='UUID of the buyer from authentication service',
                null=True,
                blank=True,
            ),
        ),
        migrations.AlterField(
            model_name='order',
            name='seller_id',
            field=models.UUIDField(
                help_text='UUID of the seller from authentication service',
                null=True,
                blank=True,
            ),
        ),
        
        # Step 6: Add back the unique constraints and indexes for the new fields
        migrations.AlterUniqueTogether(
            name='requestwatchlist',
            unique_together={('request', 'user_id')},
        ),
        
        # Step 7: Add indexes for the new UUID fields
        migrations.AddIndex(
            model_name='requestmessage',
            index=models.Index(fields=['sender_id'], name='product_req_sender__uuid_idx'),
        ),
        migrations.AddIndex(
            model_name='requestwatchlist',
            index=models.Index(fields=['user_id', 'created_at'], name='product_req_user_id_uuid_idx'),
        ),
        
        # Update other indexes to reflect UUID changes
        migrations.RenameIndex(
            model_name='productrequest',
            new_name='product_req_buyer_uuid_idx',
            old_name='product_req_buyer_i_a82346_idx',
        ),
        migrations.RenameIndex(
            model_name='order',
            new_name='orders_buyer_uuid_idx',
            old_name='orders_buyer_i_ca4401_idx',
        ),
        migrations.RenameIndex(
            model_name='order',
            new_name='orders_seller_uuid_idx',
            old_name='orders_seller__7a6b96_idx',
        ),
    ]
