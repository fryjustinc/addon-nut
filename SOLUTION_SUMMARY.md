# SOLUTION SUMMARY: Addon Not Being Detected

## Root Causes Fixed

### 1. ✅ **Missing repository descriptor**
   - **Problem**: No `repository.yaml` or `repository.json` in root
   - **Solution**: Created both files with proper structure

### 2. ✅ **Missing README.md**
   - **Problem**: Only had `.README.j2` template file
   - **Solution**: Created proper `README.md` in `/nut/` directory

### 3. ✅ **Invalid config.yaml**
   - **Problem**: Comments in the `options` section made it invalid
   - **Solution**: Removed all comments from `options` section

### 4. ✅ **Driver path issue** (for runtime)
   - **Problem**: powerman-pdu installed at `/lib/nut/` but NUT looks in `/usr/lib/nut/`
   - **Solution**: Added symlink in Dockerfile

## Final Addon Structure

```
addon-nut/
├── repository.yaml          ✅ Created
├── repository.json          ✅ Created (backup)
└── nut/
    ├── config.yaml         ✅ Fixed
    ├── Dockerfile          ✅ Fixed
    ├── README.md           ✅ Created
    ├── DOCS.md            ✅ Exists
    ├── build.yaml         ✅ Exists
    ├── icon.png           ✅ Exists
    ├── logo.png           ✅ Exists
    └── rootfs/            ✅ Exists
```

## Installation Instructions

### Quickest Method - Direct Copy

1. **On your Mac:**
   ```bash
   cd ~/Dev/addon-nut
   tar czf nut-addon.tar.gz nut/ repository.yaml
   scp nut-addon.tar.gz root@homeassistant.local:/tmp/
   ```

2. **SSH into Home Assistant:**
   ```bash
   ssh root@homeassistant.local
   cd /config/addons
   tar xzf /tmp/nut-addon.tar.gz
   ```

3. **In Home Assistant UI:**
   - Settings → Add-ons → Add-on Store
   - Click ⋮ → Check for updates
   - Click ⋮ → Reload
   - Find "Network UPS Tools" under "Local add-ons"

## Verification Commands

Run these on Home Assistant to verify:

```bash
# Check if addon is valid
ls -la /config/addons/nut/
cat /config/addons/repository.yaml

# Check YAML validity
python3 -c "import yaml; print('✓ Valid') if yaml.safe_load(open('/config/addons/nut/config.yaml')) else print('✗ Invalid')"

# Check Home Assistant supervisor logs
docker logs hassio_supervisor 2>&1 | grep -i "nut\|addon"
```

## If STILL Not Working

1. **Complete restart of Home Assistant:**
   ```bash
   ha core restart
   ha supervisor restart
   ```

2. **Force reload of addon store:**
   ```bash
   ha addons reload
   ha store reload
   ```

3. **Check for errors:**
   ```bash
   ha supervisor logs | grep -i error
   ```

## Working Configuration for Your APC PDU

Once installed, use this exact configuration:

```yaml
users:
  - username: "nutuser"
    password: "StrongPassword123!"
    instcmds:
      - all
    actions: []

devices:
  - name: rack_pdu
    driver: powerman-pdu
    port: powerman://localhost:10101
    config: []
    powerman_device: apc_pdu

powerman:
  enabled: true
  devices:
    - name: apc_pdu
      type: apc
      host: 192.168.51.124
      username: apc
      password: apc
      nodes: "outlet[1-8]"

mode: netserver
shutdown_host: "false"
log_level: debug
```

## Files Changed Summary

1. Created `/repository.yaml` and `/repository.json`
2. Created `/nut/README.md` from template
3. Fixed `/nut/config.yaml` - removed comments from options
4. Fixed `/nut/Dockerfile` - added symlink for driver
5. Renamed `/nut/.README.j2` to `/nut/.README.j2.backup`

The addon should now be detectable by Home Assistant!
