# RMIDI - MIDI 2.0 Patch Selection Application

RMIDI is a modern application for managing and selecting MIDI patches across various devices. It provides a user-friendly interface for musicians and producers to quickly select and send MIDI program changes to their hardware.

## Features

- **Device Management**: Automatically detects and manages MIDI devices
- **Patch Selection**: Browse and select patches/presets from your devices
- **MIDI Control**: Send program changes and bank select messages to your MIDI devices
- **Multi-Device Support**: Control multiple MIDI devices simultaneously
- **Sequencer Integration**: Optional routing to a sequencer port
- **User-Friendly Interface**: Clean, intuitive GUI for easy navigation

## Installation

### Prerequisites

- Python 3.8 or higher
- [SendMIDI](https://github.com/gbevin/SendMIDI) command-line tool
- MIDI devices connected to your computer

### Installation Steps

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/rmidi.git
   cd rmidi
   ```

2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

   Or using the pyproject.toml:
   ```bash
   pip install -e .
   ```

3. Install SendMIDI:
   - **macOS** (using Homebrew):
     ```bash
     brew install gbevin/tools/sendmidi
     ```
   - **Windows/Linux**: Download from [SendMIDI GitHub releases](https://github.com/gbevin/SendMIDI/releases)

## Configuration

### Environment Variables

Create a `.env` file in the project root with the following variables:

```
PORT=7777  # The port for the API server (default: 7777)
```

### Device Configuration

Device definitions are stored as JSON files in the `devices` folder. Each device file should follow this format:

```json
{
  "name": "Device Name",
  "midi_ports": {
    "main": "MIDI Port Name",
    "alternate": "Alternative MIDI Port Name"
  },
  "midi_channels": {
    "main": 1,
    "alternate": 2
  },
  "presets": [
    {
      "preset_name": "Preset 1",
      "category": "Category",
      "characters": ["warm", "bright"],
      "cc_0": 0,
      "pgm": 1
    },
    {
      "preset_name": "Preset 2",
      "category": "Another Category",
      "characters": ["dark", "deep"],
      "cc_0": 0,
      "pgm": 2
    }
  ]
}
```

An example device file for the Expressivee Osmose is included in the `devices` folder.

## Usage

### Starting the Application

Run the main application:

```bash
python main.py
```

This will:
1. Start the API server on the configured port (default: 7777)
2. Scan for connected MIDI devices
3. Launch the GUI client

### Using the GUI

The GUI is divided into two main panels:

#### Device Panel (Top)

- **MIDI Output Port**: Select the MIDI port to send commands to
- **MIDI Channel**: Select the MIDI channel (1-16)
- **Sequencer Port**: Optionally select a secondary port to send the same commands to (useful for recording in a DAW)

#### Patch Panel (Bottom)

- Browse patches by category
- Search for patches by name
- Select a patch to send to the device

#### Sending MIDI Commands

1. Select a MIDI output port and channel in the Device Panel
2. Select a patch in the Patch Panel
3. Click the "Send MIDI" button to send the program change to your device

### API Endpoints

The application provides a REST API that can be used by other applications:

- `GET /devices` - Get a list of all devices
- `GET /patches` - Get a list of all patches
- `GET /midi_port` - Get a list of available MIDI ports
- `POST /preset` - Send a preset to a MIDI port/channel

Example API usage with curl:

```bash
# Get all devices
curl http://localhost:7777/devices

# Get all patches
curl http://localhost:7777/patches

# Get MIDI ports
curl http://localhost:7777/midi_port

# Send a preset
curl -X POST http://localhost:7777/preset \
  -H "Content-Type: application/json" \
  -d '{"preset_name": "Preset Name", "midi_port": "MIDI Port Name", "midi_channel": 1}'
```

## Development

### Project Structure

- `main.py` - Main entry point and API server
- `device_manager.py` - Handles device scanning and management
- `midi_utils.py` - MIDI utility functions
- `models.py` - Data models
- `ui_launcher.py` - Launches the GUI client
- `midi_patch_client/` - GUI client application
  - `main.py` - Client entry point
  - `api_client.py` - Client for the API
  - `models.py` - Client-side data models
  - `ui/` - UI components
    - `main_window.py` - Main window
    - `device_panel.py` - Device selection panel
    - `patch_panel.py` - Patch selection panel

### Running Tests

To run the tests:

```bash
# Install test dependencies
pip install -e ".[test]"

# Run all tests
pytest tests/

# Run with coverage
pytest --cov=. tests/
```

## Troubleshooting

### Common Issues

1. **SendMIDI not found**
   - Ensure SendMIDI is installed and available in your PATH
   - The application will show a warning if SendMIDI is not found

2. **No MIDI devices detected**
   - Check that your MIDI devices are connected and powered on
   - Some devices may require specific drivers

3. **UI client fails to start**
   - Check the logs in the `logs` directory for error messages
   - Ensure PyQt6 is properly installed

### Logs

Logs are stored in the `logs` directory:
- `main.log` - Main application logs
- `device_manager.log` - Device manager logs
- `midi_utils.log` - MIDI utility logs
- `ui_launcher.log` - UI launcher logs
- `uvicorn.log` - Web server logs
- `all.log` - Combined logs from all components

## License

[MIT License](LICENSE)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request