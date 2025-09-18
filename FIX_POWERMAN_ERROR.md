# Fix for PowerMan Connection Error

## The Error
```
Can't connect to powerman://localhost:10101: failed to get address info for server
Driver failed to start (exit status=1)
```

## Root Causes

1. **PowerMan daemon not running** when NUT driver tries to connect
2. **You might not need PowerMan at all** - SNMP is already working!

## Important Discovery

Your logs show:
```
Detected Smart-UPS 1500 on host 192.168.51.124 (mib: apcc 1.6)
```

**This means SNMP is already working!** You don't need PowerMan unless you specifically want individual outlet control.

## Solution 1: Use SNMP (Recommended - Simplest)

Since SNMP is already detecting your device, just use this configuration:

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
      - community = private  # or "public" depending on your PDU settings
      - mibs = apcc

mode: netserver
shutdown_host: "false"
log_level: info
```

**No PowerMan configuration needed!** Remove all `powerman_*` settings.

## Solution 2: Fix PowerMan (If You Really Need It)

If you need individual outlet control via PowerMan:

### Files Updated:

1. **`/nut/rootfs/etc/cont-init.d/nut.sh`** - Start PowerMan earlier in init
2. **`/nut/rootfs/etc/services.d/powerman/run`** - Ensure service starts properly
3. **`/nut/rootfs/etc/services.d/upsd/run`** - Wait for PowerMan before starting

### Configuration:

```yaml
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
```

## Quick Deployment

```bash
# Copy updated files
cd ~/Dev/addon-nut
scp -r nut/rootfs/etc/* root@homeassistant.local:/config/addons/nut/rootfs/etc/

# Restart addon
ssh root@homeassistant.local "ha addons restart local_nut"
```

## Testing Your Connection

Copy and run this test script on Home Assistant:

```bash
scp test_pdu_connection.sh root@homeassistant.local:/tmp/
ssh root@homeassistant.local "chmod +x /tmp/test_pdu_connection.sh && /tmp/test_pdu_connection.sh"
```

## Recommendation

**Use SNMP!** It's simpler and already working. Only use PowerMan if you need:
- Individual outlet on/off control
- Complex power sequencing
- Outlet group management

For basic PDU monitoring and power status, SNMP is perfect and much simpler.

## Verification

After starting with SNMP config:
```bash
# Check if device is recognized
docker exec addon_local_nut upsc apc_pdu@localhost

# You should see output like:
# battery.charge: 100
# device.mfr: APC
# device.model: Smart-UPS 1500
# device.serial: ...
# ups.status: OL
```

The "No matching MIB" warning can be safely ignored - the fallback APCC MIB works fine!
