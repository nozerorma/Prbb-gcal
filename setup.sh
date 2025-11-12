#!/usr/bin/env bash
# setup.sh - Complete setup for calprbb project

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "Setting up calprbb project"
echo "=========================================="
echo ""

# 1. Create virtual environment
echo "Step 1: Creating virtual environment..."
if [ ! -d "$PROJECT_ROOT/src/venv" ]; then
    cd "$PROJECT_ROOT/src"
    python3 -m venv venv
    source venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
    deactivate
    echo "✓ Virtual environment created"
else
    echo "✓ Virtual environment already exists"
fi
echo ""

# 2. Build custom CA bundle
echo "Step 2: Building custom CA bundle..."
cd "$PROJECT_ROOT"
"$PROJECT_ROOT/scripts/build_ca_bundle.sh"
echo ""

# 3. Run tests
echo "Step 3: Testing SSL fix..."
"$PROJECT_ROOT/scripts/test_ssl_fix.sh"
echo ""

# 4. Check Google Cloud SDK (optional, for deployment)
echo "Step 4: Checking Google Cloud SDK (optional)..."
if command -v gcloud &> /dev/null; then
    GCLOUD_VERSION=$(gcloud version --format="value(version)" 2>/dev/null || echo "unknown")
    echo "✓ Google Cloud SDK found (version: $GCLOUD_VERSION)"
    
    # Check if project is set
    CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null || echo "")
    if [ -n "$CURRENT_PROJECT" ]; then
        echo "✓ Project configured: $CURRENT_PROJECT"
    else
        echo "⚠ No project configured"
        echo "  Run: ./scripts/install_gcloud.sh to configure"
    fi
else
    echo "⚠ Google Cloud SDK not found (only needed for cloud deployment)"
    echo "  To install and configure, run:"
    echo "    ./scripts/install_gcloud.sh"
fi
echo ""

echo "=========================================="
echo "✓ Setup complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Run the parser:"
echo "     ./run.sh"
echo ""
echo "  2. For Google Cloud deployment:"
echo "     a. Install/configure Google Cloud SDK (if not done):"
echo "        ./scripts/install_gcloud.sh"
echo "     b. Authenticate (if credentials expired):"
echo "        gcloud auth application-default login"
echo "     c. Deploy:"
echo "        ./scripts/deploy_gcloud.sh"
echo ""
