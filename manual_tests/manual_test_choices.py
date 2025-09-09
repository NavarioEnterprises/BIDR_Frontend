#!/usr/bin/env python
"""
Test script to verify that MetricType.choices and MetricPeriod.choices work correctly.
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


def test_choices():
    """Test that choices attributes work correctly"""
    print("Testing MetricType.choices:")
    print(MetricType.choices)
    
    print("\nTesting MetricPeriod.choices:")
    print(MetricPeriod.choices)
    
    # Test that we can access individual choices
    print("\nAccessing individual choices:")
    print(f"MetricType.COUNTER: {MetricType.COUNTER}")
    print(f"MetricPeriod.DAY: {MetricPeriod.DAY}")
    
    # Test that we can iterate over choices
    print("\nIterating over MetricType.choices:")
    for value, label in MetricType.choices:
        print(f"  Value: {value}, Label: {label}")
    
    print("\nIterating over MetricPeriod.choices:")
    for value, label in MetricPeriod.choices:
        print(f"  Value: {value}, Label: {label}")


if __name__ == "__main__":
    test_choices()