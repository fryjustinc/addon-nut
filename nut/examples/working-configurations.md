# Working Configuration Examples

## APC AP7900B PDU Configuration (Using PowerMan)

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

# PowerMan configuration (simplified flat structure)
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

## USB UPS Configuration

```yaml
users:
  - username: "nutuser"
    password: "changeme123"
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

## SNMP UPS Configuration

```yaml
users:
  - username: "nutuser"
    password: "changeme123"
    instcmds:
      - all
    actions: []

devices:
  - name: smart_ups
    driver: snmp-ups
    port: 192.168.1.50
    config:
      - community = private
      - mibs = apcc

mode: netserver
shutdown_host: "false"
```

## Combined UPS and PDU

```yaml
users:
  - username: "nutuser"
    password: "changeme123"
    instcmds:
      - all
    actions: []

devices:
  # USB UPS
  - name: main_ups
    driver: usbhid-ups
    port: auto
    config: []
  
  # PowerMan PDU
  - name: rack_pdu
    driver: powerman-pdu
    port: powerman://localhost:10101
    config: []

# PowerMan configuration
powerman_enabled: true
powerman_pdu_name: apc_pdu
powerman_pdu_type: apc
powerman_pdu_host: 192.168.51.124
powerman_pdu_username: apc
powerman_pdu_password: apc
powerman_pdu_nodes: "outlet[1-8]"

mode: netserver
shutdown_host: "false"
log_level: info
```

## IPMI-based PDU Configuration

```yaml
users:
  - username: "nutuser"
    password: "changeme123"
    instcmds:
      - all
    actions: []

devices:
  - name: server_pdu
    driver: powerman-pdu
    port: powerman://localhost:10101
    config: []

powerman_enabled: true
powerman_pdu_name: ipmi_pdu
powerman_pdu_type: ipmipower
powerman_pdu_host: 192.168.1.100
powerman_pdu_username: admin
powerman_pdu_password: changeme
powerman_pdu_nodes: "server[1-8]"

mode: netserver
shutdown_host: "false"
```
