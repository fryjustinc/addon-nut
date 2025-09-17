# APC Device Support Summary - NUT Home Assistant Addon

## Overview
This NUT addon now provides comprehensive support for APC power infrastructure devices, including both UPS and PDU equipment commonly used in data centers and server rooms.

## Supported APC Devices

### UPS Devices (Network-Connected via SNMP)

#### APC SMT2200RM2UC
- **Type**: Smart-UPS 2200VA/1980W Rack Mount
- **Connection**: SNMP via NMC2 (Network Management Card)
- **Driver**: `snmp-ups`
- **Key Features**:
  - 2U rack-mount form factor
  - Pure sine wave output
  - Hot-swappable batteries
  - Advanced battery management
  - Temperature monitoring
  - Automatic voltage regulation (AVR)

**Compatible Models**:
- SMT2200RM2U, SMT2200RM2UC, SMT2200RM2UTW
- SMT3000RM2U, SMT3000RM2UC (3000VA version)
- SMT1500RM2U, SMT1500RM2UC (1500VA version)
- SMX2200RMLV2U, SMX3000RMLV2U (SMX series)
- SRT2200RMXLA, SRT3000RMXLA (SRT series)

### PDU Devices (via PowerMan)

#### APC AP7900B
- **Type**: Switched Rack PDU, 8 Outlets
- **Connection**: Telnet via PowerMan
- **Driver**: `powerman` (NUT) → PowerMan daemon → Telnet
- **Key Features**:
  - 8 individually switched outlets
  - 15A @ 120V / 10A @ 230V capacity
  - Remote outlet control
  - Current monitoring
  - Sequential outlet startup/shutdown
  - Network management interface

**Compatible Models**:
- AP7900, AP7900B (8 outlets, 1U)
- AP7901, AP7902 (8 outlets, variants)
- AP7920, AP7921 (8 outlets, different mounting)
- AP8959 (16 outlets, 2U)
- AP8961 (21 outlets, 0U vertical)

## Configuration Examples

### Minimal Configuration (UPS Only)
```yaml
devices:
  - name: ups
    driver: snmp-ups
    port: 192.168.1.50  # NMC2 IP
    config:
      - community = "private"
```

### Minimal Configuration (PDU Only)
```yaml
devices:
  - name: pdu
    driver: powerman
    port: "powerman://localhost:10101"
    powerman_device: "apc_pdu"

powerman:
  enabled: true
  devices:
    - name: apc_pdu
      type: apc
      host: 192.168.1.75
      username: apc
      password: changeme
      nodes: "outlet[1-8]"
```

### Complete Infrastructure Configuration
```yaml
users:
  - username: nutadmin
    password: SecurePass123!
    instcmds:
      - all
    actions:
      - set
      - fsd
    upsmon: master

devices:
  # UPS via SNMP
  - name: smart_ups
    driver: snmp-ups
    port: 192.168.1.50
    config:
      - community = "private"
      - snmp_version = "v1"
      - pollfreq = 15
      - desc = "Rack UPS - Primary Power"
  
  # PDU via PowerMan
  - name: rack_pdu
    driver: powerman
    port: "powerman://localhost:10101"
    powerman_device: "apc_pdu"

powerman:
  enabled: true
  devices:
    - name: apc_pdu
      type: apc
      host: 192.168.1.75
      username: apc
      password: SecurePass456!
      nodes: "outlet[1-8]"

mode: netserver
shutdown_host: "false"
```

## Network Management Card (NMC) Setup

### NMC2 (AP9630/AP9631)
1. **Initial Access**:
   - Serial: 9600,8,N,1
   - Default IP: DHCP
   - Default credentials: apc/apc

2. **Network Configuration**:
   ```
   Web UI → Configuration → Network → TCP/IP
   - IPv4 Configuration: Manual
   - IP Address: [Your Static IP]
   - Subnet Mask: [Your Subnet]
   - Default Gateway: [Your Gateway]
   ```

3. **SNMP Setup**:
   ```
   Web UI → Configuration → Network → SNMPv1
   - Access: Enable
   - Read Community: [Change from "public"]
   - Write Community: [Change from "private"]
   ```

### NMC3 (AP9640/AP9641)
Similar to NMC2 but with additional features:
- HTTPS support by default
- SNMPv3 support
- RESTful API
- Better performance

## Available Monitoring Data

### UPS Metrics (via SNMP)
| Metric | NUT Variable | Description |
|--------|--------------|-------------|
| Status | ups.status | OL (online), OB (on battery), LB (low battery) |
| Battery Charge | battery.charge | Percentage (0-100) |
| Runtime | battery.runtime | Seconds remaining |
| Load | ups.load | Percentage of capacity |
| Input Voltage | input.voltage | VAC input |
| Output Voltage | output.voltage | VAC output |
| Temperature | ups.temperature | Celsius |
| Test Result | ups.test.result | Last self-test result |

