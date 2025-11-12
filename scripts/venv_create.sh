#!/bin/bash
mkdir -p ../src/venv
# Create python venv and add needed deps
python -m venv ../src/venv ; source ../src/venv/bin/activate
\pip install -r ../src/requirements.txt

deactivate
