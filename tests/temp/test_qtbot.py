import pytest
from PyQt6.QtWidgets import QApplication, QPushButton


def test_qtbot_works(qtbot):
    """Test that qtbot fixture works with PyQt6"""
    # Create a simple button widget
    button = QPushButton("Click me")
    
    # Add the widget to qtbot for automatic cleanup
    qtbot.addWidget(button)
    
    # Test the widget
    assert button.text() == "Click me"
    
    # Test that we can interact with the widget
    button.setText("Clicked!")
    assert button.text() == "Clicked!"
    
    # qtbot automatically handles QApplication lifecycle
