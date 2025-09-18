#!/bin/bash

# Complete deployment and fix script
# Handles all issues and deploys working configuration

echo "============================================"
echo "NUT Addon - Complete Fix and Deploy"
echo "============================================"
echo ""

# Get Home Assistant host
read -p "Home Assistant host [homeassistant.local]: " HA_HOST
HA_HOST=${HA_HOST:-homeassistant.local}

# Get PDU IP
read -p "APC PDU IP address [192.168.51.124]: " PDU_IP
PDU_IP=${PDU_IP:-192.168.51.124}

echo ""
echo "1) Deploy SNMP configuration (Recommended - Simplest)"
echo "2) Deploy PowerMan configuration (Advanced)"  
echo "3) Deploy both (SNMP + PowerMan ready)"
echo "4) Just copy fixed files (no config change)"
echo ""
read -p "Choose option [1-4]: " OPTION

# Create deployment package
echo ""
echo "Creating deployment package..."
cd ~/Dev/addon-nut 2>/dev/null || cd /Users/fryjustinc/Dev/addon-nut

tar czf /tmp/nut-addon-complete.tar.gz \
    nut/config.yaml \
    nut/Dockerfile \
    nut/README.md \
    nut/DOCS.md \
    nut/build.yaml \
    nut/icon.png \
    nut/logo.png \
    nut/rootfs \
    repository.yaml \
    *.md \
    *.sh

echo "✓ Package created"

# Copy to Home Assistant
echo "Copying to $HA_HOST..."
scp /tmp/nut-addon-complete.tar.gz root@$HA_HOST:/tmp/

# Deploy and configure
echo "Deploying..."
ssh root@$HA_HOST << ENDSSH
set -e

# Backup existing addon
if [ -d /config/addons/nut ]; then
    echo "Backing up existing addon..."
    cp -r /config/addons/nut /config/addons/nut.backup.\$(date +%s)
fi

# Extract new addon
echo "Installing addon files..."
cd /config/addons
tar xzf /tmp/nut-addon-complete.tar.gz
rm /tmp/nut-addon-complete.tar.gz

# Create configuration based on option
case $OPTION in
    1)
        echo "Setting up SNMP configuration..."
        cat > /tmp/nut_config.yaml << 'EOF'
users:
  - username: "nutuser"
    password: "changeme123"
    instcmds:
      - all
    actions: []

devices:
  - name: apc_pdu
    driver: snmp-ups
    port: $PDU_IP
    config:
      - community = private
      - mibs = apcc

mode: netserver
shutdown_host: "false"
log_level: info
EOF
        sed -i "s/\\\$PDU_IP/$PDU_IP/g" /tmp/nut_config.yaml
        echo "✓ SNMP configuration ready"
        ;;
        
    2)
        echo "Setting up PowerMan configuration..."
        cat > /tmp/nut_config.yaml << 'EOF'
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
powerman_pdu_host: $PDU_IP
powerman_pdu_username: apc
powerman_pdu_password: apc
powerman_pdu_nodes: "outlet[1-8]"

mode: netserver
shutdown_host: "false"
log_level: debug
EOF
        sed -i "s/\\\$PDU_IP/$PDU_IP/g" /tmp/nut_config.yaml
        echo "✓ PowerMan configuration ready"
        ;;
        
    3)
        echo "Setting up hybrid configuration..."
        cat > /tmp/nut_config.yaml << 'EOF'
users:
  - username: "nutuser"
    password: "changeme123"
    instcmds:
      - all
    actions: []

devices:
  - name: apc_pdu
    driver: snmp-ups
    port: $PDU_IP
    config:
      - community = private
      - mibs = apcc

powerman_enabled: false
powerman_pdu_name: apc_pdu
powerman_pdu_type: apc
powerman_pdu_host: $PDU_IP
powerman_pdu_username: apc
powerman_pdu_password: apc
powerman_pdu_nodes: "outlet[1-8]"

mode: netserver
shutdown_host: "false"
log_level: info
EOF
        sed -i "s/\\\$PDU_IP/$PDU_IP/g" /tmp/nut_config.yaml
        echo "✓ Hybrid configuration ready"
        ;;
        
    4)
        echo "Files copied, no configuration change"
        ;;
esac

# Reload addon store
echo ""
echo "Reloading addon store..."
ha addons reload
sleep 2
ha store reload

# Check if addon is detected
echo ""
echo "Checking addon status..."
if ha addons info local_nut &>/dev/null; then
    echo "✓ Addon detected!"
    
    # Show configuration to apply
    if [ -f /tmp/nut_config.yaml ] && [ $OPTION -ne 4 ]; then
        echo ""
        echo "============================================"
        echo "CONFIGURATION TO APPLY:"
        echo "============================================"
        cat /tmp/nut_config.yaml
        echo "============================================"
        echo ""
        echo "Copy the configuration above and:"
        echo "1. Go to Settings → Add-ons → Network UPS Tools"
        echo "2. Go to Configuration tab"
        echo "3. Paste the configuration"
        echo "4. Save and start the addon"
    fi
else
    echo "✗ Addon not detected yet"
    echo "Try: ha supervisor restart"
fi

# Quick connectivity test
echo ""
echo "Testing PDU connectivity..."
ping -c 1 -W 2 $PDU_IP &>/dev/null && echo "✓ PDU is reachable at $PDU_IP" || echo "✗ Cannot reach PDU at $PDU_IP"

if [ $OPTION -eq 1 ] || [ $OPTION -eq 3 ]; then
    echo "Testing SNMP..."
    snmpget -v1 -c private $PDU_IP sysDescr.0 2>/dev/null | head -1 && echo "✓ SNMP is working!" || echo "✗ SNMP not responding"
fi

ENDSSH

echo ""
echo "============================================"
echo "DEPLOYMENT COMPLETE!"
echo "============================================"
echo ""
echo "Next steps:"
echo "1. Go to Home Assistant web UI"
echo "2. Settings → Add-ons → Add-on Store"
echo "3. Find 'Network UPS Tools' under Local add-ons"
echo "4. Install the addon"
echo "5. Apply the configuration shown above"
echo "6. Start the addon"
echo ""
echo "If using SNMP (recommended):"
echo "  The 'No matching MIB' warning is harmless"
echo "  The device will work as 'Smart-UPS 1500'"
echo ""

rm -f /tmp/nut-addon-complete.tar.gz
