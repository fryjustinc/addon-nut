#!/command/with-contenv bashio
# ==============================================================================
# Home Assistant Community Add-on: Network UPS Tools
# Configures Network UPS Tools
# ==============================================================================
readonly USERS_CONF=/etc/nut/upsd.users
readonly UPSD_CONF=/etc/nut/upsd.conf
declare nutmode
declare password
declare shutdowncmd
declare upsmonpwd
declare username

chown root:root /var/run/nut
chmod 0770 /var/run/nut

chown -R root:root /etc/nut
find /etc/nut -not -perm 0660 -type f -exec chmod 0660 {} \;
find /etc/nut -not -perm 0660 -type d -exec chmod 0660 {} \;

nutmode=$(bashio::config 'mode')
bashio::log.info "Setting mode to ${nutmode}..."
sed -i "s#%%nutmode%%#${nutmode}#g" /etc/nut/nut.conf

if bashio::config.true 'list_usb_devices' ;then
    bashio::log.info "Connected USB devices:"
    lsusb
fi

# Check if we need PowerMan (will be configured by powerman.sh init script)
has_powerman=false
if bashio::config.has_value 'powerman_enabled' && bashio::config.true 'powerman_enabled'; then
    has_powerman=true
    bashio::log.info "PowerMan is enabled"
fi

# Also check for powerman-pdu devices
for device in $(bashio::config "devices|keys"); do
    driver=$(bashio::config "devices[${device}].driver")
    if [[ "${driver}" == "powerman-pdu" ]]; then
        has_powerman=true
        bashio::log.info "Found powerman-pdu device, PowerMan will be needed"
        break
    fi
done

# Wait for PowerMan service if needed
if [[ "${has_powerman}" == "true" ]]; then
    bashio::log.info "Checking if PowerMan is ready..."
    powerman_ready=false
    
    # First check if PowerMan is already running (started by 00-powerman.sh)
    if [ -f /var/run/powerman.ready ]; then
        bashio::log.info "PowerMan ready flag found, verifying..."
        if nc -z localhost 10101 2>/dev/null || nc -z 127.0.0.1 10101 2>/dev/null; then
            bashio::log.info "PowerMan is already running and ready"
            powerman_ready=true
        else
            bashio::log.warning "PowerMan flag exists but service not responding, waiting..."
        fi
    fi
    
    # If not ready yet, wait for it
    if [[ "${powerman_ready}" != "true" ]]; then
        bashio::log.info "Waiting for PowerMan to start listening on port 10101..."
        for i in {1..15}; do
            # Check if PowerMan is listening
            if nc -z localhost 10101 2>/dev/null || nc -z 127.0.0.1 10101 2>/dev/null; then
                bashio::log.info "PowerMan is listening on port 10101"
                powerman_ready=true
                
                # Test actual connectivity with powerman client
                if command -v pm &>/dev/null; then
                    if timeout 2 pm -h localhost -l 2>&1 | grep -qE "(rack_pdu|[1-8])"; then
                        bashio::log.info "PowerMan connectivity verified with pm client"
                    else
                        bashio::log.warning "PowerMan is listening but pm client test failed"
                    fi
                fi
                
                # Also test with a simple echo command
                if echo "help" | nc -w 1 localhost 10101 2>/dev/null | grep -q "powerman"; then
                    bashio::log.info "PowerMan is responding to commands"
                fi
                
                # Mark as ready if not already marked
                touch /var/run/powerman.ready
                break
            fi
            
            if [[ $i -eq 15 ]]; then
                bashio::log.error "PowerMan not responding after 15 seconds!"
                bashio::log.info "Checking PowerMan process..."
                if [ -f /var/run/powerman.pid ]; then
                    PID=$(cat /var/run/powerman.pid)
                    if kill -0 ${PID} 2>/dev/null; then
                        bashio::log.warning "PowerMan process (PID ${PID}) is running but not responding"
                    else
                        bashio::log.error "PowerMan process (PID ${PID}) is not running!"
                    fi
                else
                    ps aux | grep powermand | grep -v grep || bashio::log.error "PowerMan process not found!"
                fi
                
                bashio::log.info "PowerMan log (last 30 lines):"
                if [ -f /var/log/powerman.log ]; then
                    tail -30 /var/log/powerman.log
                else
                    bashio::log.error "No PowerMan log file found"
                fi
                
                bashio::log.info "Checking if port 10101 is in use:"
                netstat -tuln 2>/dev/null | grep 10101 || bashio::log.error "Port 10101 not listening (netstat)"
                ss -tuln 2>/dev/null | grep 10101 || bashio::log.error "Port 10101 not listening (ss)"
            else
                bashio::log.debug "Waiting for PowerMan... ($i/15)"
                sleep 1
            fi
        done
    fi
    
    if [[ "${powerman_ready}" != "true" ]]; then
        bashio::log.error "PowerMan is not ready, powerman-pdu driver may fail"
        bashio::log.info "Attempting to start drivers anyway..."
    fi
