#!/bin/bash

# The ip address to ping
TARGET="8.8.8.8"

# Ping three times to check network connectivity
if ! ping -c 3 "$TARGET" > /dev/null 2>&1; then
    echo "$(date): Network unreachable. Restarting network..." >> /var/log/check-network.log

    # Try to restart the network service
    sudo systemctl restart systemd-networkd #|| systemctl restart NetworkManager

    # If the network is still unreachable, reboot the system
    sleep 60
    if ! ping -c 3 "$TARGET" > /dev/null 2>&1; then
        echo "$(date): Still no network. Rebooting..." >> /var/log/check-network.log
        sudo reboot
    fi
else
    echo "$(date): Network OK." >> /var/log/check-network.log
fi