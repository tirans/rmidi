import asyncio
from typing import Optional
from PyQt6.QtWidgets import (
    QMainWindow, QWidget, QVBoxLayout, QHBoxLayout, 
    QStatusBar, QMessageBox, QSplitter, QPushButton
)
from PyQt6.QtCore import Qt, QTimer

from ..api_client import ApiClient
from .patch_panel import PatchPanel
from .device_panel import DevicePanel
from ..models import Patch

class MainWindow(QMainWindow):
    """Main application window"""

    def __init__(self, server_url: str = "http://localhost:7777"):
        super().__init__()
        self.server_url = server_url
        self.api_client = ApiClient(server_url)
        self.selected_patch: Optional[Patch] = None
        self.selected_midi_out_port: Optional[str] = None
        self.selected_sequencer_port: Optional[str] = None
        self.selected_midi_channel: int = 1

        # Set up the UI
        self.initUI()

        # Set up a timer to load data after the UI is shown
        QTimer.singleShot(100, self.load_data)

    def initUI(self):
        """Initialize the UI components"""
        # Set window properties
        self.setWindowTitle("MIDI Patch Selection")
        self.setMinimumSize(800, 600)

        # Create central widget and layout
        central_widget = QWidget()
        self.setCentralWidget(central_widget)

        main_layout = QVBoxLayout()
        central_widget.setLayout(main_layout)

        # Create a splitter for resizable panels
        splitter = QSplitter(Qt.Orientation.Vertical)
        main_layout.addWidget(splitter)

        # Device panel (top)
        self.device_panel = DevicePanel()
        splitter.addWidget(self.device_panel)

        # Connect device panel signals
        self.device_panel.midi_out_port_changed.connect(self.on_midi_out_port_changed)
        self.device_panel.sequencer_port_changed.connect(self.on_sequencer_port_changed)
        self.device_panel.midi_channel_changed.connect(self.on_midi_channel_changed)

        # Patch panel (bottom)
        self.patch_panel = PatchPanel()
        splitter.addWidget(self.patch_panel)

        # Connect patch panel signals
        self.patch_panel.patch_selected.connect(self.on_patch_selected)

        # Set initial splitter sizes (30% top, 70% bottom)
        splitter.setSizes([300, 700])

        # Add Send button
        self.send_button = QPushButton("Send MIDI")
        self.send_button.setToolTip("Send the selected patch to the MIDI device")
        self.send_button.clicked.connect(self.on_send_button_clicked)
        main_layout.addWidget(self.send_button)

        # Status bar
        self.status_bar = QStatusBar()
        self.setStatusBar(self.status_bar)
        self.status_bar.showMessage("Ready")

    async def _load_data_async(self):
        """Load data from the server asynchronously"""
        # Show loading message
        self.status_bar.showMessage("Loading data from server...")

        # Load devices
        devices = await self.api_client.get_devices()
        self.device_panel.set_devices(devices)

        # Load MIDI ports
        midi_ports = await self.api_client.get_midi_ports()
        self.device_panel.set_midi_ports(midi_ports)

        # Load patches
        patches = await self.api_client.get_patches()
        self.patch_panel.set_patches(patches)

        # Update status
        self.status_bar.showMessage(f"Loaded {len(devices)} devices and {len(patches)} patches")

    def load_data(self):
        """Load data from the server"""
        # Create a new event loop for the async operation
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)

        try:
            # Run the async load operation
            loop.run_until_complete(self._load_data_async())
        except Exception as e:
            self.show_error(f"Error loading data: {str(e)}")
        finally:
            loop.close()

    def on_patch_selected(self, patch: Patch):
        """Handle patch selection"""
        self.selected_patch = patch
        self.status_bar.showMessage(f"Selected patch: {patch.preset_name}")

    def on_midi_out_port_changed(self, port_name: str):
        """Handle MIDI out port selection change"""
        self.selected_midi_out_port = port_name
        self.status_bar.showMessage(f"Selected MIDI out port: {port_name}")

    def on_sequencer_port_changed(self, port_name: str):
        """Handle sequencer port selection change"""
        self.selected_sequencer_port = port_name if port_name else None
        if port_name:
            self.status_bar.showMessage(f"Selected sequencer port: {port_name}")
        else:
            self.status_bar.showMessage("No sequencer port selected")

    def on_midi_channel_changed(self, channel: int):
        """Handle MIDI channel selection change"""
        self.selected_midi_channel = channel
        self.status_bar.showMessage(f"Selected MIDI channel: {channel}")

    def on_send_button_clicked(self):
        """Handle Send button click"""
        if not self.selected_patch:
            self.show_error("No patch selected. Please select a patch first.")
            return

        if not self.selected_midi_out_port:
            self.show_error("No MIDI output port selected. Please select a MIDI output port first.")
            return

        self.send_preset()

    async def _send_preset_async(self):
        """Send the selected preset to the server asynchronously"""
        if not self.selected_patch or not self.selected_midi_out_port:
            return

        self.status_bar.showMessage(f"Sending preset: {self.selected_patch.preset_name}...")

        try:
            result = await self.api_client.send_preset(
                self.selected_patch.preset_name,
                self.selected_midi_out_port,
                self.selected_midi_channel,
                self.selected_sequencer_port
            )

            if result.get("status") == "success":
                self.status_bar.showMessage(f"Preset sent: {self.selected_patch.preset_name}")
            else:
                self.show_error(f"Error sending preset: {result.get('message', 'Unknown error')}")

        except Exception as e:
            self.show_error(f"Error sending preset: {str(e)}")

    def send_preset(self):
        """Send the selected preset to the server"""
        # Use the current event loop if it exists and is running, otherwise create a new one
        try:
            loop = asyncio.get_event_loop()
            if loop.is_closed():
                loop = asyncio.new_event_loop()
                asyncio.set_event_loop(loop)
        except RuntimeError:
            # No event loop in current thread
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)

        try:
            # Run the async send operation
            loop.run_until_complete(self._send_preset_async())
        except Exception as e:
            self.show_error(f"Error sending preset: {str(e)}")
        # Don't close the loop here, as it might be used by other operations

    def show_error(self, message: str):
        """Show an error message dialog"""
        self.status_bar.showMessage(f"Error: {message}")

        error_box = QMessageBox()
        error_box.setIcon(QMessageBox.Icon.Critical)
        error_box.setWindowTitle("Error")
        error_box.setText(message)
        error_box.exec()

    def closeEvent(self, event):
        """Handle window close event"""
        # Create a new event loop for the async operation
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)

        try:
            # Close the API client
            loop.run_until_complete(self.api_client.close())
        except Exception as e:
            print(f"Error closing API client: {str(e)}")
        finally:
            loop.close()

        # Accept the close event
        event.accept()
