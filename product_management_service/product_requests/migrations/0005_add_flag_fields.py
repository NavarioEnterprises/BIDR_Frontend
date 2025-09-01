# Migration to add missing flag fields to ProductRequest model

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('product_requests', '0004_convert_to_uuid_fields'),
    ]

    operations = [
        # Add the is_flagged field
        migrations.AddField(
            model_name='productrequest',
            name='is_flagged',
            field=models.BooleanField(
                default=False,
                help_text='Whether this request has been flagged by sellers'
            ),
        ),
        
        # Add the flags field
        migrations.AddField(
            model_name='productrequest',
            name='flags',
            field=models.JSONField(
                default=list,
                blank=True,
                help_text='List of flags with uid, reason, and timestamp'
            ),
        ),
    ]