import os
import json
import logging
import subprocess
from typing import Dict, List, Optional, Tuple
from models import Device, Patch

# Get logger
logger = logging.getLogger(__name__)

class DeviceManager:
    """Handles scanning and managing device data"""

    def __init__(self, devices_folder="midi-presets/devices"):
        """Initialize the device manager with the path to the devices folder"""
        self.devices_folder = devices_folder
        self.devices = {}  # Map of device name to device data
        self.manufacturers = []  # List of manufacturer names
        self.device_structure = {}  # Map of manufacturer to list of devices

    def run_git_sync(self) -> Tuple[bool, str]:
        """
        Run git submodule sync to update the midi-presets submodule
        Returns a tuple of (success, message)
        """
        logger.info("Running git submodule sync")
        try:
            result = subprocess.run(
                ["git", "submodule", "sync"],
                capture_output=True,
                text=True,
                check=True
            )
            logger.info(f"Git submodule sync output: {result.stdout}")

            # Also run git submodule update to ensure the submodule is up to date
            update_result = subprocess.run(
                ["git", "submodule", "update", "--init", "--recursive"],
                capture_output=True,
                text=True,
                check=True
            )
            logger.info(f"Git submodule update output: {update_result.stdout}")

            return True, "Git submodule sync and update completed successfully"
        except subprocess.CalledProcessError as e:
            logger.error(f"Git submodule sync failed: {e.stderr}")
            return False, f"Git submodule sync failed: {e.stderr}"
        except Exception as e:
            logger.error(f"Error running git submodule sync: {str(e)}")
            return False, f"Error running git submodule sync: {str(e)}"

    def scan_devices(self) -> Dict[str, Dict]:
        """
        Scan devices folder for JSON files and load them into memory
        Returns a dictionary of device names to device data
        """
        logger.info(f"Scanning devices folder: {self.devices_folder}")

        # Clear existing data
        self.devices = {}
        self.manufacturers = []
        self.device_structure = {}

        # Check if devices folder exists
        if not os.path.exists(self.devices_folder):
            logger.warning(f"Devices folder '{self.devices_folder}' does not exist")
            return {}

        try:
            # Get list of manufacturer directories
            manufacturers = [d for d in os.listdir(self.devices_folder) 
                            if os.path.isdir(os.path.join(self.devices_folder, d))]
            logger.info(f"Found {len(manufacturers)} manufacturer directories")
            self.manufacturers = manufacturers

            # Process each manufacturer directory
            for manufacturer in manufacturers:
                manufacturer_path = os.path.join(self.devices_folder, manufacturer)
                logger.debug(f"Processing manufacturer directory: {manufacturer}")

                # Initialize device structure for this manufacturer
                self.device_structure[manufacturer] = []

                # Get list of files and directories in manufacturer directory
                items = os.listdir(manufacturer_path)

                # Process device directories and JSON files
                device_dirs = [d for d in items if os.path.isdir(os.path.join(manufacturer_path, d)) and d != 'community']
                json_files = [f for f in items if f.endswith('.json')]

                logger.info(f"Found {len(device_dirs)} device directories and {len(json_files)} JSON files in {manufacturer} directory")

                # Process JSON files directly in manufacturer directory
                for filename in json_files:
                    file_path = os.path.join(manufacturer_path, filename)
                    logger.debug(f"Processing device file: {filename}")

                    try:
                        with open(file_path, 'r') as f:
                            device_data = json.load(f)

                            # Check if device has device_info with a name
                            if 'device_info' in device_data and 'name' in device_data['device_info']:
                                device_name = device_data['device_info']['name']

                                # Add manufacturer information
                                device_data['manufacturer'] = manufacturer

                                # Check for community folders
                                community_path = os.path.join(manufacturer_path, 'community')
                                community_folders = []

                                if os.path.exists(community_path) and os.path.isdir(community_path):
                                    community_items = [f for f in os.listdir(community_path) 
                                                     if f.endswith('.json')]
                                    community_folders = [os.path.splitext(f)[0] for f in community_items]
                                    logger.debug(f"Found {len(community_folders)} community folders for {device_name}")

                                device_data['community_folders'] = community_folders

                                # Store the device data
                                self.devices[device_name] = device_data
                                self.device_structure[manufacturer].append(device_name)

                                logger.info(f"Loaded device: {device_name} from manufacturer {manufacturer}")
                            else:
                                logger.warning(f"Device file '{filename}' does not have a device_info.name field")
                    except json.JSONDecodeError as e:
                        logger.error(f"Invalid JSON in device file '{filename}': {str(e)}")
                    except Exception as e:
                        logger.error(f"Error loading device file '{filename}': {str(e)}")

                # Process device directories
                for device_dir in device_dirs:
                    device_dir_path = os.path.join(manufacturer_path, device_dir)
                    logger.debug(f"Processing device directory: {device_dir}")

                    # Look for JSON files in the device directory
                    device_json_files = [f for f in os.listdir(device_dir_path) if f.endswith('.json')]
                    logger.info(f"Found {len(device_json_files)} JSON files in {device_dir} directory")

                    for filename in device_json_files:
                        file_path = os.path.join(device_dir_path, filename)
                        logger.debug(f"Processing device file: {filename} in directory {device_dir}")

                        try:
                            with open(file_path, 'r') as f:
                                device_data = json.load(f)

                                # Check if device has device_info with a name
                                if 'device_info' in device_data and 'name' in device_data['device_info']:
                                    device_name = device_data['device_info']['name']

                                    # Add manufacturer information
                                    device_data['manufacturer'] = manufacturer

                                    # Check for community folders
                                    community_path = os.path.join(device_dir_path, 'community')
                                    community_folders = []

                                    if os.path.exists(community_path) and os.path.isdir(community_path):
                                        community_items = [f for f in os.listdir(community_path) 
                                                         if f.endswith('.json')]
                                        community_folders = [os.path.splitext(f)[0] for f in community_items]
                                        logger.debug(f"Found {len(community_folders)} community folders for {device_name}")

                                    device_data['community_folders'] = community_folders

                                    # Store the device data
                                    self.devices[device_name] = device_data
                                    self.device_structure[manufacturer].append(device_name)

                                    logger.info(f"Loaded device: {device_name} from manufacturer {manufacturer}")
                                else:
                                    logger.warning(f"Device file '{filename}' in directory {device_dir} does not have a device_info.name field")
                        except json.JSONDecodeError as e:
                            logger.error(f"Invalid JSON in device file '{filename}' in directory {device_dir}: {str(e)}")
                        except Exception as e:
                            logger.error(f"Error loading device file '{filename}' in directory {device_dir}: {str(e)}")

            logger.info(f"Loaded {len(self.devices)} devices from {len(self.manufacturers)} manufacturers")
            return self.devices

        except Exception as e:
            logger.error(f"Error scanning devices folder: {str(e)}")
            return self.devices

    def get_device_by_name(self, name: str) -> Optional[Dict]:
        """Get device data by name"""
        logger.debug(f"Getting device by name: {name}")
        device = self.devices.get(name)
        if device:
            logger.debug(f"Found device: {name}")
        else:
            logger.debug(f"Device not found: {name}")
        return device

    def get_manufacturers(self) -> List[str]:
        """
        Get list of all manufacturers
        Returns a list of manufacturer names
        """
        logger.info(f"Getting all manufacturers ({len(self.manufacturers)} available)")
        return self.manufacturers

    def get_devices_by_manufacturer(self, manufacturer: str) -> List[str]:
        """
        Get list of devices for a specific manufacturer
        Returns a list of device names
        """
        logger.info(f"Getting devices for manufacturer: {manufacturer}")
        return self.device_structure.get(manufacturer, [])

    def get_device_info_by_manufacturer(self, manufacturer: str) -> List[Dict]:
        """
        Get device info for a specific manufacturer
        Returns a list of dictionaries containing device_info
        """
        logger.info(f"Getting device info for manufacturer: {manufacturer}")
        result = []

        # Check if manufacturer exists
        if manufacturer not in self.manufacturers:
            logger.warning(f"Manufacturer not found: {manufacturer}")
            return result

        # Get devices for this manufacturer
        device_names = self.device_structure.get(manufacturer, [])

        # Get device info for each device
        for device_name in device_names:
            device_data = self.devices.get(device_name)
            if device_data and 'device_info' in device_data:
                result.append(device_data['device_info'])

        logger.info(f"Found {len(result)} devices for manufacturer {manufacturer}")
        return result

    def get_community_folders(self, device_name: str) -> List[str]:
        """
        Get list of community folders for a specific device
        Returns a list of folder names
        """
        logger.info(f"Getting community folders for device: {device_name}")
        device = self.devices.get(device_name)
        if device:
            return device.get('community_folders', [])
        return []

    def get_all_devices(self) -> List[Device]:
        """
        Get all devices with their MIDI ports and channels
        Returns a list of Device objects
        """
        logger.info(f"Getting all devices ({len(self.devices)} available)")
        result = []

        try:
            for name, data in self.devices.items():
                try:
                    device_info = data.get('device_info', {})
                    midi_ports = device_info.get('midi_ports', {})
                    midi_channels = device_info.get('midi_channels', {})

                    device = Device(
                        name=name,
                        manufacturer=data.get('manufacturer', ''),
                        midi_port=midi_ports,
                        midi_channel=midi_channels,
                        community_folders=data.get('community_folders', [])
                    )
                    result.append(device)
                    logger.debug(f"Added device: {name}, manufacturer: {data.get('manufacturer', '')}, "
                                f"MIDI ports: {midi_ports}, MIDI channels: {midi_channels}, "
                                f"community folders: {data.get('community_folders', [])}")
                except Exception as e:
                    logger.error(f"Error creating Device object for {name}: {str(e)}")

            logger.info(f"Returning {len(result)} devices")
            return result
        except Exception as e:
            logger.error(f"Error getting all devices: {str(e)}")
            return result

    def get_all_patches(self, device_name: Optional[str] = None, community_folder: Optional[str] = None, manufacturer: Optional[str] = None) -> List[Patch]:
        """
        Get all patches from all devices or a specific device

        Args:
            device_name: Optional name of the device to get patches from
            community_folder: Optional name of the community folder to get patches from
            manufacturer: Optional name of the manufacturer to filter devices by

        Returns:
            A list of Patch objects
        """
        if manufacturer and device_name:
            logger.info(f"Getting patches for manufacturer: {manufacturer}, device: {device_name}")
        elif manufacturer:
            logger.info(f"Getting patches for manufacturer: {manufacturer}")
        elif device_name:
            logger.info(f"Getting patches for device: {device_name}")
        else:
            logger.info("Getting all patches from all devices")

        result = []

        try:
            patch_count = 0

            # Filter devices by manufacturer and/or device_name
            devices_to_process = {}

            # If both manufacturer and device_name are provided
            if manufacturer and device_name:
                # Find the device with the matching name and manufacturer
                for name, data in self.devices.items():
                    if name == device_name and data.get('manufacturer') == manufacturer:
                        devices_to_process = {name: data}
                        break

                if not devices_to_process:
                    logger.warning(f"Device not found: {device_name} for manufacturer: {manufacturer}")
                    return []

            # If only manufacturer is provided
            elif manufacturer:
                # Filter devices by manufacturer
                for name, data in self.devices.items():
                    if data.get('manufacturer') == manufacturer:
                        devices_to_process[name] = data

                if not devices_to_process:
                    logger.warning(f"No devices found for manufacturer: {manufacturer}")
                    return []

            # If only device_name is provided
            elif device_name:
                if device_name in self.devices:
                    devices_to_process = {device_name: self.devices[device_name]}
                else:
                    logger.warning(f"Device not found: {device_name}")
                    return []
            else:
                devices_to_process = self.devices

            for device_name, device_data in devices_to_process.items():
                logger.debug(f"Processing device: {device_name}")
                manufacturer = device_data.get('manufacturer', '')

                # Process default presets
                preset_collections = device_data.get('preset_collections', {})
                for collection_name, collection_data in preset_collections.items():
                    presets = collection_data.get('presets', [])
                    logger.debug(f"Device {device_name} collection {collection_name} has {len(presets)} presets")

                    for preset in presets:
                        try:
                            patch = Patch(
                                preset_name=preset.get('preset_name', ''),
                                category=preset.get('category', ''),
                                characters=preset.get('characters', []),
                                sendmidi_command=preset.get('sendmidi_command', ''),
                                cc_0=preset.get('cc_0'),
                                pgm=preset.get('pgm'),
                                source='default'
                            )
                            result.append(patch)
                            patch_count += 1
                            logger.debug(f"Added patch: {patch.preset_name} ({patch.category})")
                        except Exception as e:
                            preset_name = preset.get('preset_name', 'unknown')
                            logger.error(f"Error creating Patch object for {preset_name}: {str(e)}")

                # Process community presets if requested
                if community_folder:
                    logger.debug(f"Processing community folder: {community_folder} for device: {device_name}")

                    # Construct path to community folder
                    community_path = os.path.join(
                        self.devices_folder, 
                        manufacturer, 
                        'community', 
                        f"{community_folder}.json"
                    )

                    if os.path.exists(community_path):
                        try:
                            with open(community_path, 'r') as f:
                                community_data = json.load(f)

                                # Process presets from community folder
                                community_presets = community_data.get('presets', [])
                                logger.debug(f"Community folder {community_folder} has {len(community_presets)} presets")

                                for preset in community_presets:
                                    try:
                                        patch = Patch(
                                            preset_name=preset.get('preset_name', ''),
                                            category=preset.get('category', ''),
                                            characters=preset.get('characters', []),
                                            sendmidi_command=preset.get('sendmidi_command', ''),
                                            cc_0=preset.get('cc_0'),
                                            pgm=preset.get('pgm'),
                                            source=community_folder
                                        )
                                        result.append(patch)
                                        patch_count += 1
                                        logger.debug(f"Added community patch: {patch.preset_name} ({patch.category})")
                                    except Exception as e:
                                        preset_name = preset.get('preset_name', 'unknown')
                                        logger.error(f"Error creating Patch object for community preset {preset_name}: {str(e)}")
                        except json.JSONDecodeError as e:
                            logger.error(f"Invalid JSON in community file '{community_path}': {str(e)}")
                        except Exception as e:
                            logger.error(f"Error loading community file '{community_path}': {str(e)}")
                    else:
                        logger.warning(f"Community folder not found: {community_path}")

            logger.info(f"Returning {patch_count} patches")
            return result
        except Exception as e:
            logger.error(f"Error getting patches: {str(e)}")
            return result

    def get_patch_by_name(self, preset_name: str) -> Optional[Dict]:
        """Get patch data by preset name"""
        for device_name, device_data in self.devices.items():
            # Check in preset collections
            preset_collections = device_data.get('preset_collections', {})
            for collection_name, collection_data in preset_collections.items():
                presets = collection_data.get('presets', [])
                for preset in presets:
                    if preset.get('preset_name') == preset_name:
                        return preset

            # Check in community folders
            manufacturer = device_data.get('manufacturer', '')
            community_folders = device_data.get('community_folders', [])

            for folder in community_folders:
                community_path = os.path.join(
                    self.devices_folder, 
                    manufacturer, 
                    'community', 
                    f"{folder}.json"
                )

                if os.path.exists(community_path):
                    try:
                        with open(community_path, 'r') as f:
                            community_data = json.load(f)
                            community_presets = community_data.get('presets', [])

                            for preset in community_presets:
                                if preset.get('preset_name') == preset_name:
                                    return preset
                    except Exception:
                        pass

        return None
