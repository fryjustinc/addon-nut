#!/bin/bash

# Quick install script for Home Assistant
# Run this on your Home Assistant instance

ADDON_DIR="/config/addons/nut"

echo "Home Assistant NUT Addon Quick Installer"
echo "========================================"

# Check if we're on Home Assistant
if [ ! -d "/config" ]; then
    echo "Error: This script should be run on your Home Assistant instance"
    echo "Please SSH into Home Assistant first"
    exit 1
fi

# Create addons directory if it doesn't exist
if [ ! -d "/config/addons" ]; then
    echo "Creating /config/addons directory..."
    mkdir -p /config/addons
fi

# Remove old addon if it exists
if [ -d "$ADDON_DIR" ]; then
    echo "Removing old addon directory..."
    rm -rf "$ADDON_DIR"
fi

# Create new addon directory
echo "Creating addon directory..."
mkdir -p "$ADDON_DIR"

# Instructions for copying files
echo ""
echo "Now copy your addon files to Home Assistant:"
echo ""
echo "On your development machine (Mac), run:"
echo "  cd ~/Dev/addon-nut"
echo "  scp -r nut/* homeassistant.local:$ADDON_DIR/"
echo "  scp repository.yaml homeassistant.local:/config/addons/"
echo ""
echo "Or if using IP address:"
echo "  scp -r nut/* root@YOUR_HA_IP:$ADDON_DIR/"
echo "  scp repository.yaml root@YOUR_HA_IP:/config/addons/"
echo ""
echo "After copying, return here and press Enter to continue..."
read -r

# Check if files were copied
if [ -f "$ADDON_DIR/config.yaml" ]; then
    echo "✓ Files copied successfully"
else
    echo "✗ Files not found. Please copy them first."
    exit 1
fi

# Set permissions
echo "Setting permissions..."
chmod -R 755 "$ADDON_DIR"

echo ""
echo "Installation complete!"
echo ""
echo "Next steps:"
echo "1. Go to Home Assistant web interface"
echo "2. Navigate to Settings → Add-ons → Add-on Store"
echo "3. Click ⋮ (three dots) → Check for updates"
echo "4. Click ⋮ → Reload"
echo "5. Look for 'Network UPS Tools' under 'Local add-ons'"
echo "6. Click on it and install"
echo ""
echo "If the addon doesn't appear:"
echo "- Try restarting Home Assistant: Settings → System → Restart"
echo "- Clear your browser cache"
echo "- Check the logs: Settings → System → Logs"
