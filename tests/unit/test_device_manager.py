import unittest
import os
import json
import tempfile
from unittest.mock import patch, mock_open, MagicMock
from device_manager import DeviceManager
from models import Device, Patch

class TestDeviceManager(unittest.TestCase):
    """Test cases for the DeviceManager class"""

    def setUp(self):
        """Set up test fixtures"""
        self.device_manager = DeviceManager()

        # Sample device data for testing
        self.sample_device = {
            "name": "Test Device",
            "midi_ports": {"main": "Port 1"},
            "midi_channels": {"main": 1},
            "presets": [
                {
                    "preset_name": "Test Preset 1",
                    "category": "Test Category",
                    "characters": ["Warm", "Bright"],
                    "cc_0": 0,
                    "pgm": 1
                },
                {
                    "preset_name": "Test Preset 2",
                    "category": "Another Category",
                    "characters": ["Dark", "Deep"],
                    "cc_0": 0,
                    "pgm": 2
                }
            ]
        }

    @patch('os.path.exists')
    @patch('os.listdir')
    @patch('builtins.open', new_callable=mock_open)
    @patch('json.load')
    def test_scan_devices(self, mock_json_load, mock_file_open, mock_listdir, mock_exists):
        """Test scanning devices from JSON files"""
        # Mock os.path.exists to return True
        mock_exists.return_value = True

        # Mock os.listdir to return a list of JSON files
        mock_listdir.return_value = ['device1.json', 'device2.json', 'not_a_json_file.txt']

        # Mock json.load to return different device data for each call
        device1 = self.sample_device.copy()
        device2 = self.sample_device.copy()
        device2['name'] = "Test Device 2"
        mock_json_load.side_effect = [device1, device2]

        # Call the method under test
        result = self.device_manager.scan_devices()

        # Verify the results
        self.assertEqual(len(result), 2)  # Two JSON files should be processed
        self.assertIn('Test Device', result)  # The device name should be in the result

        # Verify that open was called for each JSON file
        self.assertEqual(mock_file_open.call_count, 2)

        # Verify that json.load was called for each file
        self.assertEqual(mock_json_load.call_count, 2)

    @patch('os.path.exists')
    def test_scan_devices_folder_not_exists(self, mock_exists):
        """Test scanning devices when the folder doesn't exist"""
        # Mock os.path.exists to return False
        mock_exists.return_value = False

        # Call the method under test
        result = self.device_manager.scan_devices()

        # Verify the results
        self.assertEqual(len(result), 0)  # No devices should be found

    @patch('os.path.exists')
    @patch('os.listdir')
    @patch('builtins.open', new_callable=mock_open)
    @patch('json.load')
    def test_scan_devices_json_error(self, mock_json_load, mock_file_open, mock_listdir, mock_exists):
        """Test scanning devices with JSON parsing errors"""
        # Mock os.path.exists to return True
        mock_exists.return_value = True

        # Mock os.listdir to return a list of JSON files
        mock_listdir.return_value = ['device1.json']

        # Mock json.load to raise a JSONDecodeError
        mock_json_load.side_effect = json.JSONDecodeError("Test error", "", 0)

        # Call the method under test
        result = self.device_manager.scan_devices()

        # Verify the results
        self.assertEqual(len(result), 0)  # No devices should be found due to the error

    def test_get_device_by_name(self):
        """Test getting a device by name"""
        # Set up the device manager with a sample device
        self.device_manager.devices = {'Test Device': self.sample_device}

        # Test getting an existing device
        device = self.device_manager.get_device_by_name('Test Device')
        self.assertEqual(device, self.sample_device)

        # Test getting a non-existent device
        device = self.device_manager.get_device_by_name('Non-existent Device')
        self.assertIsNone(device)

    def test_get_all_devices(self):
        """Test getting all devices"""
        # Set up the device manager with a sample device
        self.device_manager.devices = {'Test Device': self.sample_device}

        # Call the method under test
        devices = self.device_manager.get_all_devices()

        # Verify the results
        self.assertEqual(len(devices), 1)
        self.assertIsInstance(devices[0], Device)
        self.assertEqual(devices[0].name, 'Test Device')
        self.assertEqual(devices[0].midi_port, {'main': 'Port 1'})
        self.assertEqual(devices[0].midi_channel, {'main': 1})

    def test_get_all_patches(self):
        """Test getting all patches"""
        # Set up the device manager with a sample device
        self.device_manager.devices = {'Test Device': self.sample_device}

        # Call the method under test
        patches = self.device_manager.get_all_patches()

        # Verify the results
        self.assertEqual(len(patches), 2)
        self.assertIsInstance(patches[0], Patch)
        self.assertEqual(patches[0].preset_name, 'Test Preset 1')
        self.assertEqual(patches[0].category, 'Test Category')
        self.assertEqual(patches[0].characters, ['Warm', 'Bright'])
        self.assertEqual(patches[0].cc_0, 0)
        self.assertEqual(patches[0].pgm, 1)

        self.assertEqual(patches[1].preset_name, 'Test Preset 2')
        self.assertEqual(patches[1].category, 'Another Category')

    def test_get_patch_by_name(self):
        """Test getting a patch by name"""
        # Set up the device manager with a sample device
        self.device_manager.devices = {'Test Device': self.sample_device}

        # Test getting an existing patch
        patch = self.device_manager.get_patch_by_name('Test Preset 1')
        self.assertEqual(patch['preset_name'], 'Test Preset 1')
        self.assertEqual(patch['category'], 'Test Category')

        # Test getting a non-existent patch
        patch = self.device_manager.get_patch_by_name('Non-existent Patch')
        self.assertIsNone(patch)

if __name__ == "__main__":
    unittest.main()
