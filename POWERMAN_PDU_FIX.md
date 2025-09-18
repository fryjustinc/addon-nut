# NUT Addon - PowerMan PDU Driver Fix

## Issue Resolution

The error `Can't start /usr/lib/nut/powerman: No such file or directory` occurs because:

1. The NUT powerman PDU driver is actually named `powerman-pdu` not `powerman`
2. The driver is installed at `/lib/nut/powerman-pdu` by the `nut-powerman-pdu` package
3. The driver name in configurations must be `powerman-pdu`

## Corrected Configuration

Here's your corrected configuration:

```yaml
users:
  - username: homeassistant
    password: coolie
    instcmds:
      - all
    actions:
      - set
      - fsd
    upsmon: master

devices:
  # APC Smart-UPS with NMC2 (SNMP) - This part was working
  - name: smart_ups
    driver: snmp-ups
    port: 192.168.51.124
    config:
      - community = "private"
      - snmp_version = "v1"
      - pollfreq = 15
      - desc = "Rack UPS - Primary Power"
  
  # APC AP7900B PDU - CORRECTED DRIVER NAME
  - name: rack_pdu
    driver: powerman-pdu  # <-- Changed from "powerman" to "powerman-pdu"
    port: "powerman://localhost:10101"
    config: []
    powerman_device: "apc_pdu"

powerman:
  enabled: true
  devices:
    - name: apc_pdu
      type: apc
      host: 192.168.51.27
      username: apc
      password: apc
      nodes: "outlet[1-8]"  # <-- Make sure this is quoted

mode: netserver
shutdown_host: "false"
```

## Key Changes Made

### 1. Driver Name
- **OLD**: `driver: powerman`
- **NEW**: `driver: powerman-pdu`

### 2. Dockerfile Updates
- Re-added `nut-powerman-pdu` package
- Added permission fixes for `/var/run/nut`

### 3. Service Scripts
- Updated to check for `powerman-pdu` driver

## Additional Notes

### SNMP UPS (SMT2200RM2UC)
Your SNMP UPS was detected successfully:
- Model: Smart-UPS 1500 (detected)
- IP: 192.168.51.124
- MIB: apcc 1.6

The warning about the sysOID can be ignored - it's working with the classic MIB detection.

### PowerMan PDU (AP7900B)
For the PDU to work:
1. Ensure telnet is enabled on the PDU (port 23)
2. Verify credentials (default: apc/apc)
3. Check network connectivity: `telnet 192.168.51.27 23`

## Testing After Rebuild

1. **Rebuild the addon** with the updated Dockerfile
2. **Apply the corrected configuration** (with `powerman-pdu` driver)
3. **Check logs** for successful startup
4. **Test connectivity**:
   ```bash
   # Test SNMP UPS
   upsc smart_ups@localhost
   
   # Test PDU (after PowerMan starts)
   powerman -h localhost:10101 -l
   ```

## Troubleshooting Commands

```bash
# Check if services are running
ps aux | grep -E "(upsd|upsmon|powermand)"

# Check NUT device list
upsc -l

# View detailed logs
ha addon logs a0d7b954-nut --lines=100

# Test network connectivity
ping 192.168.51.124  # UPS NMC
ping 192.168.51.27   # PDU
```

## Common Issues and Solutions

| Issue | Solution |
|-------|----------|
| powerman: No such file or directory | Use `powerman-pdu` driver, not `powerman` |
| Permission denied on socket | Fixed in Dockerfile with chmod 0770 /var/run/nut |
| PowerMan daemon not starting | Check if powerman-pdu driver is in devices |
| Can't connect to PDU | Enable telnet on PDU, check firewall |

## Summary

The main issue was using the wrong driver name. The correct driver for PowerMan PDUs in NUT is `powerman-pdu`, not `powerman`. With this change and the Dockerfile updates, both your UPS and PDU should work correctly.
