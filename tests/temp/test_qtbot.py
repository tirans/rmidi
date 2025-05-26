import pytest
from PyQt6.QtWidgets import QApplication, QPushButton

@pytest.mark.skip(reason="This is a temporary test that requires qtbot fixture")
def test_qtbot_works(qtbot):
    """Test that qtbot fixture works"""
    app = QApplication.instance() or QApplication([])
    button = QPushButton("Click me")
    qtbot.addWidget(button)
    assert button.text() == "Click me"
