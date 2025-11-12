# Prbb-gcal
Small script to parse PRBB Agenda and add it to an ica

## Quick Start

```bash
# Complete setup (creates venv, builds CA bundle, runs tests)
./scripts/setup.sh

# Run the parser
cd src
source venv/bin/activate
python main.py
```

## How-to
1. Run venv creation script
2. **Build the custom CA bundle** (required for SSL verification)
3. Run parser
4. Upload ics to your personal PRBB calendar
5. Create a cron task to autoparse the calendar whenever you like

You can also subscribe to my PRBB calendar through the following link
<link>

## Setup

### 1. Create Virtual Environment
```bash
./scripts/venv_create.sh
```

### 2. Build Custom CA Bundle
The PRBB website (www.prbb.org) has a misconfigured SSL certificate that doesn't include the intermediate CA in its chain. This causes SSL verification to fail with standard Python/requests.

**Build the custom CA bundle** (includes HARICA/GEANT intermediate CA):
```bash
./scripts/build_ca_bundle.sh
```

This creates `src/custom_ca_bundle.pem` which the script will automatically use.

### 3. Run the Parser
```bash
cd src
source venv/bin/activate
python main.py
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

### Rebuild the bundle
The bundle should be rebuilt periodically (e.g., monthly) or when certifi is updated:
```bash
pip install --upgrade certifi
./scripts/build_ca_bundle.sh
```
