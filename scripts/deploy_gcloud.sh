#!/bin/bash

set -euo pipefail

echo "Preparing deployment..."

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

echo "✓ Deployment complete!"
echo ""
echo "The custom CA bundle (custom_ca_bundle.pem) has been included in the deployment."
echo "This fixes SSL verification for www.prbb.org"
