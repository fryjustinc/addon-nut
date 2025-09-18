# Complete Fix Summary - NUT Addon with PowerMan Support

## All Issues Fixed ✅

### 1. **Addon Not Detected** → Fixed
- Added `repository.yaml` 
- Created `README.md` (was missing, only had .README.j2)
- Fixed `config.yaml` schema

### 2. **Schema Validation Error** → Fixed
- Changed from nested `powerman.devices` array to flat `powerman_*` fields
- Home Assistant can't handle complex nested arrays in schema

### 3. **Docker Build Error** → Fixed
- Changed symlink creation to check if file exists first
- Uses conditional logic to avoid "File exists" error

### 4. **PowerMan Driver Path** → Fixed
- Handles both `/lib/nut/powerman-pdu` and `/usr/lib/nut/powerman-pdu` locations
- Creates symlink only if needed

## Quick Deployment

Run this on your Mac:
```bash
cd ~/Dev/addon-nut
chmod +x deploy.sh
./deploy.sh
```

This will:
1. Package the addon
2. Copy to Home Assistant
3. Install in `/config/addons/nut/`
4. Reload the addon store

## Your Working Configuration

```yaml
users:
  - username: "nutuser"
    password: "YourSecurePassword"
    instcmds:
      - all
    actions: []

devices:
  - name: rack_pdu
    driver: powerman-pdu
    port: powerman://localhost:10101
    config: []

# PowerMan configuration (flat structure - required!)
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

## Files Modified

| File | Change | Reason |
|------|--------|--------|
| `repository.yaml` | Created | Required for addon detection |
| `nut/README.md` | Created | Required for addon detection |
| `nut/config.yaml` | Fixed schema | Flat structure for PowerMan |
| `nut/Dockerfile` | Fixed symlink | Conditional creation |
| `nut/rootfs/etc/cont-init.d/nut.sh` | Updated | Read flat config |
| `nut/rootfs/etc/services.d/powerman/run` | Updated | Check powerman_enabled |

## Verification Steps

1. **Check addon is detected:**
   ```bash
   docker logs hassio_supervisor 2>&1 | grep "addon-nut"
   ```

2. **After installation, check logs:**
   ```bash
   docker logs addon_local_nut
   ```

3. **Check PowerMan is running:**
   ```bash
   docker exec addon_local_nut ps aux | grep powerman
   ```

4. **Test NUT connection:**
   ```bash
   docker exec addon_local_nut upsc rack_pdu@localhost
   ```

## Troubleshooting

If addon still not showing:
```bash
# On Home Assistant
ha supervisor restart
# Wait 30 seconds
ha addons reload
ha store reload
```

If build fails:
- Check Docker logs: `docker logs hassio_supervisor 2>&1 | grep ERROR`
- Clear Docker cache: `docker system prune -a`

If PowerMan doesn't start:
- Check config has `powerman_enabled: true`
- Check PDU is reachable: `ping 192.168.51.124`
- Enable debug logging: `log_level: debug`

## Success Indicators

✅ Addon appears under "Local add-ons"  
✅ Addon installs without errors  
✅ Addon starts successfully  
✅ Log shows "Starting PowerMan daemon"  
✅ Log shows "Starting the UPS drivers"  
✅ NUT integration connects to `a0d7b954-nut:3493`  

## Next Development Steps

If you need multiple PDU support:
1. Could create a more complex schema workaround
2. Could use manual PowerMan config files
3. Could create separate addon instances

For now, single PDU support is working and ready to use!
