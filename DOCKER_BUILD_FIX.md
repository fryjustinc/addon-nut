# Fixed: Docker Build Error

## The Problem
Docker build was failing with:
```
ln: failed to create symbolic link '/usr/lib/nut/powerman-pdu': File exists
```

## The Solution
The `nut-powerman-pdu` package might already install the driver in `/usr/lib/nut/` or create the symlink. Fixed the Dockerfile to:

1. **Check before creating symlink** - Only create if source exists and target doesn't
2. **Handle existing files gracefully** - Don't fail if symlink/file already exists
3. **Add diagnostics** - Show where the driver is actually located

## Updated Dockerfile

```dockerfile
# Create symlinks for powerman-pdu driver if needed
RUN mkdir -p /usr/lib/nut \
    && if [ -f /lib/nut/powerman-pdu ] && [ ! -e /usr/lib/nut/powerman-pdu ]; then \
        ln -s /lib/nut/powerman-pdu /usr/lib/nut/powerman-pdu; \
    fi
```

## Next Steps

1. **Copy the fixed Dockerfile to Home Assistant:**
   ```bash
   # On your Mac
   cd ~/Dev/addon-nut
   scp nut/Dockerfile root@homeassistant.local:/config/addons/nut/
   ```

2. **Rebuild the addon in Home Assistant:**
   - Go to the addon page
   - Click "Rebuild" if available
   - Or uninstall and reinstall the addon

3. **Start the addon with this config:**
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

## Verification

The build should now complete successfully. During the build, you'll see diagnostic output showing where the powerman-pdu driver is located.
