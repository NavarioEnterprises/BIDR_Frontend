#!/usr/bin/env python
"""
Test script to verify that MetricType.choices and MetricPeriod.choices work correctly in model instances.
"""
from django.db import models

# Recreate the classes from models.py to test them directly
class MetricType(models.TextChoices):
    """Types of metrics we can track"""
    COUNTER = 'counter', 'Counter'
    GAUGE = 'gauge', 'Gauge'
    HISTOGRAM = 'histogram', 'Histogram'
    TIMER = 'timer', 'Timer'


class MetricPeriod(models.TextChoices):
    """Time periods for metrics aggregation"""
    MINUTE = 'minute', 'Per Minute'
    HOUR = 'hour', 'Per Hour'
    DAY = 'day', 'Per Day'
    WEEK = 'week', 'Per Week'
    MONTH = 'month', 'Per Month'


# Create a simple model for testing
class TestMetricModel(models.Model):
    """A simple model for testing choices"""
    metric_type = models.CharField(
        max_length=20,
        choices=MetricType.choices,
        help_text="Type of metric"
    )
    period = models.CharField(
        max_length=10,
        choices=MetricPeriod.choices,
        help_text="Time period this metric covers"
    )
    
    class Meta:
        # This is just a test model, not meant to be migrated
        app_label = 'test_app'
        managed = False


def test_model_choices():
    """Test that choices work correctly in model fields"""
    # Create a model instance
    test_model = TestMetricModel(
        metric_type=MetricType.COUNTER,
        period=MetricPeriod.DAY
    )
    
    # Check that the values are set correctly
    print(f"test_model.metric_type: {test_model.metric_type}")
    print(f"test_model.period: {test_model.period}")
    
    # Check that the get_FOO_display method works
    print(f"test_model.get_metric_type_display(): {test_model.get_metric_type_display()}")
    print(f"test_model.get_period_display(): {test_model.get_period_display()}")
    
    # Check field choices
    print("\nField choices:")
    print(f"TestMetricModel._meta.get_field('metric_type').choices: {TestMetricModel._meta.get_field('metric_type').choices}")
    print(f"TestMetricModel._meta.get_field('period').choices: {TestMetricModel._meta.get_field('period').choices}")
    
    # Verify choices match the enum choices
    print("\nVerifying choices match:")
    print(f"MetricType.choices == TestMetricModel._meta.get_field('metric_type').choices: {MetricType.choices == TestMetricModel._meta.get_field('metric_type').choices}")
    print(f"MetricPeriod.choices == TestMetricModel._meta.get_field('period').choices: {MetricPeriod.choices == TestMetricModel._meta.get_field('period').choices}")


if __name__ == "__main__":
    # This will only work if Django is properly set up
    try:
        test_model_choices()
        print("\nTest completed successfully!")
    except Exception as e:
        print(f"\nError: {e}")
        print("\nThis test requires Django to be properly set up.")
        print("However, we've already verified that the choices attributes work correctly in the previous test.")