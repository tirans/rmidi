import subprocess
import rtmidi
import logging
import asyncio
from typing import Dict, List, Optional, Tuple

# Get logger
logger = logging.getLogger(__name__)

class MidiUtils:
    """Utilities for MIDI port detection and command execution"""

    @staticmethod
    def get_midi_ports() -> Dict[str, List[str]]:
        """
        Get all available MIDI ports on the system
        Returns a dictionary with 'in' and 'out' keys containing lists of port names
        """
        logger.info("Getting MIDI ports...")
        try:
            midi_in = rtmidi.MidiIn()
            midi_out = rtmidi.MidiOut()

            in_ports = midi_in.get_ports()
            out_ports = midi_out.get_ports()

            logger.info(f"Found {len(in_ports)} MIDI in ports and {len(out_ports)} MIDI out ports")
            logger.debug(f"MIDI in ports: {in_ports}")
            logger.debug(f"MIDI out ports: {out_ports}")

            return {
                "in": in_ports,
                "out": out_ports
            }
        except Exception as e:
            logger.error(f"Error getting MIDI ports: {str(e)}")
            # Return empty lists as fallback
            return {"in": [], "out": []}

    @staticmethod
    def send_midi_command(command: str, sequencer_port: Optional[str] = None) -> Tuple[bool, str]:
        """
        Execute SendMIDI command and optionally send to sequencer port

        Args:
            command: The SendMIDI command to execute
            sequencer_port: Optional sequencer port to send the command to

        Returns:
            Tuple of (success, message)
        """
        logger.info(f"Executing MIDI command: {command}")
        try:
            # Execute the main command
            result = subprocess.run(
                command, 
                shell=True, 
                check=True, 
                capture_output=True, 
                text=True
            )
            logger.debug(f"Command output: {result.stdout}")

            # If sequencer port is specified, modify the command and send to that port as well
            if sequencer_port:
                logger.info(f"Sending to sequencer port: {sequencer_port}")
                try:
                    # Extract the MIDI message part from the original command
                    # For the new command format: sendmidi dev "Port Name" ch <channel> cc 0 <cc_0> pc <pgm>
                    # We need to extract everything after "dev "Port Name"" and replace the port name

                    # Find the position of the first occurrence of 'dev "'
                    dev_pos = command.find('dev "')
                    if dev_pos >= 0:
                        # Find the position of the closing quote after the port name
                        port_end_pos = command.find('"', dev_pos + 5)
                        if port_end_pos >= 0:
                            # Extract everything after the port name
                            midi_message = command[port_end_pos + 2:]
                            seq_command = f'sendmidi dev "{sequencer_port}" {midi_message}'
                            logger.info(f"Sequencer command: {seq_command}")

                            seq_result = subprocess.run(
                                seq_command, 
                                shell=True, 
                                check=True, 
                                capture_output=True, 
                                text=True
                            )
                            logger.debug(f"Sequencer command output: {seq_result.stdout}")

                            if seq_result.returncode != 0:
                                logger.error(f"Error sending to sequencer port: {seq_result.stderr}")
                                return False, f"Error sending to sequencer port: {seq_result.stderr}"
                        else:
                            logger.warning("Could not find end of port name in command")
                    else:
                        logger.warning("Could not find 'dev \"' in command")
                except Exception as e:
                    logger.error(f"Error sending to sequencer port: {str(e)}")
                    # Continue execution even if sequencer command fails
                    # Just log the error but don't fail the whole operation

            logger.info("MIDI command executed successfully")
            return True, "Command executed successfully"

        except subprocess.CalledProcessError as e:
            logger.error(f"Error executing SendMIDI command: {e.stderr}")
            return False, f"Error executing SendMIDI command: {e.stderr}"
        except Exception as e:
            logger.error(f"Unexpected error executing MIDI command: {str(e)}")
            return False, f"Unexpected error: {str(e)}"

    @staticmethod
    def is_sendmidi_installed() -> bool:
        """Check if SendMIDI is installed on the system"""
        logger.info("Checking if SendMIDI is installed...")
        try:
            result = subprocess.run(
                ["which", "sendmidi"], 
                capture_output=True, 
                text=True
            )
            is_installed = result.returncode == 0
            if is_installed:
                logger.info("SendMIDI is installed")
                logger.debug(f"SendMIDI path: {result.stdout.strip()}")
            else:
                logger.warning("SendMIDI is not installed")
            return is_installed
        except Exception as e:
            logger.error(f"Error checking if SendMIDI is installed: {str(e)}")
            return False

    @staticmethod
    async def asend_midi_command(command: str, sequencer_port: Optional[str] = None) -> Tuple[bool, str]:
        """
        Asynchronously execute SendMIDI command and optionally send to sequencer port

        This is an async wrapper around send_midi_command for use with FastAPI

        Args:
            command: The SendMIDI command to execute
            sequencer_port: Optional sequencer port to send the command to

        Returns:
            Tuple of (success, message)
        """
        logger.info(f"Executing MIDI command asynchronously: {command}")
        try:
            # Run the synchronous send_midi_command in a thread pool
            loop = asyncio.get_event_loop()
            result = await loop.run_in_executor(
                None, 
                lambda: MidiUtils.send_midi_command(command, sequencer_port)
            )
            return result
        except Exception as e:
            logger.error(f"Unexpected error in asend_midi_command: {str(e)}")
            return False, f"Unexpected error in asend_midi_command: {str(e)}"
