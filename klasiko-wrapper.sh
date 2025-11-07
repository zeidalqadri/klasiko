#!/bin/bash

# Klasiko Wrapper Script
# Activates virtual environment and runs klasiko.py with all arguments
# This allows klasiko to be run from anywhere on the system

SCRIPT_DIR="/Users/zeidalqadri/Desktop/klasiko"
VENV_PATH="$SCRIPT_DIR/venv"
PYTHON_SCRIPT="$SCRIPT_DIR/klasiko.py"

# Activate virtual environment
source "$VENV_PATH/bin/activate"

# Run klasiko.py with all arguments passed to this script
python "$PYTHON_SCRIPT" "$@"

# Capture exit code
exit_code=$?

# Deactivate virtual environment
deactivate

# Exit with same code as Python script
exit $exit_code
