#!/bin/bash

LOG_FILE="/var/log/check-network.log"
MAX_SIZE=$((10 * 1024 * 1024)) # 10MB
MAX_FILES=5

rotate_logs() {
  if [ -f "${LOG_FILE}.${MAX_FILES}" ]; then
    rm -f "${LOG_FILE}.${MAX_FILES}"
  fi

  for ((i=MAX_FILES-1; i>=1; i--)); do
    if [ -f "${LOG_FILE}.${i}" ]; then
      mv "${LOG_FILE}.${i}" "${LOG_FILE}.$((i+1))"
    fi
  done

  if [ -f "$LOG_FILE" ]; then
    mv "$LOG_FILE" "${LOG_FILE}.1"
  fi
}

if [ -f "$LOG_FILE" ]; then
  FILE_SIZE=$(stat -c %s "$LOG_FILE")
  if (( FILE_SIZE >= MAX_SIZE )); then
    rotate_logs
  fi
fi

# The ip address to ping
TARGET="8.8.8.8"

# Ping three times to check network connectivity
if ! ping -c 3 "$TARGET" > /dev/null 2>&1; then
    echo "$(date): Network unreachable. Restarting network..." >> "$LOG_FILE"

    # Try to restart the network service
    sudo systemctl restart systemd-networkd #|| systemctl restart NetworkManager

    # If the network is still unreachable, reboot the system
    sleep 60
    if ! ping -c 3 "$TARGET" > /dev/null 2>&1; then
        echo "$(date): Still no network. Rebooting..." >> "$LOG_FILE"
        sudo reboot
    fi
else
    echo "$(date): Network OK." >> "$LOG_FILE"
fi