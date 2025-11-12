#!/usr/bin/env bash
# setup.sh - Complete setup for calprbb project

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "Setting up calprbb project"
echo "=========================================="
echo ""

# 1. Create virtual environment
echo "Step 1: Creating virtual environment..."
if [ ! -d "$PROJECT_ROOT/src/venv" ]; then
    "$SCRIPT_DIR/venv_create.sh"
    echo "✓ Virtual environment created"
else
    echo "✓ Virtual environment already exists"
fi
echo ""

# 2. Build custom CA bundle
echo "Step 2: Building custom CA bundle..."
"$SCRIPT_DIR/build_ca_bundle.sh"
echo ""

# 3. Run tests
echo "Step 3: Testing SSL fix..."
"$SCRIPT_DIR/test_ssl_fix.sh"
echo ""

echo "=========================================="
echo "✓ Setup complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Activate the virtual environment:"
echo "     cd src && source venv/bin/activate"
echo ""
echo "  2. Run the parser:"
echo "     python main.py"
echo ""
echo "  3. Deploy to Google Cloud (optional):"
echo "     ./scripts/deploy_gcloud.sh"
echo ""
