#!/usr/bin/env bash
# test_ssl_fix.sh - Verify the SSL fix works correctly

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SRC_DIR="$PROJECT_ROOT/src"

echo "============================================"
echo "Testing SSL Certificate Fix for www.prbb.org"
echo "============================================"
echo ""

# Check if custom bundle exists
if [ ! -f "$SRC_DIR/custom_ca_bundle.pem" ]; then
    echo "✗ Custom CA bundle not found!"
    echo "  Run: ./scripts/build_ca_bundle.sh"
    exit 1
fi

echo "✓ Custom CA bundle found: $SRC_DIR/custom_ca_bundle.pem"
CERT_COUNT=$(grep -c 'BEGIN CERTIFICATE' "$SRC_DIR/custom_ca_bundle.pem")
echo "  Certificates in bundle: $CERT_COUNT"
echo ""

# Test with curl
echo "Testing HTTPS connection with curl..."
if curl -I --cacert "$SRC_DIR/custom_ca_bundle.pem" https://www.prbb.org/agenda-evento.php?id=1821 >/dev/null 2>&1; then
    echo "✓ curl verification successful"
else
    echo "✗ curl verification failed"
    exit 1
fi
echo ""

# Test with Python
echo "Testing HTTPS connection with Python requests..."
cd "$SRC_DIR"

# Activate venv if it exists
if [ -d "venv" ]; then
    source venv/bin/activate
fi

python3 - <<'EOF'
import sys
import logging

# Suppress warnings for cleaner output
logging.basicConfig(level=logging.ERROR)

# Import our module
try:
    from main import fetch_url_content, CA_BUNDLE
except ImportError as e:
    print(f"✗ Import failed: {e}")
    print("  Make sure you've run: pip install -r requirements.txt")
    sys.exit(1)

# Test fetch
test_url = "https://www.prbb.org/agenda-evento.php?id=1821"
content = fetch_url_content(test_url)

if content and len(content) > 0:
    print(f"✓ Python requests verification successful")
    print(f"  Fetched {len(content):,} bytes from {test_url}")
else:
    print("✗ Python requests verification failed")
    sys.exit(1)
EOF

if [ $? -eq 0 ]; then
    echo ""
    echo "============================================"
    echo "✓ All SSL verification tests passed!"
    echo "============================================"
    echo ""
    echo "The fix is working correctly. You can now:"
    echo "  - Run the parser: python src/main.py"
    echo "  - Deploy to cloud: ./scripts/deploy_gcloud.sh"
else
    echo ""
    echo "✗ Tests failed"
    exit 1
fi
