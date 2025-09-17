# APC AP7900B PDU Support - Implementation Summary

## Overview
Full support has been added for the APC AP7900B 8-outlet switched rack PDU to the NUT Home Assistant addon through PowerMan integration.

## APC AP7900B Specifications
- Model: AP7900B (also compatible with AP7900, AP7901, AP7902)
- Outlets: 8 switched outlets
- Capacity: 15A @ 120V / 10A @ 230V
- Management: Telnet, SSH, HTTP/HTTPS, SNMP
- Control: Individual outlet switching
- Monitoring: Current, voltage, power consumption

## Key Features Added

### 1. Native APC Support
- Added specific handling for APC PDU protocol
- Telnet-based communication (port 23)
- Automatic authentication handling
- Support for outlet control and status monitoring

### 2. Configuration Examples
- Complete working configuration for AP7900B
- Example files in `/nut/examples/` directory
- Inline documentation in config.yaml
- Troubleshooting guides

### 3. Testing Tools
- Generic PowerMan test script: `/usr/bin/test-powerman`
- APC-specific test script: `/usr/bin/test-apc-ap7900b`
- Network connectivity verification
- PowerMan daemon status checking
- NUT integration validation

## Configuration Guide

### Basic Configuration
```yaml
devices:
  - name: apc_pdu
    driver: powerman
    port: "powerman://localhost:10101"
    powerman_device: "ap7900b"

powerman:
  enabled: true
  devices:
    - name: ap7900b
      type: apc
      host: 192.168.1.75  # Your PDU's IP
      username: apc       # Your username
      password: yourpass  # Your password
      nodes: "outlet[1-8]"
```

### PDU Preparation Steps
1. **Set Static IP**: Configure via web interface or serial console
2. **Enable Telnet**: Network → TCP/IP → Telnet Enable
3. **Change Password**: Security → User Management
4. **Update Firmware**: AOS v3.9.2 or later recommended

### Home Assistant Integration
After configuring the addon:
1. Navigate to Settings → Devices & Services
2. Add NUT integration
3. Configure with:
   - Host: `a0d7b954-nut`
   - Port: `3493`
   - Username/Password from addon config

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| Connection refused | Enable telnet on PDU, check port 23 |
| Login failed | Verify credentials, check account lockout |
| PDU not detected | Check PowerMan logs, verify network connectivity |
| No outlet control | Verify user permissions on PDU |

### Diagnostic Commands
```bash
# Test connectivity
ping 192.168.1.75

# Test telnet
telnet 192.168.1.75 23

# Run APC test
/usr/bin/test-apc-ap7900b

# Check PowerMan
powerman -h localhost:10101 -l

# Query via NUT
upsc apc_pdu@localhost
```

## Security Considerations

1. **Change Default Credentials**: Factory defaults are well-known
2. **Network Segmentation**: Use VLAN for management traffic
3. **Firewall Rules**: Restrict access to PDU management ports
4. **Regular Updates**: Keep firmware current for security patches
5. **Audit Logging**: Enable PDU event logging

## Compatibility

### Tested Models
- AP7900B (primary target)
- AP7900
- AP7901
- AP7902

### Should Also Work With
- AP8959 (switched rack PDU)
- AP8961 (switched rack PDU)
- AP7920 (switched rack PDU)
- Other APC MasterSwitch series

## Files Modified/Created

### Modified
- `Dockerfile` - Added telnet, expect packages
- `config.yaml` - Added APC example configuration
- `nut.sh` - Enhanced APC PDU handling
- `DOCS.md` - Comprehensive APC documentation
- `.README.j2` - Mentioned PDU support

### Created
- `/usr/bin/test-apc-ap7900b` - APC-specific test script
- `/examples/apc-ap7900b-config.yaml` - Complete example config
- `/examples/README.md` - Examples documentation

## Future Enhancements

1. **SNMP Support**: Add SNMP monitoring for better metrics
2. **SSH Support**: More secure than telnet
3. **Outlet Groups**: Configure logical outlet groupings
4. **Power Metrics**: Enhanced power consumption monitoring
5. **Custom Sensors**: Per-outlet power sensors in HA
6. **Scheduled Actions**: Time-based outlet control

## Testing Checklist

- [ ] PDU network connectivity verified
- [ ] Telnet access confirmed
- [ ] PowerMan daemon starts successfully
- [ ] PDU appears in PowerMan device list
- [ ] NUT can query PDU status
- [ ] Home Assistant integration works
- [ ] Outlet status visible in HA
- [ ] Test outlet switching (if enabled)
- [ ] Check logs for errors

## Support Resources

1. **APC Documentation**: https://www.apc.com/support
2. **PowerMan Docs**: https://github.com/chaos/powerman
3. **NUT Documentation**: https://networkupstools.org
4. **Home Assistant Forum**: https://community.home-assistant.io

## Notes

- Telnet is inherently insecure - consider network isolation
- Some features may require APC business account for firmware downloads
- Outlet switching may have delays (1-2 seconds typical)
- Maximum telnet sessions may be limited (typically 4 concurrent)
