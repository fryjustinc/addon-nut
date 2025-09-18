#!/bin/bash

# Quick deployment script for fixed NUT addon
# Run this on your Mac to deploy to Home Assistant

echo "=================================="
echo "NUT Addon Deployment Script"
echo "=================================="

# Check if we're in the right directory
if [ ! -f "nut/config.yaml" ]; then
    echo "Error: Not in addon-nut directory"
    echo "Please cd to ~/Dev/addon-nut first"
    exit 1
fi

# Get Home Assistant host
read -p "Enter Home Assistant hostname or IP [homeassistant.local]: " HA_HOST
HA_HOST=${HA_HOST:-homeassistant.local}

echo ""
echo "Deploying to: $HA_HOST"
echo ""

# Create a deployment package
echo "Creating deployment package..."
tar czf nut-addon-fixed.tar.gz \
    nut/config.yaml \
    nut/Dockerfile \
    nut/README.md \
    nut/DOCS.md \
    nut/build.yaml \
    nut/icon.png \
    nut/logo.png \
    nut/rootfs \
    nut/examples \
    repository.yaml

echo "✓ Package created"

# Copy to Home Assistant
echo ""
echo "Copying to Home Assistant..."
scp nut-addon-fixed.tar.gz root@${HA_HOST}:/tmp/

# Deploy on Home Assistant
echo ""
echo "Deploying on Home Assistant..."
ssh root@${HA_HOST} << 'ENDSSH'
cd /config/addons
rm -rf nut.backup
if [ -d nut ]; then
    mv nut nut.backup
fi
tar xzf /tmp/nut-addon-fixed.tar.gz
rm /tmp/nut-addon-fixed.tar.gz

# Copy repository file
if [ -f repository.yaml ]; then
    cp repository.yaml /config/addons/
fi

echo "✓ Files deployed"

# Reload addon store
echo ""
echo "Reloading addon store..."
ha addons reload
sleep 2
ha store reload

echo ""
echo "Checking for addon..."
docker logs hassio_supervisor 2>&1 | grep -i "addon-nut" | tail -3

echo ""
echo "✓ Deployment complete"
ENDSSH

# Clean up
rm -f nut-addon-fixed.tar.gz

echo ""
echo "=================================="
echo "Deployment Complete!"
echo "=================================="
echo ""
echo "Next steps:"
echo "1. Go to Home Assistant web UI"
echo "2. Settings → Add-ons → Add-on Store"
echo "3. Look under 'Local add-ons'"
echo "4. Click 'Network UPS Tools' and install"
echo ""
echo "Configuration for your APC PDU:"
echo "=================================="
cat << 'EOF'
users:
  - username: "nutuser"
    password: "changeme123"
    instcmds:
      - all
    actions: []

devices:
  - name: rack_pdu
    driver: powerman-pdu
    port: powerman://localhost:10101
    config: []

powerman_enabled: true
powerman_pdu_name: apc_pdu
powerman_pdu_type: apc
powerman_pdu_host: 192.168.51.124
powerman_pdu_username: apc
powerman_pdu_password: apc
powerman_pdu_nodes: "outlet[1-8]"

mode: netserver
shutdown_host: "false"
log_level: debug
EOF
