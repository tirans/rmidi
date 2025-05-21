import unittest
from models import Device, Patch, PresetRequest

class TestModels(unittest.TestCase):
    """Test cases for the models module"""

    def test_device_model(self):
        """Test the Device model"""
        # Test with minimal required fields
        device = Device(name="Test Device")
        self.assertEqual(device.name, "Test Device")
        self.assertIsNone(device.midi_port)
        self.assertIsNone(device.midi_channel)

        # Test with all fields
        device = Device(
            name="Test Device",
            midi_port={"main": "Port 1"},
            midi_channel={"main": 1}
        )
        self.assertEqual(device.name, "Test Device")
        self.assertEqual(device.midi_port, {"main": "Port 1"})
        self.assertEqual(device.midi_channel, {"main": 1})

    def test_patch_model(self):
        """Test the Patch model"""
        # Test with minimal required fields
        patch = Patch(preset_name="Test Preset", category="Test Category")
        self.assertEqual(patch.preset_name, "Test Preset")
        self.assertEqual(patch.category, "Test Category")
        self.assertIsNone(patch.characters)
        self.assertIsNone(patch.sendmidi_command)
        self.assertIsNone(patch.cc_0)
        self.assertIsNone(patch.pgm)

        # Test with all fields
        patch = Patch(
            preset_name="Test Preset",
            category="Test Category",
            characters=["Warm", "Bright"],
            sendmidi_command="sendmidi dev 'Port 1' ch 1 cc 0 0 pc 0",
            cc_0=0,
            pgm=0
        )
        self.assertEqual(patch.preset_name, "Test Preset")
        self.assertEqual(patch.category, "Test Category")
        self.assertEqual(patch.characters, ["Warm", "Bright"])
        self.assertEqual(patch.sendmidi_command, "sendmidi dev 'Port 1' ch 1 cc 0 0 pc 0")
        self.assertEqual(patch.cc_0, 0)
        self.assertEqual(patch.pgm, 0)

    def test_preset_request_model(self):
        """Test the PresetRequest model"""
        # Test with minimal required fields
        preset_request = PresetRequest(
            preset_name="Test Preset",
            midi_port="Port 1",
            midi_channel=1
        )
        self.assertEqual(preset_request.preset_name, "Test Preset")
        self.assertEqual(preset_request.midi_port, "Port 1")
        self.assertEqual(preset_request.midi_channel, 1)
        self.assertIsNone(preset_request.sequencer_port)

        # Test with all fields
        preset_request = PresetRequest(
            preset_name="Test Preset",
            midi_port="Port 1",
            midi_channel=1,
            sequencer_port="Port 2"
        )
        self.assertEqual(preset_request.preset_name, "Test Preset")
        self.assertEqual(preset_request.midi_port, "Port 1")
        self.assertEqual(preset_request.midi_channel, 1)
        self.assertEqual(preset_request.sequencer_port, "Port 2")

if __name__ == "__main__":
    unittest.main()