#!/bin/bash

# Create dir structure
mkdir -p ~/bin/calprbb

# Create python venv and add needed deps
python -m venv venv ; source venv/bin/activate
pip install bs4 icalendar datetime beautifulsoup4 requests

deactivate