### PDU Metrics (via PowerMan)
| Metric | Description |
|--------|-------------|
| Outlet Status | On/Off state per outlet |
| Current Draw | Total current (if supported) |
| Power Usage | Watts (if supported) |
| Outlet Control | Switch outlets on/off |

## Testing Tools

### Test SNMP UPS Connection
```bash
/usr/bin/test-snmp-ups
```

### Test PDU Connection
```bash
/usr/bin/test-apc-ap7900b
```

### Manual SNMP Test
```bash
# Test SNMP connectivity
snmpwalk -v1 -c private 192.168.1.50 .1.3.6.1.4.1.318

# Get specific UPS data
upsc smart_ups@localhost
```

### Manual PDU Test
```bash
# Test telnet
telnet 192.168.1.75 23

# Query via PowerMan
powerman -h localhost:10101 -q apc_pdu
```

## Home Assistant Integration

### Adding Devices
1. Settings → Devices & Services
2. Add Integration → Network UPS Tools (NUT)
3. Configure:
   - Host: `a0d7b954-nut`
   - Port: `3493`
   - Username: `nutadmin`
   - Password: [Your password]

### Available Entities
- **UPS Entities**:
  - sensor.smart_ups_status
  - sensor.smart_ups_battery_charge
  - sensor.smart_ups_battery_runtime
  - sensor.smart_ups_load
  - sensor.smart_ups_input_voltage
  - sensor.smart_ups_temperature

- **PDU Entities**:
  - sensor.rack_pdu_status
  - switch.rack_pdu_outlet_1 through 8 (if supported)

### Automation Examples

#### Low Battery Notification
```yaml
automation:
  - alias: "UPS Low Battery Alert"
    trigger:
      platform: numeric_state
      entity_id: sensor.smart_ups_battery_charge
      below: 20
    action:
      service: notify.mobile_app
      data:
        title: "⚠️ UPS Low Battery"
        message: "Battery at {{ states('sensor.smart_ups_battery_charge') }}%"
        data:
          push:
            sound:
              critical: 1
              volume: 1.0
```

#### Power Outage Response
```yaml
automation:
  - alias: "Power Outage Detected"
    trigger:
      platform: state
      entity_id: sensor.smart_ups_status
      from: "OL"
      to: "OB"
    action:
      - service: notify.mobile_app
        data:
          title: "⚡ Power Outage"
          message: "Running on battery. Runtime: {{ states('sensor.smart_ups_battery_runtime') | int // 60 }} minutes"
      - service: script.shutdown_non_critical_devices
```

## Security Recommendations

### Network Security
1. **VLAN Isolation**: Place management interfaces on dedicated VLAN
2. **Firewall Rules**:
   ```
   # SNMP (UPS)
   allow tcp/443 from management_network to nmc_ip  # HTTPS
   allow udp/161 from ha_host to nmc_ip            # SNMP
   
   # Telnet (PDU) - Consider replacing with SSH
   allow tcp/23 from ha_host to pdu_ip             # Telnet
   ```

3. **Access Control**:
   - Change ALL default passwords
   - Use SNMPv3 when possible
   - Disable unused services
   - Enable HTTPS for web access
   - Configure IP access lists

### Credential Management
- Never use default credentials (apc/apc)
- Use strong, unique passwords
- Rotate credentials regularly
- Consider using Home Assistant secrets.yaml

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| SNMP timeout | Check firewall, verify community string |
| PDU connection refused | Enable telnet on PDU |
| No UPS data | Update NMC firmware, check SNMP version |
| Authentication failed | Verify credentials, check account lockout |
| Missing sensors | Some metrics require newer firmware |

### Debug Commands
```bash
# Check addon logs
ha addon logs a0d7b954-nut

# Test network connectivity
ping 192.168.1.50  # UPS NMC
ping 192.168.1.75  # PDU

# Verify services running
ps aux | grep -E "(upsd|upsmon|powermand)"

# Check NUT status
upsc -l
```

## Firmware Requirements

### Recommended Minimum Versions
- **UPS Firmware**: AOS 6.8.2 or later
- **NMC2 Firmware**: 7.1.0 or later
- **NMC3 Firmware**: 1.2.0 or later
- **PDU Firmware**: AOS 3.9.2 or later

### Update Process
1. Download from Schneider Electric website
2. Access device web interface
3. Administration → Firmware Update
4. Upload and apply firmware
5. Device will reboot automatically

## Support Resources

- **Home Assistant Community**: https://community.home-assistant.io/
- **NUT Documentation**: https://networkupstools.org/
- **APC Support**: https://www.apc.com/support/
- **Schneider Electric**: https://www.se.com/

## Contributing

To add support for additional APC models:
1. Test with your device
2. Document configuration
3. Submit example to repository
4. Include test results and any special requirements

## License

This addon extension maintains the MIT License of the original NUT addon.
