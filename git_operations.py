import logging
import os
import shutil
import re
import git
from git import Repo, GitCommandError

# Configure logger
logger = logging.getLogger(__name__)

def git_sync():
    """
    Perform a git submodule sync and update for the midi-presets submodule

    This function:
    1. Runs git submodule sync from the repository root
    2. Runs git submodule update --init --recursive to update the submodule
    3. If that fails, tries more aggressive approaches including complete removal and re-cloning
    4. Logs each step of the operation

    Returns:
        Tuple of (success: bool, message: str, status_code: int)
    """
    logger.info("Starting git sync operation")

    try:
        # Get the current directory
        current_dir = os.getcwd()
        midi_presets_dir = os.path.join(current_dir, "midi-presets")

        # Open the repository
        try:
            repo = Repo(current_dir)
        except git.InvalidGitRepositoryError:
            error_msg = f"Not a valid git repository: {current_dir}"
            logger.error(error_msg)
            return False, error_msg, 500

        # Step 1: Try the standard approach first
        try:
            logger.info("Step 1: Syncing git submodule...")

            # Sync the submodule
            with repo.git.custom_environment(GIT_TERMINAL_PROMPT="0"):
                sync_output = repo.git.submodule("sync")
                logger.info(f"Git submodule sync output: {sync_output}")

                # Update the submodule
                logger.info("Updating git submodule...")
                update_output = repo.git.submodule("update", "--init", "--recursive")
                logger.info(f"Git submodule update output: {update_output}")

            # If we get here, it worked!
            logger.info("Git submodule sync completed successfully with standard approach")
            return True, "Git submodule sync completed successfully", 200

        except GitCommandError as e:
            logger.warning(f"Standard submodule update failed: {e.stderr}")
            # Continue to next approach

        # Step 2: Try with force flag
        try:
            logger.info("Step 2: Trying submodule update with force...")

            # Reset the submodule state
            with repo.git.custom_environment(GIT_TERMINAL_PROMPT="0"):
                reset_output = repo.git.submodule("deinit", "-f", "--", "midi-presets")
                logger.info(f"Git submodule deinit output: {reset_output}")

                # Re-initialize and update with force
                reinit_output = repo.git.submodule("update", "--init", "--recursive", "--force")
                logger.info(f"Git submodule force update output: {reinit_output}")

            # If we get here, it worked!
            logger.info("Git submodule sync completed successfully with force approach")
            return True, "Git submodule sync completed successfully", 200

        except GitCommandError as e:
            logger.warning(f"Force submodule update failed: {e.stderr}")
            # Continue to next approach

        # Step 3: Most aggressive approach - remove and re-clone
        logger.info("Step 3: Trying complete removal and re-initialization...")

        # First, get the submodule URL from .gitmodules
        try:
            # Get the submodule URL from the repo's configuration
            try:
                # Check if the submodule is configured
                submodule_url = None
                for submodule in repo.submodules:
                    if submodule.name == "midi-presets":
                        submodule_url = submodule.url
                        break

                # If not found in submodules, try to get it from .gitmodules file
                if not submodule_url:
                    gitmodules_path = os.path.join(current_dir, ".gitmodules")
                    if not os.path.exists(gitmodules_path):
                        raise FileNotFoundError(f".gitmodules file not found at {gitmodules_path}")

                    # Parse .gitmodules to get the URL
                    with open(gitmodules_path, 'r') as f:
                        content = f.read()
                        url_match = re.search(r'\[submodule\s+"midi-presets"\].*?\s+url\s+=\s+(.+)', content, re.DOTALL)
                        if url_match:
                            submodule_url = url_match.group(1).strip()

                if not submodule_url:
                    # Use the default URL if not found
                    submodule_url = "https://github.com/tirans/midi-presets.git"
                    logger.warning(f"Could not find midi-presets URL in configuration, using default: {submodule_url}")
                else:
                    logger.info(f"Found submodule URL: {submodule_url}")

                # Verify that the URL is the expected one
                expected_url = "https://github.com/tirans/midi-presets.git"
                if submodule_url != expected_url:
                    logger.warning(f"Submodule URL {submodule_url} doesn't match expected URL {expected_url}")
                    submodule_url = expected_url
                    logger.info(f"Using expected URL: {submodule_url}")

            except Exception as e:
                logger.warning(f"Error getting submodule URL from configuration: {str(e)}")
                # Use the default URL if there was an error
                submodule_url = "https://github.com/tirans/midi-presets.git"
                logger.info(f"Using default submodule URL: {submodule_url}")

            # Check if the midi-presets directory exists
            if os.path.exists(midi_presets_dir):
                logger.info(f"Midi-presets directory exists at: {midi_presets_dir}")

                # Check if it's a regular git repository (not a submodule)
                git_dir = os.path.join(midi_presets_dir, ".git")
                if os.path.exists(git_dir) and os.path.isdir(git_dir):
                    logger.info("Detected regular git repository instead of submodule. Converting to submodule...")

                    # Get the current commit hash to preserve it
                    try:
                        midi_repo = Repo(midi_presets_dir)
                        current_commit = midi_repo.head.commit.hexsha
                        logger.info(f"Current commit hash: {current_commit}")
                    except Exception as e:
                        logger.warning(f"Could not get current commit hash: {str(e)}")
                        current_commit = None

                    # Remove the directory but preserve the content
                    temp_dir = os.path.join(current_dir, "midi-presets-temp")
                    try:
                        # Create a temporary directory
                        if os.path.exists(temp_dir):
                            shutil.rmtree(temp_dir)

                        # Copy the content to the temporary directory
                        shutil.copytree(midi_presets_dir, temp_dir, symlinks=True)
                        logger.info(f"Copied midi-presets content to temporary directory: {temp_dir}")

                        # Remove the original directory
                        shutil.rmtree(midi_presets_dir)
                        logger.info("Successfully removed midi-presets directory")

                        # After removing the directory, we'll let the submodule init/update recreate it
                        # and then we'll restore any local changes if needed
                    except Exception as e:
                        logger.warning(f"Error during directory operations: {str(e)}")
                        # If we failed to copy/remove, try the old approach
                        try:
                            # First try git clean to remove untracked files
                            repo.git.clean("-ffdx", "--", "midi-presets")
                        except Exception as e:
                            logger.warning(f"Git clean failed, will try manual removal: {str(e)}")

                        # Then try to remove the directory manually
                        try:
                            shutil.rmtree(midi_presets_dir)
                            logger.info("Successfully removed midi-presets directory")
                        except Exception as e:
                            logger.warning(f"Error removing directory: {str(e)}")
                            # Try with os.system as a last resort
                            if os.path.exists(midi_presets_dir):
                                if os.name == 'nt':  # Windows
                                    os.system(f'rmdir /S /Q "{midi_presets_dir}"')
                                else:  # Unix/Linux/MacOS
                                    os.system(f'rm -rf "{midi_presets_dir}"')
                                logger.info("Used system command to remove midi-presets directory")
                else:
                    # It's not a regular git repository, so just remove it
                    logger.info("Removing existing midi-presets directory...")
                    try:
                        # First try git clean to remove untracked files
                        repo.git.clean("-ffdx", "--", "midi-presets")
                    except Exception as e:
                        logger.warning(f"Git clean failed, will try manual removal: {str(e)}")

                    # Then try to remove the directory manually
                    try:
                        shutil.rmtree(midi_presets_dir)
                        logger.info("Successfully removed midi-presets directory")
                    except Exception as e:
                        logger.warning(f"Error removing directory: {str(e)}")
                        # Try with os.system as a last resort
                        if os.path.exists(midi_presets_dir):
                            if os.name == 'nt':  # Windows
                                os.system(f'rmdir /S /Q "{midi_presets_dir}"')
                            else:  # Unix/Linux/MacOS
                                os.system(f'rm -rf "{midi_presets_dir}"')
                            logger.info("Used system command to remove midi-presets directory")

            # Remove from git's index
            try:
                repo.git.rm("-f", "--cached", "midi-presets")
                logger.info("Removed midi-presets from git index")
            except Exception as e:
                logger.warning(f"Error removing from git index: {str(e)}")

            # Re-initialize the submodule
            logger.info("Re-initializing the submodule...")
            with repo.git.custom_environment(GIT_TERMINAL_PROMPT="0"):
                init_output = repo.git.submodule("init")
                logger.info(f"Git submodule init output: {init_output}")

                # Clone the submodule
                logger.info(f"Cloning the submodule from {submodule_url}...")
                clone_output = repo.git.submodule("update", "--init", "--recursive")
                logger.info(f"Git submodule clone output: {clone_output}")

            # Verify the submodule was cloned successfully
            if os.path.exists(midi_presets_dir) and os.path.isdir(midi_presets_dir):
                logger.info("Git submodule sync completed successfully with complete re-initialization")

                # Check if we have a temporary directory with content to restore
                temp_dir = os.path.join(current_dir, "midi-presets-temp")
                if os.path.exists(temp_dir) and os.path.isdir(temp_dir):
                    try:
                        # Copy any files that don't exist in the submodule
                        for root, dirs, files in os.walk(temp_dir):
                            rel_path = os.path.relpath(root, temp_dir)
                            target_dir = os.path.join(midi_presets_dir, rel_path)

                            # Create target directory if it doesn't exist
                            if not os.path.exists(target_dir):
                                os.makedirs(target_dir, exist_ok=True)

                            # Copy files
                            for file in files:
                                source_file = os.path.join(root, file)
                                target_file = os.path.join(target_dir, file)

                                # Only copy if the file doesn't exist or is different
                                if not os.path.exists(target_file):
                                    shutil.copy2(source_file, target_file)

                        logger.info("Restored content from temporary directory")

                        # Clean up the temporary directory
                        shutil.rmtree(temp_dir)
                        logger.info("Removed temporary directory")
                    except Exception as e:
                        logger.warning(f"Error restoring content from temporary directory: {str(e)}")

                return True, "Git submodule sync completed successfully with complete re-initialization", 200
            else:
                raise Exception(f"Submodule directory not found after re-initialization: {midi_presets_dir}")

        except Exception as e:
            logger.error(f"Complete re-initialization failed: {str(e)}")
            return False, f"All git sync approaches failed. Last error: {str(e)}", 500

    except GitCommandError as e:
        error_msg = f"Git operation failed: {e.stderr}"
        logger.error(error_msg)
        return False, error_msg, 500
    except Exception as e:
        error_msg = f"Error during git submodule sync: {str(e)}"
        logger.error(error_msg)
        return False, error_msg, 500
