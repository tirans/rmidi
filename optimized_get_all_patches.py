import os
import json
import logging
import time
from typing import Dict, List, Optional, Any
from models import Patch

# Get logger
logger = logging.getLogger(__name__)


def _load_json_file(file_path: str, json_cache: Dict, cache_timeout: int = 300) -> Dict:
    """
    Load a JSON file with caching to improve performance

    Args:
        file_path: Path to the JSON file
        json_cache: Dictionary to use for caching
        cache_timeout: Cache timeout in seconds

    Returns:
        Dictionary containing the JSON data
    """
    # Check if file exists
    if not os.path.exists(file_path):
        logger.warning(f"JSON file not found: {file_path}")
        return {}

    # Check if file is in cache and not expired
    if file_path in json_cache:
        timestamp, data = json_cache[file_path]
        if time.time() - timestamp < cache_timeout:
            logger.debug(f"Using cached JSON data for {file_path}")
            return data

    # Load file and update cache
    try:
        start_time = time.time()
        with open(file_path, 'r') as f:
            data = json.load(f)
        load_time = time.time() - start_time
        logger.debug(f"Loaded JSON file {file_path} in {load_time:.4f} seconds")

        # Update cache
        json_cache[file_path] = (time.time(), data)
        return data
    except json.JSONDecodeError as e:
        logger.error(f"Invalid JSON in file {file_path}: {str(e)}")
        return {}
    except Exception as e:
        logger.error(f"Error loading JSON file {file_path}: {str(e)}")
        return {}


def get_all_patches(devices_folder: str, devices: Dict, device_structure: Dict,
                    device_name: Optional[str] = None, community_folder: Optional[str] = None,
                    manufacturer: Optional[str] = None, json_cache: Dict = None) -> List[Patch]:
    """
    Get all patches from all devices or a specific device with optimized JSON loading

    Args:
        devices_folder: Path to the devices folder
        devices: Dictionary of device name to device data
        device_structure: Dictionary of manufacturer to list of devices
        device_name: Optional name of the device to get patches from
        community_folder: Optional name of the community folder to get patches from
        manufacturer: Optional name of the manufacturer to filter devices by
        json_cache: Optional cache dictionary for JSON files

    Returns:
        A list of Patch objects
    """
    if json_cache is None:
        json_cache = {}

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
            for name, data in devices.items():
                if name == device_name and data.get('manufacturer') == manufacturer:
                    devices_to_process = {name: data}
                    break

            if not devices_to_process:
                logger.warning(f"Device not found: {device_name} for manufacturer: {manufacturer}")
                return []

        # If only manufacturer is provided
        elif manufacturer:
            # Filter devices by manufacturer
            for name, data in devices.items():
                if data.get('manufacturer') == manufacturer:
                    devices_to_process[name] = data

            if not devices_to_process:
                logger.warning(f"No devices found for manufacturer: {manufacturer}")
                return []

        # If only device_name is provided
        elif device_name:
            if device_name in devices:
                devices_to_process = {device_name: devices[device_name]}
            else:
                logger.warning(f"Device not found: {device_name}")
                return []
        else:
            devices_to_process = devices

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
                    devices_folder,
                    manufacturer,
                    'community',
                    f"{community_folder}.json"
                )

                if os.path.exists(community_path):
                    try:
                        # Use cached JSON loading
                        community_data = _load_json_file(community_path, json_cache)

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
                                logger.error(
                                    f"Error creating Patch object for community preset {preset_name}: {str(e)}")
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