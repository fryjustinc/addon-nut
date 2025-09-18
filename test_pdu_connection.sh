#!/bin/bash

# APC PDU Connection Troubleshooter
# Run this on Home Assistant to determine the best connection method

echo "======================================="
echo "APC PDU Connection Troubleshooter"
echo "======================================="
echo ""

PDU_IP="192.168.51.124"
read -p "Enter your PDU IP address [$PDU_IP]: " INPUT_IP
PDU_IP=${INPUT_IP:-$PDU_IP}

echo ""
echo "Testing connectivity to $PDU_IP..."
echo ""

# Test basic connectivity
echo "1. Basic Network Test:"
if ping -c 1 -W 2 $PDU_IP > /dev/null 2>&1; then
    echo "   ✓ PDU is reachable"
else
    echo "   ✗ PDU is NOT reachable - check network connection"
    exit 1
fi

# Test SNMP
echo ""
echo "2. SNMP Test:"
if command -v snmpwalk > /dev/null 2>&1; then
    if timeout 5 snmpwalk -v1 -c public $PDU_IP system 2>/dev/null | head -1 > /dev/null; then
        echo "   ✓ SNMP v1 with community 'public' works"
        SNMP_COMMUNITY="public"
    elif timeout 5 snmpwalk -v1 -c private $PDU_IP system 2>/dev/null | head -1 > /dev/null; then
        echo "   ✓ SNMP v1 with community 'private' works"
        SNMP_COMMUNITY="private"
    else
        echo "   ✗ SNMP not responding (may be disabled)"
        SNMP_COMMUNITY=""
    fi
    
    if [ -n "$SNMP_COMMUNITY" ]; then
        echo ""
        echo "   Getting device info via SNMP..."
        snmpget -v1 -c $SNMP_COMMUNITY $PDU_IP sysDescr.0 2>/dev/null | head -1
    fi
else
    echo "   - snmpwalk not installed, skipping SNMP test"
fi

# Test Telnet
echo ""
echo "3. Telnet Test:"
if timeout 2 bash -c "echo quit | telnet $PDU_IP 23 2>/dev/null" | grep -q "User Name"; then
    echo "   ✓ Telnet port 23 is open (PowerMan compatible)"
    TELNET_AVAILABLE="yes"
else
    echo "   ✗ Telnet not available (port 23 closed)"
    TELNET_AVAILABLE="no"
fi

# Test HTTP
echo ""
echo "4. Web Interface Test:"
if timeout 2 curl -s -o /dev/null -w "%{http_code}" http://$PDU_IP/ | grep -q "200\|301\|302"; then
    echo "   ✓ Web interface is accessible at http://$PDU_IP/"
else
    echo "   - Web interface not detected"
fi

# Recommendations
echo ""
echo "======================================="
echo "RECOMMENDATIONS"
echo "======================================="
echo ""

if [ -n "$SNMP_COMMUNITY" ]; then
    echo "✓ USE SNMP CONFIGURATION (Recommended - Simplest)"
    echo ""
    cat << EOF
devices:
  - name: apc_pdu
    driver: snmp-ups
    port: $PDU_IP
    config:
      - community = $SNMP_COMMUNITY
      - mibs = apcc
EOF
    echo ""
    echo "This is the easiest method and should work immediately."
    
elif [ "$TELNET_AVAILABLE" = "yes" ]; then
    echo "✓ USE POWERMAN CONFIGURATION"
    echo ""
    cat << EOF
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
EOF
    echo ""
    echo "Use this if you need individual outlet control."
    
else
    echo "✗ No suitable connection method found!"
    echo ""
    echo "Please enable either:"
    echo "1. SNMP on your PDU (recommended)"
    echo "2. Telnet access on your PDU"
    echo ""
    echo "Access your PDU web interface at http://$PDU_IP/"
    echo "to enable one of these protocols."
fi

echo ""
echo "======================================="
echo "Save the configuration above to use in your addon."
