# Quick Start - APC PDU via SNMP

Based on your error messages, your APC device IS responding to SNMP. Here's the simplest configuration that should work immediately:

## Simple SNMP Configuration (Use This First!)

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

## Why This Should Work

Your logs show:
```
Detected Smart-UPS 1500 on host 192.168.51.124 (mib: apcc 1.6)
```

This means:
- ✅ SNMP is working
- ✅ Device is responding
- ✅ NUT can communicate with it

The "No matching MIB" warning can be ignored - it's using the fallback APCC MIB which works fine.

## Quick Test

1. Use the SNMP config above (no PowerMan needed)
2. Start the addon
3. Check if it's working:
   ```bash
   docker exec addon_local_nut upsc apc_pdu@localhost
   ```

## If You Need PowerMan Later

PowerMan is only needed if you want:
- Individual outlet on/off control via NUT
- Complex power sequencing

For basic monitoring and UPS-like functions, SNMP is sufficient and simpler!

## The Issue with Your Current Config

You're trying to use BOTH:
- SNMP (detecting as Smart-UPS)
- PowerMan (failing to connect)

Pick one approach:
- **SNMP**: Simpler, already working
- **PowerMan**: More complex, needs daemon running

Start with SNMP since it's already detecting your device!
