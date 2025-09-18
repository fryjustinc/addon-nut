#!/bin/bash

# Configuration switcher for NUT addon
# Helps switch between SNMP and PowerMan configurations

echo "======================================="
echo "NUT Addon Configuration Helper"
echo "======================================="
echo ""
echo "Choose your APC PDU connection method:"
echo ""
echo "1) SNMP (Simple - Recommended)"
echo "2) PowerMan (Advanced - Full outlet control)"
echo "3) Test current configuration"
echo ""
read -p "Enter choice [1-3]: " choice

PDU_IP="192.168.51.124"
read -p "Enter your PDU IP [$PDU_IP]: " INPUT_IP
PDU_IP=${INPUT_IP:-$PDU_IP}

case $choice in
    1)
        echo ""
        echo "SNMP Configuration"
        echo "=================="
        read -p "SNMP Community string [private]: " COMMUNITY
        COMMUNITY=${COMMUNITY:-private}
        
        cat << EOF > /tmp/nut_config.yaml
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
      - community = $COMMUNITY
      - mibs = apcc

mode: netserver
shutdown_host: "false"
log_level: info
EOF
        echo ""
        echo "Configuration saved to /tmp/nut_config.yaml"
        echo ""
        echo "Testing SNMP connection..."
        if timeout 5 snmpwalk -v1 -c $COMMUNITY $PDU_IP system 2>/dev/null | head -1; then
            echo "✓ SNMP connection successful!"
        else
            echo "✗ SNMP connection failed - check community string and PDU settings"
        fi
        ;;
        
    2)
        echo ""
        echo "PowerMan Configuration"
        echo "======================"
        read -p "PDU Username [apc]: " USERNAME
        USERNAME=${USERNAME:-apc}
        read -p "PDU Password [apc]: " PASSWORD
        PASSWORD=${PASSWORD:-apc}
        
        cat << EOF > /tmp/nut_config.yaml
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
powerman_pdu_username: $USERNAME
powerman_pdu_password: $PASSWORD
powerman_pdu_nodes: "outlet[1-8]"

mode: netserver
shutdown_host: "false"
log_level: debug
EOF
        echo ""
        echo "Configuration saved to /tmp/nut_config.yaml"
        echo ""
        echo "Testing Telnet connection..."
        if timeout 2 bash -c "echo quit | telnet $PDU_IP 23 2>/dev/null" | grep -q "User Name"; then
            echo "✓ Telnet port is open!"
        else
            echo "✗ Telnet connection failed - enable Telnet on PDU"
        fi
        ;;
        
    3)
        echo ""
        echo "Testing current configuration..."
        echo "================================"
        
        # Check if addon is running
        if docker ps | grep -q addon_local_nut; then
            echo "✓ NUT addon is running"
            echo ""
            echo "Checking UPS/PDU status:"
            docker exec addon_local_nut upsc -l 2>/dev/null || echo "No devices found"
            
            echo ""
            echo "Trying to get device info:"
            for device in $(docker exec addon_local_nut upsc -l 2>/dev/null); do
                echo "Device: $device"
                docker exec addon_local_nut upsc $device 2>/dev/null | head -10
            done
        else
            echo "✗ NUT addon is not running"
        fi
        
        echo ""
        echo "Checking PowerMan status:"
        if docker exec addon_local_nut ps aux 2>/dev/null | grep -q "[p]owermand"; then
            echo "✓ PowerMan daemon is running"
        else
            echo "✗ PowerMan daemon is not running"
        fi
        ;;
        
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "======================================="
echo "To apply configuration:"
echo "1. Copy config to addon: "
echo "   cat /tmp/nut_config.yaml"
echo "2. Paste into addon configuration in Home Assistant UI"
echo "3. Save and restart the addon"
