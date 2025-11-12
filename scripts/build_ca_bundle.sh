#!/usr/bin/env bash
# build_ca_bundle.sh - Build custom CA bundle with HARICA/GEANT intermediate
# This fixes SSL verification for www.prbb.org which has a misconfigured server
# that doesn't send the intermediate certificate chain.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SRC_DIR="$PROJECT_ROOT/src"
BUNDLE_FILE="$SRC_DIR/custom_ca_bundle.pem"

echo "Building custom CA bundle..."

# Create temp directory
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

cd "$TEMP_DIR"

# 1. Get base certifi bundle
echo "- Extracting certifi CA bundle..."
python3 -c "import certifi; print(certifi.where())" | xargs cat > base_bundle.pem

# 2. Download HARICA/GEANT intermediate CA
echo "- Downloading HARICA/GEANT TLS RSA intermediate CA..."
curl -s -o harica-geant-tls-r1.cer http://crt.harica.gr/HARICA-GEANT-TLS-R1.cer

# 3. Convert DER to PEM
echo "- Converting intermediate CA from DER to PEM..."
openssl x509 -inform DER -in harica-geant-tls-r1.cer -outform PEM -out harica-intermediate.pem

# 4. Verify the intermediate cert
echo "- Verifying intermediate CA..."
SUBJECT=$(openssl x509 -in harica-intermediate.pem -noout -subject)
ISSUER=$(openssl x509 -in harica-intermediate.pem -noout -issuer)
echo "  Subject: $SUBJECT"
echo "  Issuer: $ISSUER"

# 5. Combine bundles
echo "- Creating combined CA bundle..."
cat base_bundle.pem harica-intermediate.pem > "$BUNDLE_FILE"

CERT_COUNT=$(grep -c 'BEGIN CERTIFICATE' "$BUNDLE_FILE")
echo "✓ Custom CA bundle created: $BUNDLE_FILE"
echo "  Total certificates: $CERT_COUNT"

# 6. Test the bundle
echo "- Testing bundle with www.prbb.org..."
if curl -I --cacert "$BUNDLE_FILE" https://www.prbb.org/agenda-evento.php?id=1821 >/dev/null 2>&1; then
    echo "✓ SSL verification successful!"
else
    echo "✗ SSL verification failed"
    exit 1
fi

echo "
Custom CA bundle is ready at:
  $BUNDLE_FILE

This bundle includes:
  - All standard certifi CA certificates
  - HARICA/GEANT TLS RSA intermediate CA (for www.prbb.org)
"
