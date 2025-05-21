import unittest
import json
from unittest.mock import patch, MagicMock, AsyncMock
import pytest
import httpx
from midi_patch_client.api_client import ApiClient
from midi_patch_client.models import Device, Patch

@pytest.mark.asyncio
class TestApiClient:
    """Test cases for the ApiClient class"""

    @pytest.fixture
    def api_client(self):
        """Create an ApiClient instance for testing"""
        return ApiClient(base_url="http://test-server:8000")

    @patch('httpx.AsyncClient')
    async def test_init(self, mock_async_client):
        """Test initialization of ApiClient"""
        # Create an ApiClient
        client = ApiClient(base_url="http://test-server:8000")
        
        # Verify the client was initialized correctly
        assert client.base_url == "http://test-server:8000"
        mock_async_client.assert_called_once_with(
            base_url="http://test-server:8000", 
            timeout=10.0
        )

    @patch('httpx.AsyncClient.get')
    async def test_get_devices(self, mock_get, api_client):
        """Test getting devices from the server"""
        # Set up mock response
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = [
            {"name": "Device 1", "midi_port": {"main": "Port 1"}, "midi_channel": {"main": 1}},
            {"name": "Device 2", "midi_port": {"main": "Port 2"}, "midi_channel": {"main": 2}}
        ]
        mock_get.return_value = mock_response
        
        # Call the method under test
        devices = await api_client.get_devices()
        
        # Verify the results
        assert len(devices) == 2
        assert isinstance(devices[0], Device)
        assert devices[0].name == "Device 1"
        assert devices[0].midi_port == {"main": "Port 1"}
        assert devices[0].midi_channel == {"main": 1}
        
        # Verify that the API was called correctly
        mock_get.assert_called_once_with("/devices")
        mock_response.raise_for_status.assert_called_once()

    @patch('httpx.AsyncClient.get')
    async def test_get_devices_error(self, mock_get, api_client):
        """Test getting devices with an error"""
        # Set up mock to raise an exception
        mock_get.side_effect = httpx.HTTPError("Test error")
        
        # Call the method under test
        devices = await api_client.get_devices()
        
        # Verify the results
        assert len(devices) == 0
        
        # Verify that the API was called correctly
        mock_get.assert_called_once_with("/devices")

    @patch('httpx.AsyncClient.get')
    async def test_get_patches(self, mock_get, api_client):
        """Test getting patches from the server"""
        # Set up mock response
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = [
            {"preset_name": "Patch 1", "category": "Category 1"},
            {"preset_name": "Patch 2", "category": "Category 2"}
        ]
        mock_get.return_value = mock_response
        
        # Call the method under test
        patches = await api_client.get_patches()
        
        # Verify the results
        assert len(patches) == 2
        assert isinstance(patches[0], Patch)
        assert patches[0].preset_name == "Patch 1"
        assert patches[0].category == "Category 1"
        
        # Verify that the API was called correctly
        mock_get.assert_called_once_with("/patches")
        mock_response.raise_for_status.assert_called_once()

    @patch('httpx.AsyncClient.get')
    async def test_get_patches_error(self, mock_get, api_client):
        """Test getting patches with an error"""
        # Set up mock to raise an exception
        mock_get.side_effect = httpx.HTTPError("Test error")
        
        # Call the method under test
        patches = await api_client.get_patches()
        
        # Verify the results
        assert len(patches) == 0
        
        # Verify that the API was called correctly
        mock_get.assert_called_once_with("/patches")

    @patch('httpx.AsyncClient.get')
    async def test_get_midi_ports(self, mock_get, api_client):
        """Test getting MIDI ports from the server"""
        # Set up mock response
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "in": ["In Port 1", "In Port 2"],
            "out": ["Out Port 1", "Out Port 2"]
        }
        mock_get.return_value = mock_response
        
        # Call the method under test
        ports = await api_client.get_midi_ports()
        
        # Verify the results
        assert len(ports["in"]) == 2
        assert len(ports["out"]) == 2
        assert ports["in"][0] == "In Port 1"
        assert ports["out"][0] == "Out Port 1"
        
        # Verify that the API was called correctly
        mock_get.assert_called_once_with("/midi_port")
        mock_response.raise_for_status.assert_called_once()

    @patch('httpx.AsyncClient.get')
    async def test_get_midi_ports_error(self, mock_get, api_client):
        """Test getting MIDI ports with an error"""
        # Set up mock to raise an exception
        mock_get.side_effect = httpx.HTTPError("Test error")
        
        # Call the method under test
        ports = await api_client.get_midi_ports()
        
        # Verify the results
        assert len(ports["in"]) == 0
        assert len(ports["out"]) == 0
        
        # Verify that the API was called correctly
        mock_get.assert_called_once_with("/midi_port")

    @patch('httpx.AsyncClient.post')
    async def test_send_preset(self, mock_post, api_client):
        """Test sending a preset to the server"""
        # Set up mock response
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {"status": "success", "message": "Command executed successfully"}
        mock_post.return_value = mock_response
        
        # Call the method under test
        result = await api_client.send_preset(
            preset_name="Test Preset",
            midi_port="Port 1",
            midi_channel=1
        )
        
        # Verify the results
        assert result["status"] == "success"
        assert result["message"] == "Command executed successfully"
        
        # Verify that the API was called correctly
        mock_post.assert_called_once_with(
            "/preset", 
            json={
                "preset_name": "Test Preset",
                "midi_port": "Port 1",
                "midi_channel": 1
            }
        )
        mock_response.raise_for_status.assert_called_once()

    @patch('httpx.AsyncClient.post')
    async def test_send_preset_with_sequencer(self, mock_post, api_client):
        """Test sending a preset with a sequencer port"""
        # Set up mock response
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {"status": "success", "message": "Command executed successfully"}
        mock_post.return_value = mock_response
        
        # Call the method under test
        result = await api_client.send_preset(
            preset_name="Test Preset",
            midi_port="Port 1",
            midi_channel=1,
            sequencer_port="Sequencer Port"
        )
        
        # Verify the results
        assert result["status"] == "success"
        assert result["message"] == "Command executed successfully"
        
        # Verify that the API was called correctly
        mock_post.assert_called_once_with(
            "/preset", 
            json={
                "preset_name": "Test Preset",
                "midi_port": "Port 1",
                "midi_channel": 1,
                "sequencer_port": "Sequencer Port"
            }
        )
        mock_response.raise_for_status.assert_called_once()

    @patch('httpx.AsyncClient.post')
    async def test_send_preset_error(self, mock_post, api_client):
        """Test sending a preset with an error"""
        # Set up mock to raise an exception with a response
        mock_response = MagicMock()
        mock_response.json.return_value = {"detail": "Test error"}
        mock_error = httpx.HTTPError("Test error")
        mock_error.response = mock_response
        mock_post.side_effect = mock_error
        
        # Call the method under test
        result = await api_client.send_preset(
            preset_name="Test Preset",
            midi_port="Port 1",
            midi_channel=1
        )
        
        # Verify the results
        assert result["status"] == "error"
        assert result["message"] == "Test error"
        
        # Verify that the API was called correctly
        mock_post.assert_called_once()

    @patch('httpx.AsyncClient.post')
    async def test_send_preset_error_no_json(self, mock_post, api_client):
        """Test sending a preset with an error that doesn't have JSON response"""
        # Set up mock to raise an exception without a valid JSON response
        mock_response = MagicMock()
        mock_response.json.side_effect = json.JSONDecodeError("Test error", "", 0)
        mock_error = httpx.HTTPError("Test error")
        mock_error.response = mock_response
        mock_post.side_effect = mock_error
        
        # Call the method under test
        result = await api_client.send_preset(
            preset_name="Test Preset",
            midi_port="Port 1",
            midi_channel=1
        )
        
        # Verify the results
        assert result["status"] == "error"
        assert "Test error" in result["message"]
        
        # Verify that the API was called correctly
        mock_post.assert_called_once()

    @patch('httpx.AsyncClient.aclose')
    async def test_close(self, mock_aclose, api_client):
        """Test closing the API client"""
        # Call the method under test
        await api_client.close()
        
        # Verify that aclose was called
        mock_aclose.assert_called_once()