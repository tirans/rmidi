import unittest
import os
import socket
import asyncio
from unittest.mock import patch, MagicMock, AsyncMock
from fastapi.testclient import TestClient
import pytest

# Import the app and functions from main.py
from main import app, is_port_in_use, find_available_port, launch_ui_client_with_delay

class TestMainFunctions(unittest.TestCase):
    """Test cases for the utility functions in main.py"""

    @patch('socket.socket')
    def test_is_port_in_use_true(self, mock_socket):
        """Test is_port_in_use when port is in use"""
        # Set up mock to return 0 (success) for connect_ex
        mock_socket_instance = MagicMock()
        mock_socket_instance.connect_ex.return_value = 0
        mock_socket.return_value.__enter__.return_value = mock_socket_instance

        # Call the function
        result = is_port_in_use(8000)

        # Verify the result
        self.assertTrue(result)
        mock_socket_instance.connect_ex.assert_called_once_with(('localhost', 8000))

    @patch('socket.socket')
    def test_is_port_in_use_false(self, mock_socket):
        """Test is_port_in_use when port is not in use"""
        # Set up mock to return non-zero (failure) for connect_ex
        mock_socket_instance = MagicMock()
        mock_socket_instance.connect_ex.return_value = 1
        mock_socket.return_value.__enter__.return_value = mock_socket_instance

        # Call the function
        result = is_port_in_use(8000)

        # Verify the result
        self.assertFalse(result)
        mock_socket_instance.connect_ex.assert_called_once_with(('localhost', 8000))

    @patch('main.is_port_in_use')
    def test_find_available_port_first_available(self, mock_is_port_in_use):
        """Test find_available_port when the first port is available"""
        # Set up mock to return False (port not in use)
        mock_is_port_in_use.return_value = False

        # Call the function
        result = find_available_port(8000)

        # Verify the result
        self.assertEqual(result, 8000)
        mock_is_port_in_use.assert_called_once_with(8000)

    @patch('main.is_port_in_use')
    def test_find_available_port_second_available(self, mock_is_port_in_use):
        """Test find_available_port when the second port is available"""
        # Set up mock to return True for first port, False for second port
        mock_is_port_in_use.side_effect = [True, False]

        # Call the function
        result = find_available_port(8000)

        # Verify the result
        self.assertEqual(result, 8001)
        self.assertEqual(mock_is_port_in_use.call_count, 2)
        mock_is_port_in_use.assert_any_call(8000)
        mock_is_port_in_use.assert_any_call(8001)

    @patch('main.is_port_in_use')
    def test_find_available_port_none_available(self, mock_is_port_in_use):
        """Test find_available_port when no ports are available"""
        # Set up mock to always return True (all ports in use)
        mock_is_port_in_use.return_value = True

        # Call the function
        result = find_available_port(8000, max_attempts=3)

        # Verify the result
        self.assertEqual(result, 8000)  # Should return the original port
        self.assertEqual(mock_is_port_in_use.call_count, 3)

    @patch('time.sleep')
    @patch('main.ui_launcher')
    def test_launch_ui_client_with_delay_success(self, mock_ui_launcher, mock_sleep):
        """Test launching UI client with delay when ui_launcher is initialized"""
        # Set up mock ui_launcher
        mock_ui_launcher.launch_client.return_value = True

        # Call the function
        launch_ui_client_with_delay(1)

        # Verify the results
        mock_sleep.assert_called_once_with(1)
        mock_ui_launcher.launch_client.assert_called_once()

    @patch('time.sleep')
    @patch('main.ui_launcher')
    def test_launch_ui_client_with_delay_failure(self, mock_ui_launcher, mock_sleep):
        """Test launching UI client with delay when ui_launcher is initialized but launch fails"""
        # Set up mock ui_launcher
        mock_ui_launcher.launch_client.return_value = False

        # Call the function
        launch_ui_client_with_delay(1)

        # Verify the results
        mock_sleep.assert_called_once_with(1)
        mock_ui_launcher.launch_client.assert_called_once()

    @patch('time.sleep')
    @patch('main.ui_launcher', None)
    def test_launch_ui_client_with_delay_no_launcher(self, mock_sleep):
        """Test launching UI client with delay when ui_launcher is not initialized"""
        # Call the function
        launch_ui_client_with_delay(1)

        # Verify the results
        mock_sleep.assert_called_once_with(1)
        # No launcher to call, so no assertions on launcher methods

