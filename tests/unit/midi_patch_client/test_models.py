import unittest
from midi_patch_client.models import Device, Patch, UIState

class TestClientModels(unittest.TestCase):
    """Test cases for the client-side models"""

    def test_device_model(self):
        """Test the Device model"""
        # Test with minimal required fields
        device = Device(name="Test Device")
        self.assertEqual(device.name, "Test Device")
        self.assertEqual(device.manufacturer, "")
        self.assertIsNone(device.midi_port)
        self.assertIsNone(device.midi_channel)
        self.assertIsNone(device.community_folders)

        # Test with all fields
        device = Device(
            name="Test Device",
            manufacturer="Test Manufacturer",
            midi_port={"IN": "Port 1", "OUT": "Port 2"},
            midi_channel={"IN": 1, "OUT": 2},
            community_folders=["folder1", "folder2"]
        )
        self.assertEqual(device.name, "Test Device")
        self.assertEqual(device.manufacturer, "Test Manufacturer")
        self.assertEqual(device.midi_port, {"IN": "Port 1", "OUT": "Port 2"})
        self.assertEqual(device.midi_channel, {"IN": 1, "OUT": 2})
        self.assertEqual(device.community_folders, ["folder1", "folder2"])

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
        self.assertIsNone(patch.source)

        # Test with all fields
        patch = Patch(
            preset_name="Test Preset",
            category="Test Category",
            characters=["Warm", "Bright"],
            sendmidi_command="sendmidi dev 'Port 1' ch 1 cc 0 0 pc 0",
            cc_0=0,
            pgm=0,
            source="default"
        )
        self.assertEqual(patch.preset_name, "Test Preset")
        self.assertEqual(patch.category, "Test Category")
        self.assertEqual(patch.characters, ["Warm", "Bright"])
        self.assertEqual(patch.sendmidi_command, "sendmidi dev 'Port 1' ch 1 cc 0 0 pc 0")
        self.assertEqual(patch.cc_0, 0)
        self.assertEqual(patch.pgm, 0)
        self.assertEqual(patch.source, "default")

    def test_patch_get_display_name(self):
        """Test the get_display_name method of the Patch model"""
        # Test without source
        patch = Patch(preset_name="Test Preset", category="Test Category")
        self.assertEqual(patch.get_display_name(), "Test Preset (Test Category)")

        # Test with default source
        patch = Patch(preset_name="Test Preset", category="Test Category", source="default")
        self.assertEqual(patch.get_display_name(), "Test Preset (Test Category)")

        # Test with community folder source
        patch = Patch(preset_name="Test Preset", category="Test Category", source="community_folder")
        self.assertEqual(patch.get_display_name(), "Test Preset (Test Category) [community_folder]")

    def test_patch_get_details(self):
        """Test the get_details method of the Patch model"""
        # Test with minimal fields
        patch = Patch(preset_name="Test Preset", category="Test Category")
        details = patch.get_details()
        self.assertIn("Name: Test Preset", details)
        self.assertIn("Category: Test Category", details)
        self.assertNotIn("Source:", details)
        self.assertNotIn("Characters:", details)
        self.assertNotIn("CC 0:", details)

        # Test with source field
        patch = Patch(preset_name="Test Preset", category="Test Category", source="default")
        details = patch.get_details()
        self.assertIn("Name: Test Preset", details)
        self.assertIn("Category: Test Category", details)
        self.assertIn("Source: default", details)

        # Test with all fields
        patch = Patch(
            preset_name="Test Preset",
            category="Test Category",
            characters=["Warm", "Bright"],
            cc_0=0,
            pgm=1,
            source="community_folder"
        )
        details = patch.get_details()
        self.assertIn("Name: Test Preset", details)
        self.assertIn("Category: Test Category", details)
        self.assertIn("Source: community_folder", details)
        self.assertIn("Characters: Warm, Bright", details)
        self.assertIn("CC 0: 0, Program: 1", details)

    def test_ui_state_model(self):
        """Test the UIState model"""
        # Test with default values
        ui_state = UIState()
        self.assertIsNone(ui_state.manufacturer)
        self.assertIsNone(ui_state.device)
        self.assertIsNone(ui_state.community_folder)
        self.assertIsNone(ui_state.midi_in_port)
        self.assertIsNone(ui_state.midi_out_port)
        self.assertIsNone(ui_state.sequencer_port)
        self.assertIsNone(ui_state.midi_channel)
        self.assertTrue(ui_state.sync_enabled)

        # Test with all fields
        ui_state = UIState(
            manufacturer="Test Manufacturer",
            device="Test Device",
            community_folder="Test Folder",
            midi_in_port="In Port",
            midi_out_port="Out Port",
            sequencer_port="Seq Port",
            midi_channel=5,
            sync_enabled=False
        )
        self.assertEqual(ui_state.manufacturer, "Test Manufacturer")
        self.assertEqual(ui_state.device, "Test Device")
        self.assertEqual(ui_state.community_folder, "Test Folder")
        self.assertEqual(ui_state.midi_in_port, "In Port")
        self.assertEqual(ui_state.midi_out_port, "Out Port")
        self.assertEqual(ui_state.sequencer_port, "Seq Port")
        self.assertEqual(ui_state.midi_channel, 5)
        self.assertFalse(ui_state.sync_enabled)

if __name__ == "__main__":
    unittest.main()
