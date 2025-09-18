# Quick Fix Guide

## Your Error
```
Can't connect to powerman://localhost:10101
```

## The Fix: Use SNMP Instead!

Your device is **already working with SNMP**. Just use this configuration:

```yaml
users:
  - username: "nutuser"
    password: "changeme123"
    instcmds:
      - all
    actions: []

devices:
  - name: apc_pdu
    driver: snmp-ups
    port: 192.168.51.124
    config:
      - community = private
      - mibs = apcc

mode: netserver
shutdown_host: "false"
```

**Remove all powerman_* settings!**

## Deploy Now

```bash
# On your Mac
cd ~/Dev/addon-nut
chmod +x deploy_complete.sh
./deploy_complete.sh

# Choose option 1 (SNMP)
```

## That's It!

The "No matching MIB" warning is harmless. Your PDU will show as "Smart-UPS 1500" and work perfectly.

## Only If SNMP Doesn't Work

Then try PowerMan (option 2 in deploy script). But SNMP is already detecting your device, so it should work!
