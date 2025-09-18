# Home Assistant Community Add-on: Network UPS Tools

[![Release][release-shield]][release] ![Project Stage][project-stage-shield] ![Project Maintenance][maintenance-shield]

[![Discord][discord-shield]][discord] [![Community Forum][forum-shield]][forum]

A Network UPS Tools daemon to allow you to easily manage battery backup (UPS) and Power Distribution Unit (PDU) devices connected to your Home Assistant machine.

## About

The primary goal of the Network UPS Tools (NUT) project is to provide support for Power Devices, such as Uninterruptible Power Supplies, Power Distribution Units, Automatic Transfer Switch, Power Supply Units and Solar Controllers.

This fork adds PowerMan PDU support, allowing you to monitor and control network-connected PDUs alongside traditional UPS devices.

### Features

- Monitor UPS devices via USB, SNMP, and network connections
- **NEW: Monitor and control PDU outlets via PowerMan**
- Support for 140+ manufacturers and thousands of UPS models
- Support for APC, IPMI, and Baytech PDUs
- Uniform control and management interface
- Integration with Home Assistant via NUT integration

## Supported Devices

### UPS Devices
- More than 140 different manufacturers
- Several thousand models are [compatible][nut-compatible]
- USB, Serial, SNMP, and network connections

### PDU Devices (via PowerMan)
- APC Switched Rack PDUs (AP7900 series)
- IPMI-based PDUs
- Baytech RPC series
- Other PowerMan-supported devices

## Installation

The installation of this add-on is straightforward and not different from installing any other Home Assistant add-on.

1. Add this repository to your Home Assistant instance
2. Search for the "Network UPS Tools" add-on
3. Click the "Install" button
4. Configure the add-on (see Configuration section)
5. Start the add-on
6. Add the NUT integration in Home Assistant

## Configuration

See the Documentation tab for detailed configuration options and examples.

### Quick Start - USB UPS

```yaml
users:
  - username: nutuser
    password: changeme
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

### Quick Start - APC PDU with PowerMan

```yaml
users:
  - username: nutuser
    password: changeme
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
      host: 192.168.1.100  # Your PDU IP
      username: apc
      password: apc
      nodes: "outlet[1-8]"
mode: netserver
shutdown_host: "false"
```

## Support

Got questions?

You have several options to get them answered:

- The [Home Assistant Community Add-ons Discord chat server][discord]
- The [Home Assistant Discord chat server][discord-ha]
- The Home Assistant [Community Forum][forum]
- Join the [Reddit subreddit][reddit] in [/r/homeassistant][reddit]

[buymeacoffee-shield]: https://www.buymeacoffee.com/assets/img/guidelines/download-assets-sm-2.svg
[buymeacoffee]: https://www.buymeacoffee.com/dale3h
[discord-shield]: https://img.shields.io/discord/478094546522079232.svg
[discord]: https://discord.me/hassioaddons
[discord-ha]: https://discord.gg/c5DvZ4e
[forum-shield]: https://img.shields.io/badge/community-forum-brightgreen.svg
[forum]: https://community.home-assistant.io/t/community-hass-io-add-on-network-ups-tools/68516
[maintenance-shield]: https://img.shields.io/maintenance/yes/2025.svg
[nut-acknowledgements]: https://networkupstools.org/acknowledgements.html
[nut-compatible]: https://networkupstools.org/stable-hcl.html
[nut-features]: https://networkupstools.org/features.html
[nut-ha-docs]: https://www.home-assistant.io/integrations/nut/
[project-stage-shield]: https://img.shields.io/badge/project%20stage-experimental-yellow.svg
[reddit]: https://reddit.com/r/homeassistant
[release-shield]: https://img.shields.io/badge/version-dev-blue.svg
[release]: https://github.com/hassio-addons/addon-nut
