# Prbb-gcal
Small script to parse PRBB Agenda and add it to an ics

## Quick Start

```bash
# Complete setup (creates venv, builds CA bundle, runs tests)
./setup.sh

# Run the parser
./run.sh
```

## How-to
1. Run `./setup.sh` to set up environment and build CA bundle
2. Run `./run.sh` to parse PRBB events
3. (Optional) Deploy to Google Cloud Functions for automatic updates
4. (Optional) Create a cron job for periodic updates

You can also subscribe to my PRBB calendar through the following link
<link>

## Setup

### 1. Complete Setup (Recommended)
```bash
./setup.sh
```

This will:
- Create virtual environment in `src/venv/`
- Install Python dependencies
- Build custom CA bundle (fixes SSL verification)
- Test the SSL configuration
- Check for Google Cloud SDK (optional)

### 2. Manual Setup

**Create Virtual Environment:**
```bash
./scripts/venv_create.sh
```

**Build Custom CA Bundle:**
The PRBB website (www.prbb.org) has a misconfigured SSL certificate that doesn't include the intermediate CA in its chain. This causes SSL verification to fail with standard Python/requests.

Build the custom CA bundle (includes HARICA/GEANT intermediate CA):
```bash
./scripts/build_ca_bundle.sh
```

This creates `src/custom_ca_bundle.pem` which the script will automatically use.

### 3. Run the Parser

**Easy way:**
```bash
./run.sh
```

### 4. Google Cloud Setup (Optional - for cloud deployment)

If you plan to deploy to Google Cloud Functions:

**Install and configure Google Cloud SDK:**
```bash
./scripts/install_gcloud.sh
```

This script will:
- Install Google Cloud SDK (if not present)
- Authenticate with your Google account
- Set up a default project
- Configure application default credentials

**Manual configuration (if needed):**
```bash
# Install gcloud CLI
# See: https://cloud.google.com/sdk/docs/install

# Authenticate
gcloud auth login

# Set project
gcloud config set project YOUR_PROJECT_ID

# Set up application default credentials
gcloud auth application-default login

# Enable required APIs
gcloud services enable cloudfunctions.googleapis.com
gcloud services enable storage-api.googleapis.com
```

**Deploy to Google Cloud:**
```bash
./scripts/deploy_gcloud.sh
```

## SSL Certificate Issue - Technical Details

**Problem**: The PRBB server only sends its leaf certificate, not the intermediate CA (GEANT TLS RSA 1 issued by HARICA). This violates TLS best practices and causes verification failures.

**Solution**: We download the missing intermediate CA and combine it with certifi's CA bundle.

**What the build script does**:
1. Extracts the base certifi CA bundle (147 standard CAs)
2. Downloads HARICA/GEANT TLS RSA intermediate CA from http://crt.harica.gr/
3. Combines them into `src/custom_ca_bundle.pem` (148 CAs total)
4. Verifies the bundle works with www.prbb.org

**Code behavior**:
- Automatically uses `custom_ca_bundle.pem` if present
- Falls back to certifi default (will fail for prbb.org)
- Can be overridden with `REQUESTS_CA_BUNDLE` environment variable

**For deployment** (Google Cloud Functions, etc.):
```bash
# Include the custom bundle in your deployment
gcloud functions deploy ... --set-env-vars REQUESTS_CA_BUNDLE=/workspace/src/custom_ca_bundle.pem
```

Or rebuild the bundle during deployment by adding to your deploy script:
```bash
./scripts/build_ca_bundle.sh
```

## Troubleshooting

### Google OAuth: "invalid_grant: Bad Request"
```
google.auth.exceptions.RefreshError: ('invalid_grant: Bad Request', {'error': 'invalid_grant', 'error_description': 'Bad Request'})
```

**This means your Google OAuth credentials have expired.**

**Solution:**
```bash
# Re-authenticate with Google Cloud
gcloud auth application-default login
```

Then run the parser again:
```bash
./run.sh
```

### SSL Certificate Verification Failed
```
ERROR: [SSL: CERTIFICATE_VERIFY_FAILED] certificate verify failed: unable to get local issuer certificate
```

**Solution**: Run `./scripts/build_ca_bundle.sh` to create the custom CA bundle.

### Custom bundle not found warning
If you see:
```
WARNING: Custom CA bundle not found. Run scripts/build_ca_bundle.sh...
```

Run the build script:
```bash
./scripts/build_ca_bundle.sh
```

### Google Cloud: "Project was not passed and could not be determined from the environment"
```
ERROR: (gcloud.functions.deploy) INVALID_ARGUMENT: Project was not passed and could not be determined from the environment
```

**Quick fix**:
```bash
# Set your project
gcloud config set project YOUR_PROJECT_ID

# Verify it's set
gcloud config get-value project
```

**Or run the full setup script**:
```bash
./scripts/install_gcloud.sh
```

### Google Cloud: Authentication errors
```
ERROR: (gcloud) The current user has not obtained credentials
```

**Solution**:
```bash
# For interactive use
gcloud auth login

# For application default (needed for Cloud Functions)
gcloud auth application-default login
```

### Rebuild the CA bundle
The bundle should be rebuilt periodically (e.g., monthly) or when certifi is updated:
```bash
pip install --upgrade certifi
./scripts/build_ca_bundle.sh
```
