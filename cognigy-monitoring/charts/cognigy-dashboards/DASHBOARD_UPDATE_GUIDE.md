# Dashboard Update Guide

## Overview

Dashboards are stored as JSON files and converted to Kubernetes ConfigMap YAML templates using a Python script. 

**Important:** Never edit the YAML files directly - always update the JSON source files and regenerate the YAML.

## File Structure

```
cognigy-monitoring/charts/cognigy-dashboards/
├── dashboards/              # JSON source files (EDIT THESE)
│   ├── ai/
│   ├── services/
│   ├── insights/
│   ├── la/
│   ├── vg/
│   └── ...
├── templates/dashboards/    # Generated YAML files (DO NOT EDIT)
│   └── ...
└── regenerate-dashboards.sh # Helper script to regenerate YAML
```

## How to Update a Dashboard

### Step 1: Edit the JSON Dashboard

Edit your dashboard JSON file in the `dashboards/` directory:

```bash
# Example: Edit the service-endpoint dashboard
vi dashboards/ai/service-endpoint.json
```

### Step 2: Regenerate the YAML Template

**Option A: Using the Helper Script (Recommended)**

```bash
./regenerate-dashboards.sh
```

The helper script automatically handles:
- Virtual environment setup (first run only)
- Dependency installation
- Running the conversion
- Clear output and next steps

**Option B: Manual Method**

If you prefer or need to run manually:

```bash
# First-time setup (only needed once)
cd scripts/convert-dashboard/
python3 -m venv venv
source venv/bin/activate
pip install pyyaml

# Run conversion (every time)
cd scripts/convert-dashboard/
source venv/bin/activate && python3 convert-dashboard.py
```

### Step 3: Review and Commit Changes

```bash
# Check what changed
git status
git diff

# Commit both JSON and generated YAML
git add dashboards/ai/service-endpoint.json
git add templates/dashboards/ai/service-endpoint.yaml
git commit -m "Update service-endpoint dashboard"
```
