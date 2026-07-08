#!/bin/bash

# Dashboard Regeneration Helper Script
# This script regenerates all Grafana dashboard YAML templates from their JSON sources

set -e  # Exit on error

SCRIPT_DIR="scripts/convert-dashboard"

echo "========================================="
echo "  Dashboard Regeneration Script"
echo "========================================="
echo ""

# Check if we're in the right directory
if [ ! -d "$SCRIPT_DIR" ]; then
    echo "Error: Must run this script from the cognigy-dashboards root directory"
    echo "Current directory: $(pwd)"
    exit 1
fi

# Create a temporary venv and clean it up on exit
VENV_DIR="$(mktemp -d)"
trap 'rm -rf "$VENV_DIR"' EXIT

echo "📦 Creating temporary virtual environment..."
python3 -m venv "$VENV_DIR"
source "$VENV_DIR/bin/activate"
echo "📥 Installing dependencies (pyyaml)..."
pip install pyyaml > /dev/null 2>&1
echo "✅ Dependencies installed"

# Navigate to script directory
cd "$SCRIPT_DIR"

echo ""
echo "🔄 Converting dashboards from JSON to YAML..."
echo ""

# Run the conversion script
python3 convert-dashboard.py

echo ""
echo "========================================="
echo "✅ Dashboard regeneration complete!"
echo "========================================="
echo ""
echo "📝 Next steps:"
echo "  1. Review changes: git status"
echo "  2. Check diffs: git diff"
echo "  3. Commit changes: git add . && git commit"
echo ""
