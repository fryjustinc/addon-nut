# APC Device Quick Reference Card

## APC Smart-UPS (Network) - Quick Config

```yaml
# Minimal configuration for APC Smart-UPS with NMC2
devices:
  - name: ups
    driver: snmp-ups
    port: YOUR_NMC_IP_HERE  # e.g., 192.168.1.50
    config:
      - community = "private"  # Change this!
```

**Before using:**
1. Set static IP on NMC2: `http://[nmc-ip]` → Network → TCP/IP
2. Change SNMP community: Network → SNMPv1 → Change "private" 
3. Update firmware if needed

**Test connection:**
```bash
/usr/bin/test-snmp-ups
```

---

## APC AP7900B PDU - Quick Config

```yaml
# Minimal configuration for APC AP7900B PDU
devices:
  - name: pdu
    driver: powerman
    port: "powerman://localhost:10101"
    powerman_device: "my_pdu"

powerman:
  enabled: true
  devices:
    - name: my_pdu
      type: apc
      host: YOUR_PDU_IP_HERE  # e.g., 192.168.1.75
      username: apc            # Change this!
      password: apc            # Change this!
      nodes: "outlet[1-8]"
```

**Before using:**
1. Enable telnet: `http://[pdu-ip]` → Network → Telnet Enable
2. Change default password: Security → User Management
3. Set static IP: Network → TCP/IP

**Test connection:**
```bash
/usr/bin/test-apc-ap7900b
```

---

## Combined UPS + PDU Config

```yaml
users:
  - username: nutadmin
    password: YourSecurePassword  # CHANGE!
    instcmds: ["all"]
    actions: []

devices:
  # APC Smart-UPS (SNMP)
  - name: ups
    driver: snmp-ups
    port: 192.168.1.50  # NMC2 IP
    config:
      - community = "private"
  
  # APC PDU (PowerMan)
  - name: pdu
    driver: powerman
    port: "powerman://localhost:10101"
    powerman_device: "rack_pdu"

powerman:
  enabled: true
  devices:
    - name: rack_pdu
      type: apc
      host: 192.168.1.75  # PDU IP
      username: admin
      password: YourPDUPassword
      nodes: "outlet[1-8]"

mode: netserver
shutdown_host: "false"
```

---

## Common NUT Variables

### UPS Status Values
- `OL` = Online (normal)
- `OB` = On Battery
- `LB` = Low Battery
- `RB` = Replace Battery
- `CHRG` = Charging
- `DISCHRG` = Discharging
- `BYPASS` = Bypass Active
- `CAL` = Calibrating
- `OFF` = Offline

### Key Sensors to Monitor
```yaml
# In Home Assistant automations
sensor.ups_status          # OL, OB, LB
sensor.ups_battery_charge  # 0-100%
sensor.ups_battery_runtime # seconds
sensor.ups_load            # 0-100%
sensor.ups_input_voltage   # VAC
```

---

## Quick Troubleshooting

| Problem | Check This |
|---------|------------|
| Can't connect to UPS | `ping [nmc-ip]`, check SNMP enabled |
| Wrong community string | Default: public/private, check NMC2 settings |
| PDU not responding | Telnet enabled? `telnet [pdu-ip] 23` |
| No sensors in HA | Check addon logs, restart addon |
| Auth failed | Default: apc/apc, check if locked out |

---

## Security Checklist

- [ ] Changed default passwords (apc/apc)
- [ ] Changed SNMP community strings
- [ ] Set static IP addresses
- [ ] Updated firmware
- [ ] Enabled HTTPS (disable HTTP)
- [ ] Configured firewall rules
- [ ] Placed on management VLAN
- [ ] Disabled unused services

---

## Useful Commands

```bash
# View addon logs
ha addon logs a0d7b954-nut

# Test SNMP UPS
/usr/bin/test-snmp-ups

# Test PDU
/usr/bin/test-apc-ap7900b

# Query UPS status
upsc ups@localhost

# List all devices
upsc -l

# PowerMan PDU status
powerman -h localhost:10101 -q

# Manual SNMP test
snmpwalk -v1 -c private [ip] .1.3.6.1.4.1.318
```

---

## Home Assistant Integration

1. **Add Integration:**
   - Settings → Devices & Services → Add → NUT
   - Host: `a0d7b954-nut`
   - Port: `3493`
   - Username/Password from config

2. **Example Automation:**
```yaml
automation:
  - alias: "UPS on battery"
    trigger:
      platform: state
      entity_id: sensor.ups_status
      to: "OB"
    action:
      service: notify.mobile_app
      data:
        title: "⚡ Power Outage"
        message: "UPS on battery!"
```

---

## Support Links

- **NUT Addon Issues**: https://github.com/hassio-addons/addon-nut/issues
- **APC Support**: https://www.apc.com/support/
- **NUT Docs**: https://networkupstools.org/
- **HA Forum**: https://community.home-assistant.io/
