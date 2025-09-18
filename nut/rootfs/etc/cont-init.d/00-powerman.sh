#!/command/with-contenv bashio
# ==============================================================================
# Home Assistant Community Add-on: Network UPS Tools
# Configure and START PowerMan for PDU support
# ==============================================================================

# Check if powerman is enabled or if we have powerman-pdu devices
has_powerman=false

# First check the explicit powerman_enabled flag
if bashio::config.has_value 'powerman_enabled' && bashio::config.true 'powerman_enabled' ;then
    has_powerman=true
    bashio::log.info "PowerMan explicitly enabled via configuration"
fi

# Also check if any device uses the powerman-pdu driver
for device in $(bashio::config "devices|keys"); do
    driver=$(bashio::config "devices[${device}].driver")
    if [[ "${driver}" == "powerman-pdu" ]]; then
        has_powerman=true
        bashio::log.info "Found powerman-pdu device, enabling PowerMan"
        break
    fi
done

if [[ "${has_powerman}" == "false" ]]; then
    bashio::log.info "PowerMan not needed, skipping configuration"
    exit 0
fi

bashio::log.info "Configuring PowerMan daemon..."

# Create powerman config directory if it doesn't exist
mkdir -p /etc/powerman/devices

# Start building the powerman.conf file
cat > /etc/powerman/powerman.conf << 'EOF'
# PowerMan configuration for NUT addon
# Auto-generated - do not edit

# Listen on all interfaces for NUT connections
listen "0.0.0.0:10101"

# Include device specifications
include "/etc/powerman/devices/apcpdu3.dev"

EOF

# Check if we have explicit powerman PDU configuration
if bashio::config.has_value 'powerman_pdu_name' && \
   bashio::config.has_value 'powerman_pdu_type' && \
   bashio::config.has_value 'powerman_pdu_host' ;then
    
    pdu_name=$(bashio::config 'powerman_pdu_name')
    pdu_type=$(bashio::config 'powerman_pdu_type')
    pdu_host=$(bashio::config 'powerman_pdu_host')
    pdu_username=""
    pdu_password=""
    pdu_nodes=""
    
    if bashio::config.has_value 'powerman_pdu_username' ;then
        pdu_username=$(bashio::config 'powerman_pdu_username')
    fi
    
    if bashio::config.has_value 'powerman_pdu_password' ;then
        pdu_password=$(bashio::config 'powerman_pdu_password')
    fi
    
    if bashio::config.has_value 'powerman_pdu_nodes' ;then
        pdu_nodes=$(bashio::config 'powerman_pdu_nodes')
    fi
    
    bashio::log.info "Configuring explicit PDU: ${pdu_name} (${pdu_type} at ${pdu_host})"
    
    # Build device command based on PDU type
    case "${pdu_type}" in
        "apc"|"apcpdu"|"apc7900"|"apc7900b"|"apc7920"|"apc7940"|"apc8959")
            # APC PDUs via telnet
            bashio::log.info "Configuring APC PDU via telnet"
            echo "device \"${pdu_name}\" \"apcpdu3\" \"telnet:${pdu_host}:23 |&\"" >> /etc/powerman/powerman.conf
            ;;
        "ipmipower")
            # IPMI-based PDUs
            if [[ -n "${pdu_username}" ]] && [[ -n "${pdu_password}" ]]; then
                echo "device \"${pdu_name}\" \"ipmipower\" \"/usr/sbin/ipmipower -h ${pdu_host} -u ${pdu_username} -p ${pdu_password} |&\"" >> /etc/powerman/powerman.conf
            else
                bashio::log.warning "IPMI PDU requires username and password"
            fi
            ;;
        *)
            # Generic device
            echo "device \"${pdu_name}\" \"${pdu_type}\" \"${pdu_host}\"" >> /etc/powerman/powerman.conf
            ;;
    esac
    
    # Add node configuration
    if [[ -n "${pdu_nodes}" ]]; then
        echo "node \"${pdu_nodes}\" \"${pdu_name}\"" >> /etc/powerman/powerman.conf
    else
        # Default node configuration for 8-outlet PDU
        # APC PDUs use simple numeric plug names: 1, 2, 3, etc.
        echo "node \"[1-8]\" \"${pdu_name}\"" >> /etc/powerman/powerman.conf
    fi
