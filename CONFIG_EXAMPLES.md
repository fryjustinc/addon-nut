# Network UPS Tools - PowerMan PDU Configuration Examples

## USB-connected UPS (standard configuration)
```yaml
users:
  - username: "nutuser"
    password: "strongpassword123"
    instcmds:
      - all
    actions: []
devices:
  - name: myups
    driver: usbhid-ups
    port: auto
    config: []
mode: netserver
shutdown_host: "false"
```

## APC Smart-UPS with Network Management Card (SNMP)
```yaml
users:
  - username: "nutuser"
    password: "strongpassword123"
    instcmds:
      - all
    actions: []
devices:
  - name: smart_ups
    driver: snmp-ups
    port: 192.168.1.50  # NMC2 IP address
    config:
      - community = "private"  # SNMP community
      - snmp_version = "v1"   # or v2c, v3
      - mibs = "apcc"  # APC MIB
mode: netserver
shutdown_host: "false"
```

## APC AP7900B PDU with PowerMan (8-outlet switched rack PDU)
```yaml
users:
  - username: "nutuser"
    password: "strongpassword123"
    instcmds:
      - all
    actions: []
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
      host: 192.168.51.124  # Your PDU IP
      username: apc
      password: apc
      nodes: "outlet[1-8]"
mode: netserver
shutdown_host: "false"
```

## Multiple Devices (UPS + PDU)
```yaml
users:
  - username: "nutuser"
    password: "strongpassword123"
    instcmds:
      - all
    actions: []
devices:
  # USB UPS
  - name: main_ups
    driver: usbhid-ups
    port: auto
    config: []
  # SNMP UPS
  - name: smart_ups
    driver: snmp-ups
    port: 192.168.1.50
    config:
      - community = "private"
      - mibs = "apcc"
  # PowerMan PDU
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
      host: 192.168.51.124
      username: apc
      password: apc
      nodes: "outlet[1-8]"
mode: netserver
shutdown_host: "false"
log_level: debug  # Use for troubleshooting
```

## IPMI-based PDUs with PowerMan
```yaml
users:
  - username: "nutuser"
    password: "strongpassword123"
    instcmds:
      - all
    actions: []
devices:
  - name: server_pdu
    driver: powerman-pdu
    port: powerman://localhost:10101
    config: []
    powerman_device: ipmi_pdu1
powerman:
  enabled: true
  devices:
    - name: ipmi_pdu1
      type: ipmipower
      host: 192.168.1.100
      username: admin
      password: changeme
      nodes: "outlet[1-8]"
mode: netserver
shutdown_host: "false"
```

## Notes:
1. Always use strong passwords for production systems
2. Replace IP addresses with your actual device IPs
3. For APC PDUs, default credentials are often apc/apc but should be changed
4. PowerMan support requires the addon to build and run powermand
5. Use `log_level: debug` when troubleshooting connection issues
6. The `shutdown_host` option determines if the entire Home Assistant host shuts down on UPS low battery
