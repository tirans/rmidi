import os
import json
import logging
import time
import concurrent.futures
from typing import Dict, List, Optional, Tuple, Any

# Get logger
logger = logging.getLogger(__name__)

def optimized_scan_devices(devices_folder: str, json_cache: Dict, cache_timeout: int = 3600) -> Tuple[Dict[str, Dict], List[str], Dict[str, List[str]]]:
    """
    Optimized version of scan_devices that uses parallel processing to load JSON files
    
    Args:
        devices_folder: Path to the devices folder
        json_cache: Dictionary to use for caching
        cache_timeout: Cache timeout in seconds
        
    Returns:
        Tuple of (devices, manufacturers, device_structure)
    """
    logger.info(f"Scanning devices folder with optimized scanner: {devices_folder}")
    
    # Initialize return values
    devices = {}
    manufacturers = []
    device_structure = {}
    
    # Check if devices folder exists
    if not os.path.exists(devices_folder):
        logger.warning(f"Devices folder '{devices_folder}' does not exist")
        return {}, [], {}
    
    start_time = time.time()
    
    try:
        # Get list of manufacturer directories
        manufacturers = [d for d in os.listdir(devices_folder) 
                        if os.path.isdir(os.path.join(devices_folder, d))]
        logger.info(f"Found {len(manufacturers)} manufacturer directories")
        
        # Use a thread pool to process manufacturers in parallel
        with concurrent.futures.ThreadPoolExecutor(max_workers=min(32, os.cpu_count() * 4)) as executor:
            # Submit tasks for each manufacturer
            future_to_manufacturer = {
                executor.submit(_process_manufacturer, devices_folder, manufacturer, json_cache, cache_timeout): manufacturer
                for manufacturer in manufacturers
            }
            
            # Process results as they complete
            for future in concurrent.futures.as_completed(future_to_manufacturer):
                manufacturer = future_to_manufacturer[future]
                try:
                    manufacturer_devices, manufacturer_device_structure = future.result()
                    devices.update(manufacturer_devices)
                    device_structure[manufacturer] = manufacturer_device_structure
                    logger.info(f"Processed manufacturer {manufacturer} with {len(manufacturer_device_structure)} devices")
                except Exception as e:
                    logger.error(f"Error processing manufacturer {manufacturer}: {str(e)}")
        
        scan_time = time.time() - start_time
        logger.info(f"Optimized scan completed in {scan_time:.4f} seconds, found {len(devices)} devices")
        return devices, manufacturers, device_structure
    
    except Exception as e:
        scan_time = time.time() - start_time
        logger.error(f"Error during optimized scan: {str(e)} (failed in {scan_time:.4f} seconds)")
        return {}, [], {}

def _process_manufacturer(devices_folder: str, manufacturer: str, json_cache: Dict, cache_timeout: int) -> Tuple[Dict[str, Dict], List[str]]:
    """
    Process a single manufacturer directory
    
    Args:
        devices_folder: Path to the devices folder
        manufacturer: Name of the manufacturer
        json_cache: Dictionary to use for caching
        cache_timeout: Cache timeout in seconds
        
    Returns:
        Tuple of (devices, device_structure)
    """
    manufacturer_path = os.path.join(devices_folder, manufacturer)
    logger.debug(f"Processing manufacturer directory: {manufacturer}")
    
    # Initialize return values
    manufacturer_devices = {}
    manufacturer_device_structure = []
    
    try:
        # Get list of files and directories in manufacturer directory
        items = os.listdir(manufacturer_path)
        
        # Process device directories and JSON files
        device_dirs = [d for d in items if os.path.isdir(os.path.join(manufacturer_path, d)) and d != 'community']
        json_files = [f for f in items if f.endswith('.json')]
        
        logger.debug(f"Found {len(device_dirs)} device directories and {len(json_files)} JSON files in {manufacturer} directory")
        
        # Use a thread pool to process JSON files in parallel
        with concurrent.futures.ThreadPoolExecutor(max_workers=min(32, os.cpu_count() * 2)) as executor:
            # Submit tasks for each JSON file
            future_to_file = {
                executor.submit(_load_json_file, os.path.join(manufacturer_path, filename), json_cache, cache_timeout): filename
                for filename in json_files
            }
            
            # Process results as they complete
            for future in concurrent.futures.as_completed(future_to_file):
                filename = future_to_file[future]
                try:
                    device_data = future.result()
                    
                    # Check if device has device_info with a name
                    if device_data and 'device_info' in device_data and 'name' in device_data['device_info']:
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
                        manufacturer_devices[device_name] = device_data
                        manufacturer_device_structure.append(device_name)
                        
                        logger.debug(f"Loaded device: {device_name} from manufacturer {manufacturer}")
                    else:
                        logger.warning(f"Device file '{filename}' does not have a device_info.name field")
                except Exception as e:
                    logger.error(f"Error processing JSON file {filename}: {str(e)}")
        
        # Process device directories
        for device_dir in device_dirs:
            device_path = os.path.join(manufacturer_path, device_dir)
            logger.debug(f"Processing device directory: {device_dir}")
            
            # Get JSON files in device directory
            device_json_files = [f for f in os.listdir(device_path) if f.endswith('.json')]
            
            if device_json_files:
                # Use a thread pool to process JSON files in parallel
                with concurrent.futures.ThreadPoolExecutor(max_workers=min(32, os.cpu_count() * 2)) as executor:
                    # Submit tasks for each JSON file
                    future_to_file = {
                        executor.submit(_load_json_file, os.path.join(device_path, filename), json_cache, cache_timeout): filename
                        for filename in device_json_files
                    }
                    
                    # Process results as they complete
                    for future in concurrent.futures.as_completed(future_to_file):
                        filename = future_to_file[future]
                        try:
                            device_data = future.result()
                            
                            # Check if device has device_info with a name
                            if device_data and 'device_info' in device_data and 'name' in device_data['device_info']:
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
                                manufacturer_devices[device_name] = device_data
                                manufacturer_device_structure.append(device_name)
                                
                                logger.debug(f"Loaded device: {device_name} from manufacturer {manufacturer}")
                            else:
                                logger.warning(f"Device file '{filename}' does not have a device_info.name field")
                        except Exception as e:
                            logger.error(f"Error processing JSON file {filename}: {str(e)}")
        
        return manufacturer_devices, manufacturer_device_structure
    
    except Exception as e:
        logger.error(f"Error processing manufacturer {manufacturer}: {str(e)}")
        return {}, []

def _load_json_file(file_path: str, json_cache: Dict, cache_timeout: int) -> Dict:
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