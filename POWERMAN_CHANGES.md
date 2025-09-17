# PowerMan PDU Support - Changes Summary

This document summarizes the changes made to add PowerMan driver support for PDUs to the NUT Home Assistant addon.

## Files Modified

1. **nut/Dockerfile**
   - Added `nut-powerman` and `powerman` packages to the installation list

2. **nut/config.yaml**
   - Added PowerMan configuration schema
   - Added device-level PowerMan options (powerman_host, powerman_port, powerman_device)
   - Added example PowerMan configuration in comments

3. **nut/.README.j2**
   - Updated description to mention PDU support
   - Added section about PowerMan PDU support

4. **nut/DOCS.md**
   - Added comprehensive PowerMan PDU Support section
   - Included configuration examples
   - Added troubleshooting guide

5. **nut/rootfs/etc/cont-init.d/nut.sh**
   - Added PowerMan device configuration logic
   - Added handling for powerman driver in device configuration
   - Creates PowerMan device files based on PDU type

## Files Created

1. **nut/rootfs/etc/powerman/powerman.conf**
   - Main PowerMan daemon configuration file

2. **nut/rootfs/etc/services.d/powerman/run**
   - S6 service script to run PowerMan daemon

3. **nut/rootfs/etc/services.d/powerman/finish**
   - S6 service finish script for PowerMan daemon

4. **nut/rootfs/usr/bin/test-powerman**
   - Helper script to test PowerMan connectivity (optional debugging tool)

5. **nut/rootfs/usr/bin/test-apc-ap7900b**
   - Specific test script for APC AP7900B PDUs

6. **nut/examples/apc-ap7900b-config.yaml**
   - Complete configuration example for APC AP7900B

7. **nut/examples/README.md**
   - Documentation for example configurations

## Configuration Example

```yaml
users:
  - username: nutadmin
    password: strongpassword
    instcmds:
      - all
    actions: []

devices:
  # Traditional UPS
  - name: myups
    driver: usbhid-ups
    port: auto
    config: []
  
  # PDU via PowerMan
  - name: serverpdu
    driver: powerman
    port: "powerman://localhost:10101"
    powerman_device: "rack_pdu"
    config: []

powerman:
  enabled: true
  devices:
    - name: rack_pdu
      type: ipmipower
      host: 192.168.1.50
      username: ADMIN
      password: ADMIN
      nodes: "outlet[1-8]"

mode: netserver
shutdown_host: "false"
```

## Supported PDU Types

- **ipmipower**: IPMI-based PDUs (most server rack PDUs)
- **apc**: APC MasterSwitch and AP series (including AP7900B)
- **baytech**: Baytech RPC series
- **raritan-px**: Raritan PX series
- Additional types can be added by extending the case statement in nut.sh

## APC AP7900B Specific Configuration

The APC AP7900B is a popular 8-outlet switched rack PDU. Configuration example:

```yaml
devices:
  - name: rack_pdu
    driver: powerman
    port: "powerman://localhost:10101"
    powerman_device: "apc_pdu"

powerman:
  enabled: true
  devices:
    - name: apc_pdu
      type: apc
      host: 192.168.1.75  # Your AP7900B IP address
      username: apc        # Default username
      password: yourpass   # Change from default!
      nodes: "outlet[1-8]" # 8 outlets on AP7900B
```

### AP7900B Setup Requirements:

1. **Network Configuration**:
   - Configure static IP address on the PDU
   - Enable telnet access (port 23)
   - Verify web interface is accessible

2. **Security**:
   - Change default credentials (apc/apc)
   - Consider network segmentation for management network

3. **Firmware**:
   - Update to AOS v3.9.2 or later for best compatibility
   - Available from APC/Schneider Electric website

## How It Works

1. When PowerMan is enabled in configuration, the addon:
   - Starts the PowerMan daemon (powermand)
   - Creates device configuration files in /etc/powerman/devices/
   - Configures NUT to use the powerman driver

2. The powerman driver in NUT communicates with the PowerMan daemon
3. PowerMan daemon handles the actual PDU communication
4. NUT exposes PDU status through standard NUT protocol

## Testing

After building and installing the updated addon:

1. Configure your PDU in the addon configuration
2. Start the addon
3. Check logs for any errors
4. Run `test-powerman` script for connectivity testing
5. Add the PDU to Home Assistant using the NUT integration

## Security Considerations

- PowerMan credentials are stored in plain text
- Ensure Home Assistant instance is properly secured
- Consider network segmentation for PDU management

## Future Enhancements

- Add support for more PDU types
- Implement credential encryption
- Add PDU-specific sensors and controls
- Create custom Home Assistant integration for PDU control functions
