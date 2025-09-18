# SOLUTION: APC PDU Connection Issues

## Your Current Situation

Your logs show that your APC PDU at `192.168.51.124` is:
- ✅ **Responding to SNMP** (detected as "Smart-UPS 1500")
- ❌ **PowerMan failing** (can't connect to localhost:10101)

## The Simple Solution: Use SNMP!

Since SNMP is already working, **you don't need PowerMan**. Just use this configuration:

```yaml
users:
  - username: "nutuser"
    password: "YourSecurePassword"
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

That's it! No PowerMan settings needed. The addon should start successfully.

## Why This Works

The error messages actually show SUCCESS:
```
Detected Smart-UPS 1500 on host 192.168.51.124 (mib: apcc 1.6)
```

The "No matching MIB" warning is harmless - NUT falls back to a generic APC MIB that works fine.

## When You Need PowerMan

Only use PowerMan if you need:
- Individual outlet on/off control
- Power sequencing for multiple servers
- Outlet group management

For basic monitoring (voltage, load, status), SNMP is perfect.

## Quick Test

After applying the SNMP config:

```bash
# From Home Assistant SSH
docker exec addon_local_nut upsc apc_pdu@localhost

# You should see:
# device.mfr: APC
# device.model: Smart-UPS 1500
# ups.status: OL
# ... more data ...
```

## If You Must Use PowerMan

I've fixed the startup sequence issues. Copy these updated files:

```bash
# From your Mac
cd ~/Dev/addon-nut
scp -r nut/rootfs/etc/cont-init.d/nut.sh root@homeassistant.local:/config/addons/nut/rootfs/etc/cont-init.d/
scp -r nut/rootfs/etc/services.d/* root@homeassistant.local:/config/addons/nut/rootfs/etc/services.d/
```

But seriously, **just use SNMP** - it's already working!

## Files Provided

1. **QUICK_START_SNMP.md** - Simple SNMP configuration
2. **test_pdu_connection.sh** - Test which connection methods work
3. **configure_helper.sh** - Generate correct configuration
4. **FIX_POWERMAN_ERROR.md** - Detailed PowerMan fixes

## Bottom Line

Your APC PDU is already accessible via SNMP. Use the SNMP configuration above and you'll be monitoring your PDU in minutes, not hours!

The PowerMan errors are a distraction - you don't need it for basic PDU monitoring.
