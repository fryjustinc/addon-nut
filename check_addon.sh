#!/bin/bash

# Home Assistant Addon Installation Troubleshooting Script

echo "========================================"
echo "Home Assistant Addon Installation Check"
echo "========================================"

# Check current directory
echo "Current directory: $(pwd)"

# Check if repository files exist
echo ""
echo "Checking repository files..."
if [ -f "repository.json" ] || [ -f "repository.yaml" ]; then
    echo "✓ Repository descriptor found"
else
    echo "✗ Missing repository.json or repository.yaml"
fi

# Check addon directory structure
echo ""
echo "Checking addon structure..."
ADDON_DIR="nut"

if [ -d "$ADDON_DIR" ]; then
    echo "✓ Addon directory exists: $ADDON_DIR"
    
    # Check required files
    REQUIRED_FILES=("config.yaml" "Dockerfile" "README.md")
    for file in "${REQUIRED_FILES[@]}"; do
        if [ -f "$ADDON_DIR/$file" ]; then
            echo "  ✓ $file exists"
        else
            echo "  ✗ Missing $file"
        fi
    done
    
    # Check optional but recommended files
    OPTIONAL_FILES=("DOCS.md" "icon.png" "logo.png" "build.yaml")
    for file in "${OPTIONAL_FILES[@]}"; do
        if [ -f "$ADDON_DIR/$file" ]; then
            echo "  ✓ $file exists (optional)"
        else
            echo "  - $file not found (optional)"
        fi
    done
else
    echo "✗ Addon directory not found: $ADDON_DIR"
fi

# Validate YAML files
echo ""
echo "Validating YAML files..."
if command -v python3 &> /dev/null; then
    python3 -c "
import yaml
import sys

files_to_check = [
    'repository.yaml',
    'nut/config.yaml'
]

for file in files_to_check:
    try:
        with open(file, 'r') as f:
            yaml.safe_load(f)
        print(f'  ✓ {file} is valid YAML')
    except FileNotFoundError:
        print(f'  - {file} not found')
    except yaml.YAMLError as e:
        print(f'  ✗ {file} has YAML errors:')
        print(f'    {e}')
    except Exception as e:
        print(f'  ✗ Error checking {file}: {e}')
"
else
    echo "  Python3 not found - cannot validate YAML"
fi

# Build the Docker image locally for testing
echo ""
echo "Docker build test..."
echo "To build the addon locally, run:"
echo "  docker build -t local/nut nut/"

# Installation instructions
echo ""
echo "========================================"
echo "Installation Instructions for Home Assistant"
echo "========================================"
echo ""
echo "Method 1: Local Addon (for testing)"
echo "1. Copy this entire directory to your Home Assistant config/addons folder:"
echo "   scp -r $(pwd) homeassistant:/config/addons/nut"
echo "2. Go to Settings → Add-ons → Add-on Store"
echo "3. Click ⋮ (three dots) → Check for updates"
echo "4. Click ⋮ → Reload"
echo "5. Find 'Network UPS Tools' under 'Local add-ons'"
echo ""
echo "Method 2: Git Repository"
echo "1. Push your changes to a Git repository"
echo "2. In Home Assistant, go to Settings → Add-ons → Add-on Store"
echo "3. Click ⋮ (three dots) → Repositories"
echo "4. Add your repository URL"
echo "5. Find 'Network UPS Tools' in the store"
echo ""
echo "Method 3: File Editor Addon"
echo "If you have the File Editor addon:"
echo "1. Create folder: /addons/nut"
echo "2. Copy all files from this directory to /addons/nut"
echo "3. Reload as in Method 1"
echo ""
echo "========================================"

# Check if we're running on Home Assistant
if [ -d "/config" ] && [ -d "/addons" ]; then
    echo ""
    echo "Home Assistant detected!"
    echo "You can copy the addon directly:"
    echo "  cp -r $(pwd) /addons/nut"
    echo "Then reload the addon store"
fi