@pytest.mark.asyncio
class TestFastAPIEndpoints:
    """Test cases for the FastAPI endpoints"""

    @pytest.fixture
    def client(self):
        """Create a TestClient for the FastAPI app"""
        return TestClient(app)

    @patch('device_manager.DeviceManager.get_all_devices')
    def test_get_devices(self, mock_get_all_devices, client):
        """Test the GET /devices endpoint"""
        # Set up mock to return a list of Device objects
        from models import Device
        mock_get_all_devices.return_value = [
            Device(name="Device 1", midi_port={"main": "Port 1"}, midi_channel={"main": 1}),
            Device(name="Device 2", midi_port={"main": "Port 2"}, midi_channel={"main": 2})
        ]

        # Make the request
        response = client.get("/devices")

        # Verify the response
        assert response.status_code == 200
        assert len(response.json()) == 2
        assert response.json()[0]["name"] == "Device 1"
        assert response.json()[1]["name"] == "Device 2"

    @patch('device_manager.DeviceManager.get_all_devices')
    def test_get_devices_error(self, mock_get_all_devices, client):
        """Test the GET /devices endpoint with an error"""
        # Set up mock to raise an exception
        mock_get_all_devices.side_effect = Exception("Test error")

        # Make the request
        response = client.get("/devices")

        # Verify the response
        assert response.status_code == 500
        assert "error" in response.json()["detail"].lower()

    @patch('device_manager.DeviceManager.get_all_patches')
    def test_get_patches(self, mock_get_all_patches, client):
        """Test the GET /patches endpoint"""
        # Set up mock to return a list of Patch objects
        from models import Patch
        mock_get_all_patches.return_value = [
            Patch(preset_name="Patch 1", category="Category 1"),
            Patch(preset_name="Patch 2", category="Category 2")
        ]

        # Make the request
        response = client.get("/patches")

        # Verify the response
        assert response.status_code == 200
        assert len(response.json()) == 2
        assert response.json()[0]["preset_name"] == "Patch 1"
        assert response.json()[1]["preset_name"] == "Patch 2"

    @patch('device_manager.DeviceManager.get_all_patches')
    def test_get_patches_error(self, mock_get_all_patches, client):
        """Test the GET /patches endpoint with an error"""
        # Set up mock to raise an exception
        mock_get_all_patches.side_effect = Exception("Test error")

        # Make the request
        response = client.get("/patches")

        # Verify the response
        assert response.status_code == 500
        assert "error" in response.json()["detail"].lower()

    @patch('midi_utils.MidiUtils.get_midi_ports')
    def test_get_midi_ports(self, mock_get_midi_ports, client):
        """Test the GET /midi_port endpoint"""
        # Set up mock to return a dictionary of ports
        mock_get_midi_ports.return_value = {
            "in": ["In Port 1", "In Port 2"],
            "out": ["Out Port 1", "Out Port 2"]
        }

        # Make the request
        response = client.get("/midi_port")

        # Verify the response
        assert response.status_code == 200
        assert len(response.json()["in"]) == 2
        assert len(response.json()["out"]) == 2
        assert response.json()["in"][0] == "In Port 1"
        assert response.json()["out"][0] == "Out Port 1"

    @patch('midi_utils.MidiUtils.get_midi_ports')
    def test_get_midi_ports_error(self, mock_get_midi_ports, client):
        """Test the GET /midi_port endpoint with an error"""
        # Set up mock to raise an exception
        mock_get_midi_ports.side_effect = Exception("Test error")

        # Make the request
        response = client.get("/midi_port")

        # Verify the response
        assert response.status_code == 500
        assert "error" in response.json()["detail"].lower()

    @patch('device_manager.DeviceManager.get_patch_by_name')
    @patch('midi_utils.MidiUtils.asend_midi_command')
    def test_send_preset(self, mock_asend_midi_command, mock_get_patch_by_name, client):
        """Test the POST /preset endpoint"""
        # Set up mocks
        mock_get_patch_by_name.return_value = {
            "preset_name": "Test Preset",
            "cc_0": 0,
            "pgm": 1
        }
        mock_asend_midi_command.return_value = (True, "Command executed successfully")

        # Make the request
        response = client.post("/preset", json={
            "preset_name": "Test Preset",
            "midi_port": "Port 1",
            "midi_channel": 1
        })

        # Verify the response
        assert response.status_code == 200
        assert response.json()["status"] == "success"

        # Verify that the mocks were called with the correct arguments
        mock_get_patch_by_name.assert_called_once_with("Test Preset")
        mock_asend_midi_command.assert_called_once()
        # Check that the command contains the correct values
        command_arg = mock_asend_midi_command.call_args[0][0]
        assert "Port 1" in command_arg
        assert "ch 1" in command_arg
        assert "cc 0 0" in command_arg
        assert "pc 1" in command_arg

    @patch('device_manager.DeviceManager.get_patch_by_name')
    def test_send_preset_not_found(self, mock_get_patch_by_name, client):
        """Test the POST /preset endpoint when the preset is not found"""
        # Set up mock to return None (preset not found)
        mock_get_patch_by_name.return_value = None

        # Make the request
        response = client.post("/preset", json={
            "preset_name": "Non-existent Preset",
            "midi_port": "Port 1",
            "midi_channel": 1
        })

        # Verify the response
        assert response.status_code == 404
        assert "not found" in response.json()["detail"].lower()

    @patch('device_manager.DeviceManager.get_patch_by_name')
    def test_send_preset_missing_values(self, mock_get_patch_by_name, client):
        """Test the POST /preset endpoint when cc_0 or pgm values are missing"""
        # Set up mock to return a patch without cc_0 or pgm
        mock_get_patch_by_name.return_value = {
            "preset_name": "Test Preset"
        }

        # Make the request
        response = client.post("/preset", json={
            "preset_name": "Test Preset",
            "midi_port": "Port 1",
            "midi_channel": 1
        })

        # Verify the response
        assert response.status_code == 400
        assert "missing" in response.json()["detail"].lower()

if __name__ == "__main__":
    unittest.main()
