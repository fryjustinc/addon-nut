# APC AP7900B PDU - Configuration Options

Your APC AP7900B PDU can be monitored in two different ways:

## Option 1: Using SNMP (Simpler - Recommended to Try First)

The error message shows NUT is detecting your device via SNMP as a "Smart-UPS 1500". This might actually work for basic monitoring.

```yaml
users:
  - username: "nutuser"
    password: "changeme123"
    instcmds:
      - all
    actions: []

devices:
  - name: apc_pdu
    driver: snmp-ups
    port: 192.168.51.124
    config:
      - community = private
      - mibs = apcc
      - snmp_version = v1

mode: netserver
shutdown_host: "false"
log_level: debug
```

### To enable SNMP on your APC PDU:
1. Access PDU web interface
2. Go to Network → SNMPv1 → Access
3. Enable SNMPv1
4. Set community string (default: "private" for read/write)
5. Apply changes

## Option 2: Using PowerMan (More Complex - Full Outlet Control)

If you need individual outlet control, use PowerMan:

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

### To enable Telnet on your APC PDU:
1. Access PDU web interface
2. Go to Network → Console → Telnet
3. Enable Telnet
4. Apply changes

## Option 3: Using APC-specific SNMP MIB

If the generic SNMP doesn't work well, try the APC-specific configuration:

```yaml
users:
  - username: "nutuser"
    password: "changeme123"
    instcmds:
      - all
    actions: []

devices:
  - name: apc_pdu
    driver: snmp-ups
    port: 192.168.51.124
    config:
      - community = private
      - mibs = apc_ats  # For APC Transfer Switches and PDUs
      # Or try:
      # - mibs = apc_pdu  # Specific PDU MIB if available

mode: netserver
shutdown_host: "false"
log_level: debug
```

## Debugging the Current Error

The error "Can't connect to powerman://localhost:10101" means PowerMan daemon isn't running when the driver starts. I've fixed this in the updated `nut.sh` script that starts PowerMan earlier.

## Testing Which Method Works

1. **Test SNMP connectivity:**
   ```bash
   # From Home Assistant SSH
   snmpwalk -v1 -c private 192.168.51.124 system
   ```

2. **Test Telnet connectivity:**
   ```bash
   telnet 192.168.51.124 23
   # Should see APC login prompt
   ```

3. **After addon starts, check what NUT sees:**
   ```bash
   docker exec addon_local_nut upsc apc_pdu@localhost
   ```

## Recommendation

Start with **Option 1 (SNMP)** since it's already detecting your device. The "No matching MIB" warning can be ignored if the device is working.

The sysOID '.1.3.6.1.4.1.318.1.3.27' corresponds to an APC device that's not fully recognized, but NUT falls back to generic APC MIB which should work fine for monitoring.
