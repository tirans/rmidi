"""Pytest configuration"""
import sys
import os
import pytest

# Add the project root to Python path
sys.path.insert(0, os.path.abspath(os.path.dirname(__file__)))


def pytest_configure(config):
    """Configure pytest for Qt testing"""
    # Set Qt platform for headless testing
    if not os.environ.get('DISPLAY'):
        os.environ.setdefault('QT_QPA_PLATFORM', 'offscreen')
