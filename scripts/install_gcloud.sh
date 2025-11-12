#!/usr/bin/env bash
# install_gcloud.sh - Install and configure Google Cloud SDK
# Based on: https://docs.cloud.google.com/sdk/docs/install?hl=es#deb

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "Google Cloud SDK Installation & Setup"
echo "=========================================="
echo ""

# Check if gcloud is already installed
if command -v gcloud &> /dev/null; then
    GCLOUD_VERSION=$(gcloud version --format="value(version)" 2>/dev/null || echo "unknown")
    echo "✓ Google Cloud SDK is already installed (version: $GCLOUD_VERSION)"
    echo ""
else
    echo "Google Cloud SDK not found. Installing..."
    echo ""
    
    # Check if running on a Debian-based system
    if ! command -v apt-get &> /dev/null; then
        echo "✗ This script is designed for Debian/Ubuntu systems."
        echo "  Please install Google Cloud SDK manually:"
        echo "  https://cloud.google.com/sdk/docs/install"
        exit 1
    fi
    
    # Install required packages
    echo "Step 1: Installing prerequisites..."
    sudo apt-get update
    sudo apt-get install -y apt-transport-https ca-certificates gnupg curl
    echo ""
    
    # Add Google Cloud SDK repository
    echo "Step 2: Adding Google Cloud SDK repository..."
    
    # Import Google Cloud public key
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
    
    # Add the gcloud SDK distribution URI as a package source
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
    echo ""
    
    # Install Google Cloud SDK
    echo "Step 3: Installing Google Cloud SDK..."
    sudo apt-get update
    sudo apt-get install -y google-cloud-cli
    echo ""
    
    echo "✓ Google Cloud SDK installed successfully!"
    echo ""
fi

# Check if user is authenticated
echo "Checking authentication status..."
if gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null | grep -q "@"; then
    ACTIVE_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null | head -n 1)
    echo "✓ Already authenticated as: $ACTIVE_ACCOUNT"
    echo ""
else
    echo "⚠ Not authenticated with Google Cloud"
    echo ""
    read -p "Do you want to authenticate now? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        gcloud auth login
        echo ""
    else
        echo "Skipping authentication. Run 'gcloud auth login' later."
        echo ""
    fi
fi

# Check if a project is set
echo "Checking project configuration..."
CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null || echo "")

if [ -n "$CURRENT_PROJECT" ]; then
    echo "✓ Current project: $CURRENT_PROJECT"
    echo ""
else
    echo "⚠ No project is currently set"
    echo ""
    
    # List available projects
    echo "Fetching available projects..."
    PROJECTS=$(gcloud projects list --format="value(projectId)" 2>/dev/null || echo "")
    
    if [ -n "$PROJECTS" ]; then
        echo "Available projects:"
        gcloud projects list --format="table(projectId,name)" 2>/dev/null || true
        echo ""
        
        read -p "Enter project ID to set as default (or press Enter to skip): " PROJECT_ID
        if [ -n "$PROJECT_ID" ]; then
            gcloud config set project "$PROJECT_ID"
            echo "✓ Project set to: $PROJECT_ID"
            echo ""
        else
            echo "⚠ No project set. You'll need to set it later with:"
            echo "  gcloud config set project YOUR_PROJECT_ID"
            echo ""
        fi
    else
        echo "⚠ No projects found or unable to list projects."
        echo "  You may need to:"
        echo "  1. Create a project at: https://console.cloud.google.com/projectcreate"
        echo "  2. Set it with: gcloud config set project YOUR_PROJECT_ID"
        echo ""
    fi
fi

# Check for application default credentials
echo "Checking application default credentials..."
if [ -f "$HOME/.config/gcloud/application_default_credentials.json" ]; then
    echo "✓ Application default credentials found"
    echo ""
else
    echo "⚠ Application default credentials not found"
    echo ""
    read -p "Do you want to set up application default credentials now? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        gcloud auth application-default login
        echo ""
    else
        echo "Skipping. Run 'gcloud auth application-default login' later."
        echo "This is required for local development with Google Cloud Storage."
        echo ""
    fi
fi

# Summary
echo "=========================================="
echo "Setup Summary"
echo "=========================================="
gcloud config list
echo ""

# Check if project is still not set
FINAL_PROJECT=$(gcloud config get-value project 2>/dev/null || echo "")
if [ -z "$FINAL_PROJECT" ]; then
    echo "⚠ WARNING: No project is configured!"
    echo ""
    echo "To fix this error from the log:"
    echo "  'Project was not passed and could not be determined from the environment'"
    echo ""
    echo "Run one of these commands:"
    echo "  1. Set a project: gcloud config set project YOUR_PROJECT_ID"
    echo "  2. Or set environment variable: export GOOGLE_CLOUD_PROJECT=YOUR_PROJECT_ID"
    echo ""
fi

echo "✓ Google Cloud SDK setup complete!"
echo ""
echo "For cloud deployment, you may also want to enable required APIs:"
echo "  gcloud services enable cloudfunctions.googleapis.com"
echo "  gcloud services enable storage-api.googleapis.com"
echo ""
