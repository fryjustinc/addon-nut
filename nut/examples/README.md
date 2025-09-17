# NUT Addon Configuration Examples

This directory contains example configurations for various UPS and PDU devices that can be used with the Home Assistant NUT addon.

## Available Examples

### Complete Infrastructure Setup
- **apc-complete-setup.yaml** - Full configuration for APC SMT2200RM2UC UPS (with NMC2) and AP7900B PDU
  - Network-connected Smart-UPS via SNMP
  - 8-outlet switched PDU via PowerMan
  - Comprehensive setup instructions
  - Security best practices

### PDU Examples
- **apc-ap7900b-config.yaml** - Configuration specific to APC AP7900B 8-outlet switched rack PDU
  - Telnet-based control
  - Individual outlet monitoring
  - Troubleshooting guide

## Quick Start

### For APC Smart-UPS with Network Card (NMC2)
```yaml
devices:
  - name: smart_ups
    driver: snmp-ups
    port: 192.168.1.50  # NMC2 IP
    config:
      - community = "private"
      - snmp_version = "v1"
```

### For APC PDU (AP7900B)
```yaml
devices:
  - name: rack_pdu
    driver: powerman
    port: "powerman://localhost:10101"
    powerman_device: "ap7900b"

powerman:
  enabled: true
  devices:
    - name: ap7900b
      type: apc
      host: 192.168.1.75  # PDU IP
      username: apc
      password: yourpass
      nodes: "outlet[1-8]"
```

## Using These Examples

1. **Choose the appropriate example** for your hardware
2. **Copy the configuration** to your addon settings
3. **Modify critical values**:
   - IP addresses for your devices
   - Usernames and passwords (NEVER use defaults!)
   - SNMP community strings
   - Device-specific settings
4. **Save and restart** the addon
5. **Check logs** for any configuration errors
6. **Add to Home Assistant** via the NUT integration

## Important Security Notes

⚠️ **ALWAYS** change default passwords on all devices
🔒 Use SNMPv3 instead of v1/v2c when possible
🌐 Isolate management interfaces on a separate VLAN
🔐 Enable HTTPS/SSH and disable telnet when possible
📝 Keep firmware updated on all devices

## Device Compatibility

These examples should work with:
- **APC Smart-UPS**: SMT, SMX, SRT series with NMC2/NMC3
- **APC PDUs**: AP7900 series, AP8959, AP8961
- **Other SNMP UPS**: Most network-enabled UPS with SNMP support
- **Other PDUs**: IPMI-based PDUs, Baytech, Raritan (with PowerMan)

## Troubleshooting

Common issues:
- **Connection refused**: Check network connectivity and firewall rules
- **Authentication failed**: Verify credentials and SNMP community strings
- **No data**: Ensure correct driver and port configuration
- **Missing sensors**: Some features depend on device firmware version

## Contributing

If you have working configurations for other UPS or PDU models, please consider contributing them to help other users!

## Support

- [Home Assistant Community Forum](https://community.home-assistant.io/)
- [NUT Documentation](https://networkupstools.org/)
- [APC Support](https://www.apc.com/support/)
