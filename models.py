from typing import Dict, List, Optional
from pydantic import BaseModel

class Device(BaseModel):
    """Model for device information"""
    name: str
    manufacturer: str
    midi_port: Optional[Dict[str, str]] = None
    midi_channel: Optional[Dict[str, int]] = None
    community_folders: Optional[List[str]] = None

class Patch(BaseModel):
    """Model for patch information"""
    preset_name: str
    category: str
    characters: Optional[List[str]] = None
    sendmidi_command: Optional[str] = None
    cc_0: Optional[int] = None
    pgm: Optional[int] = None
    source: Optional[str] = None  # 'default' or community folder name

class PresetRequest(BaseModel):
    """Model for preset selection request"""
    preset_name: str
    midi_port: str
    midi_channel: int
    sequencer_port: Optional[str] = None

class UIState(BaseModel):
    """Model for UI state persistence"""
    manufacturer: Optional[str] = None
    device: Optional[str] = None
    community_folder: Optional[str] = None
    midi_in_port: Optional[str] = None
    midi_out_port: Optional[str] = None
    sequencer_port: Optional[str] = None
    midi_channel: Optional[int] = None
    sync_enabled: bool = True

class ManufacturerRequest(BaseModel):
    """Model for manufacturer request"""
    manufacturer: str
