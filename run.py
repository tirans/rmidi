#!/usr/bin/env python3
"""
Simple entry point to run the R2MIDI server
"""
import os
import sys

# Add the project root to the Python path
project_root = os.path.dirname(__file__)
sys.path.insert(0, project_root)

if __name__ == '__main__':
    # Import server as a package
    import server
    server.main.main()