fi

# Parse devices for inline powerman configuration
for device in $(bashio::config "devices|keys"); do
    driver=$(bashio::config "devices[${device}].driver")
    
    if [[ "${driver}" == "powerman-pdu" ]]; then
        name=$(bashio::config "devices[${device}].name")
        port=$(bashio::config "devices[${device}].port")
        
        # Skip if already configured explicitly
        if bashio::config.has_value 'powerman_pdu_name' && [[ "$(bashio::config 'powerman_pdu_name')" == "${name}" ]]; then
            continue
        fi
        
        bashio::log.info "Processing powerman-pdu device: ${name}"
        
        # Extract powerman configuration from device config
        pdu_type=""
        pdu_dev=""
        
        for configitem in $(bashio::config "devices[${device}].config"); do
            # Match powerman_pdu = value or powerman_pdu=value with or without quotes
            if [[ "${configitem}" =~ powerman_pdu[[:space:]]*=[[:space:]]*[\"\']?([^\"\']+)[\"\']? ]]; then
                pdu_type="${BASH_REMATCH[1]}"
                bashio::log.debug "Found PDU type: ${pdu_type}"
            fi
            if [[ "${configitem}" =~ powerman_dev[[:space:]]*=[[:space:]]*[\"\']?([^\"\']+)[\"\']? ]]; then
                pdu_dev="${BASH_REMATCH[1]}"
                bashio::log.debug "Found PDU device: ${pdu_dev}"
            fi
        done
        
        # If we didn't find explicit config, try to extract from the port
        if [[ -z "${pdu_dev}" ]] && [[ "${port}" =~ powerman://.*@(.*) ]]; then
            pdu_dev="${BASH_REMATCH[1]}"
            bashio::log.debug "Extracted PDU device from port: ${pdu_dev}"
        fi
        
        # Default to apcpdu if no type specified
        if [[ -z "${pdu_type}" ]]; then
            pdu_type="apcpdu"
            bashio::log.info "No PDU type specified, defaulting to: ${pdu_type}"
        fi
        
        # Add device to powerman config if we have the required info
        if [[ -n "${pdu_dev}" ]]; then
            bashio::log.info "Adding PDU device to PowerMan: ${name} (${pdu_type} at ${pdu_dev})"
            # For APC PDUs, use telnet connection
            if [[ "${pdu_type}" == "apc"* ]]; then
                bashio::log.info "Adding APC PDU device via telnet: ${name}"
                echo "device \"${name}\" \"apcpdu3\" \"telnet:${pdu_dev}:23 |&\"" >> /etc/powerman/powerman.conf
            else
                echo "device \"${name}\" \"${pdu_type}\" \"${pdu_dev}\"" >> /etc/powerman/powerman.conf
            fi
            echo "node \"[1-8]\" \"${name}\"" >> /etc/powerman/powerman.conf
        else
            bashio::log.warning "PDU device ${name} missing connection info"
            # Try a default configuration for testing with telnet for APC AP7900B
            bashio::log.info "Attempting default telnet configuration for ${name}"
            echo "device \"${name}\" \"apcpdu3\" \"telnet:192.168.51.124:23 |&\"" >> /etc/powerman/powerman.conf
            echo "node \"[1-8]\" \"${name}\"" >> /etc/powerman/powerman.conf
        fi
    fi
done

# Make sure the device definition file exists
if [ ! -f /etc/powerman/devices/apcpdu3.dev ]; then
    bashio::log.info "APC PDU device definition not found, checking for existing files..."
    
    # Try to find existing device files
    found_dev=false
    for dir in /usr/share/powerman /usr/local/share/powerman /etc/powerman; do
        if [ -d "${dir}" ] && [ -f "${dir}/apcpdu3.dev" ]; then
            bashio::log.info "Found PowerMan device definitions in ${dir}, copying..."
            cp -n ${dir}/*.dev /etc/powerman/devices/ 2>/dev/null || true
            found_dev=true
            break
        fi
    done
    
    # If still not found, check if it's in the root of /etc/powerman
    if [ "${found_dev}" == "false" ] && [ -f /etc/powerman/apcpdu3.dev ]; then
        bashio::log.info "Found apcpdu3.dev in /etc/powerman, moving to devices/"
        mv /etc/powerman/apcpdu3.dev /etc/powerman/devices/ 2>/dev/null || true
    fi
    
    # Final check
    if [ -f /etc/powerman/devices/apcpdu3.dev ]; then
        bashio::log.info "APC PDU device definition file is now in place"
    else
        bashio::log.error "Could not find or create APC PDU device definition!"
    fi
fi

# Ensure powerman can write to its run directory
mkdir -p /var/run/powerman
chmod 755 /var/run/powerman

bashio::log.info "PowerMan configuration complete"

# Show the configuration
bashio::log.info "PowerMan configuration:"
cat /etc/powerman/powerman.conf | while IFS= read -r line; do
    bashio::log.info "  Config: ${line}"
done

# Verify the configuration file exists and is readable
if [ -f /etc/powerman/powerman.conf ]; then
    bashio::log.info "PowerMan configuration file created successfully"
    # Check if device file exists
    if [ -f /etc/powerman/devices/apcpdu3.dev ]; then
        bashio::log.info "APC PDU device definition file found"
    else
        bashio::log.warning "APC PDU device definition file not found, copying default..."
        cp /etc/powerman/apcpdu3.dev /etc/powerman/devices/apcpdu3.dev 2>/dev/null || true
    fi
else
    bashio::log.error "PowerMan configuration file not created!"
    exit 1
fi

# Start PowerMan directly (s6 service management seems problematic)
bashio::log.info "Starting PowerMan daemon..."

# Check if powermand binary exists
if ! command -v powermand &>/dev/null; then
    bashio::log.error "powermand binary not found!"
    which powermand 2>&1 || bashio::log.error "powermand not in PATH"
    find /usr -name powermand 2>/dev/null | head -5 || bashio::log.error "Cannot find powermand"
    exit 1
fi

# Kill any existing powermand process
if command -v pkill &>/dev/null; then
    pkill powermand 2>/dev/null || true
else
    killall powermand 2>/dev/null || true
fi
sleep 1

# Create log file
touch /var/log/powerman.log
chmod 644 /var/log/powerman.log

# Start PowerMan in daemon mode
bashio::log.info "Starting PowerMan with command: powermand -c /etc/powerman/powerman.conf"
powermand -c /etc/powerman/powerman.conf 2>&1 | tee -a /var/log/powerman.log &
POWERMAN_PID=$!

bashio::log.info "PowerMan started with PID: ${POWERMAN_PID}"

# Wait for PowerMan to be ready
bashio::log.info "Waiting for PowerMan to be ready on port 10101..."
for i in {1..30}; do
    if nc -z localhost 10101 2>/dev/null || nc -z 127.0.0.1 10101 2>/dev/null; then
        bashio::log.info "PowerMan is ready and listening on port 10101"
        
        # Test connection
        if echo "help" | nc -w 1 localhost 10101 2>&1 | grep -q "powerman"; then
            bashio::log.info "PowerMan is responding correctly"
        else
            bashio::log.warning "PowerMan is listening but may not be fully ready"
        fi
        
        # Create a flag file to indicate PowerMan is running
        touch /var/run/powerman.ready
        
        # Save PID for monitoring
        echo ${POWERMAN_PID} > /var/run/powerman.pid
        
        bashio::log.info "PowerMan successfully started and ready"
        exit 0
    fi
    
    # Check if process is still running
    if ! kill -0 ${POWERMAN_PID} 2>/dev/null; then
        bashio::log.error "PowerMan process died unexpectedly!"
        bashio::log.error "PowerMan log:"
        tail -50 /var/log/powerman.log 2>/dev/null
        exit 1
    fi
    
    bashio::log.debug "Waiting for PowerMan... ($i/30)"
    sleep 1
done

# If we get here, PowerMan isn't responding
bashio::log.error "PowerMan failed to become ready within 30 seconds!"
bashio::log.error "PowerMan log:"
tail -50 /var/log/powerman.log 2>/dev/null

# Check if the process is still running
if kill -0 ${POWERMAN_PID} 2>/dev/null; then
    bashio::log.warning "PowerMan process is running but not responding on port 10101"
    # Let it continue anyway, maybe it needs more time
    touch /var/run/powerman.ready
    echo ${POWERMAN_PID} > /var/run/powerman.pid
    exit 0
else
    bashio::log.error "PowerMan process died!"
    exit 1
fi
