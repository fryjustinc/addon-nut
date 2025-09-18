#!/bin/bash
# Run this on Home Assistant after copying files

echo "Home Assistant NUT Addon - Fix and Reload"
echo "=========================================="

# Check if running on Home Assistant
if [ ! -d "/config" ]; then
    echo "Error: This script must be run on Home Assistant"
    exit 1
fi

# Check if addon files exist
if [ ! -f "/config/addons/nut/config.yaml" ]; then
    echo "Error: Addon files not found in /config/addons/nut/"
    echo "Please copy the addon files first:"
    echo "  scp -r nut/* root@homeassistant.local:/config/addons/nut/"
    exit 1
fi

echo "Found addon files in /config/addons/nut/"

# Quick validation
echo ""
echo "Validating config.yaml..."
python3 -c "
import yaml
try:
    with open('/config/addons/nut/config.yaml', 'r') as f:
        config = yaml.safe_load(f)
    print('✓ config.yaml is valid YAML')
    if 'schema' in config:
        if 'powerman_enabled' in config['schema']:
            print('✓ PowerMan uses flat structure (FIXED)')
        elif 'powerman' in config['schema'] and 'devices' in config['schema'].get('powerman', {}):
            print('✗ PowerMan still uses nested structure (NEEDS FIX)')
            exit(1)
except Exception as e:
    print(f'✗ Error: {e}')
    exit(1)
"

if [ $? -ne 0 ]; then
    echo "Config validation failed!"
    exit 1
fi

# Reload addon store
echo ""
echo "Reloading addon store..."
ha addons reload

echo ""
echo "Forcing store refresh..."
ha store reload

# Check if addon is detected
echo ""
echo "Checking if addon is detected..."
sleep 2

# Check supervisor logs
echo ""
echo "Recent supervisor logs about nut addon:"
docker logs hassio_supervisor 2>&1 | grep -i "nut" | tail -5

echo ""
echo "=========================================="
echo "Done! Check Home Assistant UI:"
echo "  Settings → Add-ons → Add-on Store"
echo "  Look under 'Local add-ons' section"
echo ""
echo "If addon is now visible, install it and use this config:"
echo ""
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
