#!/bin/ash

# Add '/root/sysinfo' to the end of /etc/profile

# Function to extract ALL IPv4 or IPv6 addresses and their associated interface names (e.g., br-lan or br-lan:vip)
get_ip_addr() {
    local iface="$1"
    local ip_version="$2"
    local version_name
    
    [ "$ip_version" = "4" ] && version_name="IPv4"
    [ "$ip_version" = "6" ] && version_name="IPv6"

    ip -"$ip_version" addr show dev "$iface" 2>/dev/null | awk -v v="$version_name" '/inet[6]? / { 
        ip = $2
        sub(/\/[0-9]+/, "", ip)
        print v "," $NF "," ip
    }'
}

# --- Core System Metrics ---
CURRENT_DATETIME=$(date +"%a %b %d %H:%M:%S %Y")
LOADAVG=$(top -bn1 | grep "^Load average:" | sed 's/Load average: //')
CPU_INFO=$(top -bn1 | grep "^CPU:" | sed 's/^CPU:[[:space:]]*//')
ROOT_USAGE=$(df -h / | awk 'NR==2 {print $5 " of " $2}')
MEM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
MEM_USED=$(free -m | awk '/Mem:/ {print $3}')

if [ "$MEM_TOTAL" -eq 0 ]; then
    MEM_PCT=0
else
    MEM_PCT=$((MEM_USED * 100 / MEM_TOTAL))
fi

PROCESSES=$(ps | wc -l)
PROCESSES=$((PROCESSES - 1))

# --- Interface and IP Gatherers ---
WAN_INFO_LINES=""
LAN_INFO_LINES=""

# --- Dynamic WAN Interface Discovery ---
get_wan_interfaces_and_ips() {
    local wan_zone_section
    local LOGICAL_IFS=""
    local DEVICE_LIST=""
    local iface_device   
    local IP_VERSION
    local FULL_IFACE_NAME
    local IP_ADDR
    
    wan_zone_section=$(uci show firewall | awk '/\.name='\''wan'\''$/ {print $1}')
    if [ -n "$wan_zone_section" ]; then
        wan_zone_section="${wan_zone_section%.name=\'wan\'}"
        LOGICAL_IFS=$(uci get "$wan_zone_section".network 2>/dev/null | xargs)
    fi

    if [ -z "$LOGICAL_IFS" ]; then
        LOGICAL_IFS="wan wan6"
    fi
    
    WAN_INFO_LINES="${WAN_INFO_LINES} WAN Interfaces List (Original): $LOGICAL_IFS\n"
    for iface_logical in $LOGICAL_IFS; do
        iface_device=$(uci get "network.$iface_logical.device" 2>/dev/null)
        if [ -z "$iface_device" ]; then
            iface_device="$iface_logical"
        fi
        if ! echo "$DEVICE_LIST" | grep -q "\<$iface_device\>"; then
            DEVICE_LIST="$DEVICE_LIST $iface_device"
        fi
    done
    
    for iface_device_unique in $DEVICE_LIST; do
        while IFS=, read -r IP_VERSION FULL_IFACE_NAME IP_ADDR; do
            if [ -n "$IP_ADDR" ]; then
                WAN_INFO_LINES="${WAN_INFO_LINES}   ${IP_VERSION} for $FULL_IFACE_NAME: $IP_ADDR\n"
            fi
        done <<- EOF
$(get_ip_addr "$iface_device_unique" 4)
$(get_ip_addr "$iface_device_unique" 6)
EOF
    done
}

# --- Dynamic LAN Interface Discovery ---
get_lan_interfaces_and_ips() {
    local lan_zone_section
    local LOGICAL_IFS=""
    local DEVICE_LIST=""
    local iface_device
    local IP_VERSION
    local FULL_IFACE_NAME
    local IP_ADDR

    lan_zone_section=$(uci show firewall | awk '/\.name='\''lan'\''$/ {print $1}')
    if [ -n "$lan_zone_section" ]; then
        lan_zone_section="${lan_zone_section%.name=\'lan\'}"
        LOGICAL_IFS=$(uci get "$lan_zone_section".network 2>/dev/null | xargs)
    fi
    if [ -z "$LOGICAL_IFS" ]; then
        LOGICAL_IFS="lan"
    fi

    LAN_INFO_LINES="${LAN_INFO_LINES} LAN Interfaces List (Original): $LOGICAL_IFS\n"
    for iface_logical in $LOGICAL_IFS; do
        iface_device=$(uci get "network.$iface_logical.device" 2>/dev/null)
        if [ -z "$iface_device" ]; then
            iface_device="$iface_logical"
        fi
        if ! echo "$DEVICE_LIST" | grep -q "\<$iface_device\>"; then
            DEVICE_LIST="$DEVICE_LIST $iface_device"
        fi
    done
    for iface_device_unique in $DEVICE_LIST; do
        while IFS=, read -r IP_VERSION FULL_IFACE_NAME IP_ADDR; do
            if [ -n "$IP_ADDR" ]; then
                LAN_INFO_LINES="${LAN_INFO_LINES}   ${IP_VERSION} for $FULL_IFACE_NAME: $IP_ADDR\n"
            fi
        done <<- EOF
$(get_ip_addr "$iface_device_unique" 4)
$(get_ip_addr "$iface_device_unique" 6)
EOF
    done
}


# --- WIFI Interfaces ---
WIFI_INFO_LINES=""
WIFI_INTERFACES_RAW=$(ip link show | awk '/phy[0-9]-ap[0-9]:/ { gsub(/:/, "", $2); print $2 }')
WIFI_INTERFACES_DISPLAY=$(echo "$WIFI_INTERFACES_RAW" | tr '\n' ' ' | sed 's/[[:space:]]*$//') 
WIFI_INFO_LINES="${WIFI_INFO_LINES} WIFI Interfaces List (Original): $WIFI_INTERFACES_DISPLAY\n"

for wifi_iface in $WIFI_INTERFACES_RAW; do
    while IFS=, read -r IP_VERSION FULL_IFACE_NAME IP_ADDR; do
        if [ -n "$IP_ADDR" ]; then
            WIFI_INFO_LINES="${WIFI_INFO_LINES}   ${IP_VERSION} for $FULL_IFACE_NAME: $IP_ADDR\n"
        fi
    done <<- EOF
$(get_ip_addr "$wifi_iface" 4)
$(get_ip_addr "$wifi_iface" 6)
EOF
done

# --- Execution and Output ---
get_wan_interfaces_and_ips
get_lan_interfaces_and_ips

echo " System information as of $CURRENT_DATETIME"
echo ""
echo " System load:     $LOADAVG"
echo " CPU usage:       $CPU_INFO"
echo " Disk usage:      $ROOT_USAGE"
echo " Memory usage:    ${MEM_PCT}%"
echo " Processes:       $PROCESSES"
echo ""

WAN_PRINTED=0
LAN_PRINTED=0

if [ -n "$WAN_INFO_LINES" ]; then
    printf "$WAN_INFO_LINES"
    WAN_PRINTED=1
fi

if [ -n "$LAN_INFO_LINES" ]; then
    [ "$WAN_PRINTED" -eq 1 ] && echo ""
    printf "$LAN_INFO_LINES"
    LAN_PRINTED=1
fi

if [ -n "$WIFI_INFO_LINES" ]; then
    [ "$LAN_PRINTED" -eq 1 ] && echo ""
    printf "$WIFI_INFO_LINES"
fi

echo ""
