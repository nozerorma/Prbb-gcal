#!/usr/bin/env bash
# run.sh - Run the PRBB calendar parser

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if venv exists
if [ ! -d "$PROJECT_ROOT/src/venv" ]; then
    echo "❌ Virtual environment not found!"
    echo "Run ./setup.sh first"
    exit 1
fi

# Check if CA bundle exists
if [ ! -f "$PROJECT_ROOT/src/custom_ca_bundle.pem" ]; then
    echo "⚠️  Custom CA bundle not found!"
    echo "Building it now..."
    "$PROJECT_ROOT/scripts/build_ca_bundle.sh"
fi

echo "Running PRBB calendar parser..."
echo ""

# Activate venv, run parser, deactivate
cd "$PROJECT_ROOT/src"
source venv/bin/activate
python main.py
EXIT_CODE=$?
deactivate

if [ $EXIT_CODE -eq 0 ]; then
    echo ""
    echo "✓ Parser completed successfully"
else
    echo ""
    echo "❌ Parser failed with exit code $EXIT_CODE"
    echo ""
    echo "Common issues:"
    echo "  - Google auth expired: Run 'gcloud auth application-default login'"
    echo "  - Check calprbb.log for details"
fi

exit $EXIT_CODE
