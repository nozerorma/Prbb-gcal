#!/bin/bash

# Activate the virtual environment
source ~/bin/calprbb/src/venv/bin/activate

# Execute the Python script
python ~/bin/calprbb/src/main.py &> ~/bin/calprbb/calprbb.log
# Deactivate the virtual environment
deactivate
