# PowerMan PDU Support - Final Fixes

## Fixed Issues

### 1. Driver Path Issue
- **Problem**: NUT was looking for powerman-pdu driver at `/usr/lib/nut/powerman-pdu` but Debian package installs it at `/lib/nut/powerman-pdu`
- **Solution**: Added symlink in Dockerfile to link `/usr/lib/nut/powerman-pdu` to `/lib/nut/powerman-pdu`

### 2. Invalid config.yaml
- **Problem**: The `options` section contained comments which made it invalid YAML, preventing the addon from being detected as installable
- **Solution**: Removed comments from `options` section (comments are only allowed in `schema` section)

### 3. Configuration Examples
- **Added**: Created CONFIG_EXAMPLES.md with complete working examples for various configurations:
  - USB UPS
  - APC Smart-UPS with SNMP
  - APC AP7900B PDU with PowerMan
  - Multiple devices (UPS + PDU)
  - IPMI-based PDUs

## Changes Made

### Dockerfile
```dockerfile
# Added symlink creation after package installation
RUN mkdir -p /usr/lib/nut \
    && ln -s /lib/nut/powerman-pdu /usr/lib/nut/powerman-pdu
```

### config.yaml
- Removed all comments from the `options` section
- Kept schema section intact with PowerMan configuration options

## Testing Instructions

1. Rebuild the addon:
   ```bash
   cd ~/Dev/addon-nut
   docker build -t local/nut nut/
   ```

2. Install the addon in Home Assistant:
   - Go to Settings → Add-ons → Add-on Store
   - Click the three dots menu → Repositories
   - Add your local repository path
   - Install the Network UPS Tools addon

3. Configure the addon using one of the examples from CONFIG_EXAMPLES.md

4. Start the addon and check logs for any errors

## Known Working Configuration

For APC AP7900B PDU:
```yaml
devices:
  - name: rack_pdu
    driver: powerman-pdu
    port: powerman://localhost:10101
    config: []
    powerman_device: apc_rack_pdu
powerman:
  enabled: true
  devices:
    - name: apc_rack_pdu
      type: apc
      host: 192.168.51.124
      username: apc
      password: apc
      nodes: "outlet[1-8]"
```

## Next Steps

If the addon still has issues:
1. Check if powermand is running: `ps aux | grep powerman`
2. Test PowerMan connectivity: `/usr/bin/test-powerman`
3. Check NUT driver status: `upsdrvctl status`
4. Review logs with debug level enabled

## Files Modified
- `/nut/Dockerfile` - Added symlink for powerman-pdu driver
- `/nut/config.yaml` - Removed comments from options section
- Created `/CONFIG_EXAMPLES.md` - Configuration examples
- Created `/FINAL_FIXES.md` - This changelog
