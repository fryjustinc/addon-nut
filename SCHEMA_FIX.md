# FIXED: Home Assistant Addon Detection Issue

## The Problem
The supervisor was throwing this error:
```
Can't read /data/addons/local/addon-nut/nut/config.yaml: 
expected string or buffer @ data['schema']['powerman']['devices'][0]. 
Got {'name': 'str', 'type': 'str', 'host': 'str', 'username': 'str?', 'password': 'password?', 'nodes': 'str?'}
```

## Root Cause
Home Assistant's addon schema validator doesn't support nested object arrays in the format we were using:

**INVALID (What we had):**
```yaml
schema:
  powerman:
    enabled: bool?
    devices:
      - name: str
        type: str
        host: str
        username: str?
        password: password?
        nodes: str?
```

The schema validator expects simple types or arrays of simple types, not arrays of complex objects.

## The Solution
Changed to a flat configuration structure that Home Assistant can validate:

**VALID (Fixed version):**
```yaml
schema:
  powerman_enabled: bool?
  powerman_pdu_name: str?
  powerman_pdu_type: str?
  powerman_pdu_host: str?
  powerman_pdu_username: str?
  powerman_pdu_password: password?
  powerman_pdu_nodes: str?
```

## Files Updated

### 1. `/nut/config.yaml`
- Changed schema from nested `powerman.devices` array to flat `powerman_*` fields
- Simplified configuration structure

### 2. `/nut/rootfs/etc/cont-init.d/nut.sh`
- Updated to read flat `powerman_*` configuration fields
- Changed from looping through devices array to reading single PDU config

### 3. `/nut/rootfs/etc/services.d/powerman/run`
- Updated to check `powerman_enabled` flag instead of checking for driver

### 4. Configuration examples
- Updated all examples to use the new flat structure

## Your Working Configuration

```yaml
users:
  - username: "nutuser"
    password: "YourSecurePassword123"
    instcmds:
      - all
    actions: []

devices:
  - name: rack_pdu
    driver: powerman-pdu
    port: powerman://localhost:10101
    config: []

# PowerMan configuration - FLAT STRUCTURE
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

## Installation Steps

1. **Copy the updated addon to Home Assistant:**
   ```bash
   # On your Mac
   cd ~/Dev/addon-nut
   scp -r nut/* root@homeassistant.local:/config/addons/nut/
   ```

2. **Reload the addon store:**
   ```bash
   # On Home Assistant
   ha addons reload
   ha store reload
   ```

3. **Or force supervisor restart:**
   ```bash
   docker restart hassio_supervisor
   ```

4. **Check supervisor logs:**
   ```bash
   docker logs hassio_supervisor 2>&1 | grep -i "nut"
   ```

## Note on Multiple PDUs

The simplified schema only supports a single PDU configuration. If you need multiple PDUs, you would need to:
1. Run multiple instances of the addon (not ideal)
2. Or modify the PowerMan configuration files directly after addon starts
3. Or use a more complex configuration approach

For your single APC AP7900B PDU, this simplified approach works perfectly.

## Verification

After copying the fixed files:
```bash
# Check if addon is detected
docker logs hassio_supervisor 2>&1 | grep "addon-nut"

# Should see something like:
# [supervisor.store.data] Loading add-on /data/addons/local/addon-nut/nut/config.yaml
```

The addon should now appear in Home Assistant under Settings → Add-ons → Local add-ons!
