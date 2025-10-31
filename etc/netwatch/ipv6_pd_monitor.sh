#!/bin/sh

WAN_IF="wan"
LAN_IF="br-lan"
HOTPLUG_FLAG="/tmp/wan-hotplug.flag"
LOG_FILE="/var/log/ipv6-monitor.log"
INTERVAL=60  # 检查间隔（秒）

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG_FILE"
    logger -t ipv6-monitor "$1"
}

while true; do
    LINK_STATE=$(cat /sys/class/net/$WAN_IF/carrier 2>/dev/null)

    PD_PREFIX=$(ip -6 addr show dev $LAN_IF | grep 'global' | grep -v 'fd' | grep -v 'fe80' | awk '{print $2}' | cut -d/ -f1)

    if [ -f "$HOTPLUG_FLAG" ]; then
        log "检测到 hotplug 链路恢复标志，检查 IPv6-PD 状态"
        rm -f "$HOTPLUG_FLAG"

        if [ -z "$PD_PREFIX" ]; then
            log "未检测到IPv6-PD，重启wan6接口"
            ifdown wan6
            sleep 2
            ifup wan6
        else
            log "IPv6-PD正常，无需重启"
        fi
    fi

    if [ "$LINK_STATE" = "1" ] && [ -z "$PD_PREFIX" ]; then
        log "链路正常但IPv6-PD缺失，尝试恢复wan6接口"
        ifdown wan6
        sleep 2
        ifup wan6
    fi

    sleep $INTERVAL
done
