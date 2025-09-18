# PowerMan PDU Support for Network UPS Tools Addon

This fork adds PowerMan PDU (Power Distribution Unit) support to the Home Assistant Network UPS Tools addon, allowing you to monitor and control network-connected PDUs alongside traditional UPS devices.

## Features

- Monitor PDU outlet status through NUT
- Control PDU outlets (on/off/cycle) via NUT commands
- Support for multiple PDU types:
  - APC Switched Rack PDUs (AP7900 series)
  - IPMI-based PDUs
  - Baytech PDUs
  - Other PowerMan-supported devices
- Simultaneous monitoring of UPS and PDU devices
- Integration with Home Assistant via NUT integration

## Supported PDU Models

### APC PDUs
- AP7900 (Switched Rack PDU, 8 outlets)
- AP7900B (Switched Rack PDU, 8 outlets)
- AP7901 (Switched Rack PDU, 8 outlets)
- AP7920 (Switched Rack PDU, 8 outlets)
- AP7921 (Switched Rack PDU, 8 outlets)
- AP7930 (Switched Rack PDU, 24 outlets)
- AP7931 (Switched Rack PDU, 16 outlets)
- AP8953 (Switched Rack PDU, 24 outlets)

### IPMI-based PDUs
- Any PDU supporting IPMI power control

### Other Supported PDUs
- Baytech RPC series
- See PowerMan documentation for full list

## Installation

1. Add this repository to your Home Assistant addon repositories:
   - Go to Settings → Add-ons → Add-on Store
   - Click the three dots menu → Repositories
   - Add: `https://github.com/yourusername/addon-nut`

2. Install the "Network UPS Tools" addon from the store

3. Configure the addon (see Configuration section)

4. Start the addon

5. Add the NUT integration in Home Assistant:
   - Go to Settings → Devices & Services
   - Add Integration → Network UPS Tools (NUT)
   - Host: `a0d7b954-nut`
   - Port: `3493`
   - Username/Password: As configured in addon

## Configuration

### Basic APC PDU Configuration

```yaml
users:
  - username: "nutuser"
    password: "your_strong_password"
    instcmds:
      - all
    actions: []

devices:
  - name: rack_pdu
    driver: powerman-pdu
    port: powerman://localhost:10101
    config: []
    powerman_device: apc_pdu1

powerman:
  enabled: true
  devices:
    - name: apc_pdu1
      type: apc
      host: 192.168.1.100  # Your PDU IP address
      username: apc         # PDU username
      password: apc         # PDU password
      nodes: "outlet[1-8]"  # Outlet mapping

mode: netserver
shutdown_host: "false"
```

### Combined UPS and PDU Configuration

```yaml
users:
  - username: "nutuser"
    password: "your_strong_password"
    instcmds:
      - all
    actions: []

devices:
  # USB-connected UPS
  - name: main_ups
    driver: usbhid-ups
    port: auto
    config: []
    
  # PowerMan-managed PDU
  - name: rack_pdu
    driver: powerman-pdu
    port: powerman://localhost:10101
    config: []
    powerman_device: apc_pdu1

powerman:
  enabled: true
  devices:
    - name: apc_pdu1
      type: apc
      host: 192.168.1.100
      username: apc
      password: apc
      nodes: "outlet[1-8]"

mode: netserver
shutdown_host: "false"
```

## Home Assistant Integration

Once configured, your PDU will appear in Home Assistant through the NUT integration:

### Entities Created
- `sensor.rack_pdu_status` - PDU status
- `sensor.rack_pdu_outlet_1_status` - Outlet 1 status
- `sensor.rack_pdu_outlet_2_status` - Outlet 2 status
- ... (for each outlet)

### Available Services
- `nut.set_variable` - Control outlet state
- `nut.run_command` - Execute outlet commands

### Example Automation

```yaml
automation:
  - alias: "Turn off non-critical equipment on power loss"
    trigger:
      - platform: state
        entity_id: sensor.main_ups_status
        to: "OB"  # On Battery
    action:
      - service: nut.run_command
        data:
          device_name: rack_pdu
          command: outlet.5.shutdown.return
```

## Troubleshooting

### Enable Debug Logging

Add to configuration:
```yaml
log_level: debug
```

### Test PowerMan Connection

1. SSH into Home Assistant
2. Enter the addon container:
   ```bash
   docker exec -it addon_a0d7b954_nut /bin/bash
   ```
3. Test PowerMan:
   ```bash
   powerman -h localhost -q
   ```

### Common Issues

**PDU not responding:**
- Check network connectivity to PDU
- Verify PDU credentials
- Ensure SNMP/Telnet is enabled on PDU

**Driver not found:**
- Rebuild the addon after updates
- Check logs for driver path issues

**PowerMan daemon not starting:**
- Check powerman.enabled is set to true
- Verify powerman configuration syntax

## Advanced Configuration

### IPMI PDU Configuration

```yaml
powerman:
  enabled: true
  devices:
    - name: server_pdu
      type: ipmipower
      host: 192.168.1.200
      username: ADMIN
      password: ADMIN
      nodes: "server[1-8]"
```

### Multiple PDUs

```yaml
devices:
  - name: pdu1
    driver: powerman-pdu
    port: powerman://localhost:10101
    config: []
    powerman_device: apc_pdu1
    
  - name: pdu2
    driver: powerman-pdu
    port: powerman://localhost:10101
    config: []
    powerman_device: apc_pdu2

powerman:
  enabled: true
  devices:
    - name: apc_pdu1
      type: apc
      host: 192.168.1.101
      username: apc
      password: apc
      nodes: "pdu1_outlet[1-8]"
      
    - name: apc_pdu2
      type: apc
      host: 192.168.1.102
      username: apc
      password: apc
      nodes: "pdu2_outlet[1-8]"
```

## Security Considerations

1. **Change default PDU passwords** - Most PDUs ship with default credentials (apc/apc)
2. **Use strong passwords** - Both for NUT users and PDU access
3. **Network isolation** - Consider placing PDUs on a management VLAN
4. **Access control** - Limit which users can execute outlet commands

## Contributing

Issues and pull requests are welcome at: https://github.com/yourusername/addon-nut

## License

This addon is licensed under the MIT License, same as the original Home Assistant Community Addons.

## Credits

- Original NUT addon by [Dale Higgs](https://github.com/dale3h)
- PowerMan integration added by [Your Name]
- PowerMan project: https://github.com/chaos/powerman
- Network UPS Tools project: https://networkupstools.org/

## Changelog

### v1.0.0 - PowerMan Support
- Added PowerMan daemon integration
- Added powerman-pdu driver support
- Support for APC Switched Rack PDUs
- Support for IPMI-based PDUs
- Configuration examples for PDU setups
- Fixed driver path issues
- Improved documentation
