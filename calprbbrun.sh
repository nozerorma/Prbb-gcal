#!/bin/bash

# Activate the virtual environment
source ~/bin/calprbb/venv/bin/activate

# Execute the Python script
python ~/bin/calprbb/calprbb.py &> ~/bin/calprbb/calprbb.log
# Deactivate the virtual environment
deactivate
