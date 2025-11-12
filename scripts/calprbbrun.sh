#!/bin/bash

# Activate the virtual environment
source ../src/venv/bin/activate

# Execute the Python script
python3 ../src/main.py &> ../calprbb.log
# Deactivate the virtual environment
deactivate
