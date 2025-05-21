import unittest
from midi_patch_client.models import Device, Patch

class TestClientModels(unittest.TestCase):
    """Test cases for the client-side models"""

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

    def test_patch_get_display_name(self):
        """Test the get_display_name method of the Patch model"""
        patch = Patch(preset_name="Test Preset", category="Test Category")
        self.assertEqual(patch.get_display_name(), "Test Preset (Test Category)")

    def test_patch_get_details(self):
        """Test the get_details method of the Patch model"""
        # Test with minimal fields
        patch = Patch(preset_name="Test Preset", category="Test Category")
        details = patch.get_details()
        self.assertIn("Name: Test Preset", details)
        self.assertIn("Category: Test Category", details)
        self.assertNotIn("Characters:", details)
        self.assertNotIn("CC 0:", details)

        # Test with all fields
        patch = Patch(
            preset_name="Test Preset",
            category="Test Category",
            characters=["Warm", "Bright"],
            cc_0=0,
            pgm=1
        )
        details = patch.get_details()
        self.assertIn("Name: Test Preset", details)
        self.assertIn("Category: Test Category", details)
        self.assertIn("Characters: Warm, Bright", details)
        self.assertIn("CC 0: 0, Program: 1", details)

if __name__ == "__main__":
    unittest.main()