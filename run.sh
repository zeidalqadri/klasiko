#!/bin/bash
# Convenience script to run klasiko with the virtual environment

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Run klasiko.py with the virtual environment's Python
"$SCRIPT_DIR/venv/bin/python" "$SCRIPT_DIR/klasiko.py" "$@"
