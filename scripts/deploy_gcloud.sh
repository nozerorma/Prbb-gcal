#!/bin/bash

set -euo pipefail

echo "=========================================="
echo "Google Cloud Functions Deployment"
echo "=========================================="
echo ""

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo "✗ Error: Google Cloud SDK (gcloud) is not installed"
    echo ""
    echo "To install and configure, run:"
    echo "  ./scripts/install_gcloud.sh"
    echo ""
    exit 1
fi

# Check if authenticated
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null | grep -q "@"; then
    echo "✗ Error: Not authenticated with Google Cloud"
    echo ""
    echo "Run: gcloud auth login"
    echo "Or run: ./scripts/install_gcloud.sh"
    echo ""
    exit 1
fi

# Check if project is set
CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null || echo "")
if [ -z "$CURRENT_PROJECT" ]; then
    echo "✗ Error: No Google Cloud project is configured"
    echo ""
    echo "This error occurs when you see:"
    echo "  'Project was not passed and could not be determined from the environment'"
    echo ""
    echo "Fix it by running ONE of these:"
    echo "  1. gcloud config set project YOUR_PROJECT_ID"
    echo "  2. export GOOGLE_CLOUD_PROJECT=YOUR_PROJECT_ID"
    echo "  3. ./scripts/install_gcloud.sh (guided setup)"
    echo ""
    exit 1
fi

echo "✓ Authenticated and using project: $CURRENT_PROJECT"
echo ""

# Build custom CA bundle before deploying
echo "Building custom CA bundle..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/build_ca_bundle.sh"

echo "Deploying to Google Cloud Functions..."
gcloud functions deploy parsePRBBAgenda \
--runtime python310 \
--trigger-http \
--entry-point main \
--allow-unauthenticated \
--source src \
--timeout=3600s \
--gen2

echo ""
echo "=========================================="
echo "✓ Deployment complete!"
echo "=========================================="
echo ""
echo "Project: $CURRENT_PROJECT"
echo "Function: parsePRBBAgenda"
echo ""
echo "The custom CA bundle (custom_ca_bundle.pem) has been included in the deployment."
echo "This fixes SSL verification for www.prbb.org"
echo ""
