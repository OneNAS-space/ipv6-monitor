#!/bin/ash

# Add '/root/sysinfo' to the end of /etc/profile

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

LOGGED_IN_USERS=1

get_ip_addr() {
    local iface="$1"
    local ip_version="$2"
    ip -"$ip_version" addr show dev "$iface" | awk '/inet[6]? /{print $2}' | cut -d/ -f1 | head -1
}

WAN_INTERFACE="wan"
WAN_IP_V4=""
WAN_IP_V6=""

if ip link show "$WAN_INTERFACE" &>/dev/null; then
    WAN_IP_V4=$(get_ip_addr "$WAN_INTERFACE" 4)
    WAN_IP_V6=$(get_ip_addr "$WAN_INTERFACE" 6)
fi

LAN_INTERFACE="br-lan"
LAN_IP_V4=""
LAN_IP_V6=""
if ip link show "$LAN_INTERFACE" &>/dev/null; then
    LAN_IP_V4=$(get_ip_addr "$LAN_INTERFACE" 4)
    LAN_IP_V6=$(get_ip_addr "$LAN_INTERFACE" 6)
fi

WIFI_INFO_LINES=""
WIFI_INTERFACES=$(ip link show | awk '/phy[0-9]-ap[0-9]:/ { gsub(/:/, "", $2); print $2 }')

for wifi_iface in $WIFI_INTERFACES; do
    wifi_ip_v4=$(get_ip_addr "$wifi_iface" 4)
    wifi_ip_v6=$(get_ip_addr "$wifi_iface" 6)

    if [ -n "$wifi_ip_v4" ]; then
        WIFI_INFO_LINES="${WIFI_INFO_LINES}  IPv4 address for $wifi_iface: $wifi_ip_v4\n"
    fi
    if [ -n "$wifi_ip_v6" ]; then
        WIFI_INFO_LINES="${WIFI_INFO_LINES}  IPv6 address for $wifi_iface: $wifi_ip_v6\n"
    fi
done

echo " System information as of $CURRENT_DATETIME"
echo ""
echo " System load:     $LOADAVG"
echo " CPU usage:       $CPU_INFO"
echo " Disk usage:      $ROOT_USAGE"
echo " Memory usage:    ${MEM_PCT}%"
echo " Processes:       $PROCESSES"
echo " Users logged in: $LOGGED_IN_USERS"
echo ""

if [ -n "$WAN_IP_V4" ]; then
    echo " IPv4 for $WAN_INTERFACE:    $WAN_IP_V4"
fi
if [ -n "$WAN_IP_V6" ]; then
    echo " IPv6 for $WAN_INTERFACE:    $WAN_IP_V6"
fi

if [ -n "$LAN_IP_V4" ]; then
    echo " IPv4 for $LAN_INTERFACE: $LAN_IP_V4"
fi
if [ -n "$LAN_IP_V6" ]; then
    echo " IPv6 for $LAN_INTERFACE: $LAN_IP_V6"
fi

if [ -n "$WIFI_INFO_LINES" ]; then
    printf "$WIFI_INFO_LINES"
fi
echo ""