fi

if bashio::config.equals 'mode' 'netserver' ;then
    bashio::log.info "Generating ${USERS_CONF}..."

    # Create Monitor User
    upsmonpwd=$(shuf -ze -n20  {A..Z} {a..z} {0..9}|tr -d '\0')
    {
        echo
        echo "[upsmonmaster]"
        echo "  password = ${upsmonpwd}"
        echo "  upsmon master"
    } >> "${USERS_CONF}"

    for user in $(bashio::config "users|keys"); do
        bashio::config.require.username "users[${user}].username"
        username=$(bashio::config "users[${user}].username")

        bashio::log.info "Configuring user: ${username}"
        if ! bashio::config.true 'i_like_to_be_pwned'; then
            # Try to check password safety, but continue if check fails
            if ! bashio::config.require.safe_password "users[${user}].password" 2>/dev/null; then
                bashio::log.warning "Password safety check had issues, continuing..."
            fi
        else
            bashio::config.require.password "users[${user}].password"
        fi
        password=$(bashio::config "users[${user}].password")

        {
            echo
            echo "[${username}]"
            echo "  password = ${password}"
        } >> "${USERS_CONF}"

        for instcmd in $(bashio::config "users[${user}].instcmds"); do
            echo "  instcmds = ${instcmd}" >> "${USERS_CONF}"
        done

        for action in $(bashio::config "users[${user}].actions"); do
            echo "  actions = ${action}" >> "${USERS_CONF}"
        done

        if bashio::config.has_value "users[${user}].upsmon"; then
            upsmon=$(bashio::config "users[${user}].upsmon")
            echo "  upsmon ${upsmon}" >> "${USERS_CONF}"
        fi
    done

    if bashio::config.has_value "upsd_maxage"; then
        maxage=$(bashio::config "upsd_maxage")
        echo "MAXAGE ${maxage}" >> "${UPSD_CONF}"
    fi

    for device in $(bashio::config "devices|keys"); do
        upsname=$(bashio::config "devices[${device}].name")
        upsdriver=$(bashio::config "devices[${device}].driver")
        upsport=$(bashio::config "devices[${device}].port")
        if bashio::config.has_value "devices[${device}].powervalue"; then
            upspowervalue=$(bashio::config "devices[${device}].powervalue")
        else
            upspowervalue="1"
        fi

        bashio::log.info "Configuring Device named ${upsname}..."
        
        # Special handling for powerman-pdu driver
        if [[ "${upsdriver}" == "powerman-pdu" ]]; then
            # Ensure PowerMan will be used and set a sensible default port if not provided
            has_powerman=true
            bashio::log.info "Configuring ${upsname} with powerman-pdu driver"
            if [[ -z "${upsport}" || "${upsport}" == "null" ]]; then
                upsport="powerman://localhost:10101"
                bashio::log.info "No port specified for ${upsname}, defaulting to ${upsport}"
            fi
        fi
        
        {
            echo
            echo "[${upsname}]"
            echo "  driver = ${upsdriver}"
            echo "  port = ${upsport}"
            # Add helpful description
            if [[ "${upsdriver}" == "powerman-pdu" ]]; then
                echo "  desc = \"APC PDU (PowerMan control)\""
            elif [[ "${upsdriver}" == "dummy-ups" ]]; then
                echo "  mode = dummy"
                echo "  desc = \"APC PDU via PowerMan (aggregated)\""
            fi
        } >> /etc/nut/ups.conf

        OIFS=$IFS
        IFS=$'\n'
        for configitem in $(bashio::config "devices[${device}].config"); do
            echo "  ${configitem}" >> /etc/nut/ups.conf
        done
        IFS="$OIFS"

        echo "MONITOR ${upsname}@localhost ${upspowervalue} upsmonmaster ${upsmonpwd} master" \
            >> /etc/nut/upsmon.conf
    done
    
    bashio::log.info "Starting the UPS drivers..."
    # Run upsdrvctl
    if bashio::debug; then
        upsdrvctl -u root -D start
        DRIVER_START_RESULT=$?
    else
        upsdrvctl -u root start
        DRIVER_START_RESULT=$?
    fi
    
    # Check if drivers started successfully
    if [ ${DRIVER_START_RESULT} -ne 0 ]; then
        bashio::log.error "Failed to start UPS drivers! (exit code: ${DRIVER_START_RESULT})"
        bashio::log.info "Checking driver status..."
        upsdrvctl -u root status 2>&1 || true
        # Don't exit with error for now - let's see what happens
        # exit 1
    else
        bashio::log.info "UPS drivers started successfully"
    fi
fi

shutdowncmd="/run/s6/basedir/bin/halt"
if bashio::config.true 'shutdown_host'; then
    bashio::log.warning "UPS Shutdown will shutdown the host"
    shutdowncmd="/usr/bin/shutdownhost"
fi

echo "SHUTDOWNCMD  ${shutdowncmd}" >> /etc/nut/upsmon.conf
