#!/bin/bash
# thermal_watchdog.sh — soft power-cap governor for MI50 (card1)
# Run on the HOST as root, not inside the container.
# if the GPU dissaperas and reappers list the name in the render group by calling: 
# ls -l /dev/dri/render*

CARD_PATH="/sys/class/drm/card1/device/hwmon/hwmon2"
TEMP_FILE="$CARD_PATH/temp2_input"      # junction/hotspot sensor — verify index matches your card
POWER_CAP_FILE="$CARD_PATH/power1_cap"

SOFT_LIMIT=85000     # millidegrees C (85.0°C) — trigger point
RESTORE_LIMIT=72000  # millidegrees C (72.0°C) — hysteresis before restoring
NORMAL_CAP=250000000 # µW (250W) — your normal operating cap
THROTTLE_CAP=150000000 # µW (150W) — emergency step-down cap
POLL_INTERVAL=1      # seconds

throttled=0

echo "Thermal watchdog started. Soft limit: $((SOFT_LIMIT/1000))°C, restore below: $((RESTORE_LIMIT/1000))°C"

while true; do
  temp=$(cat "$TEMP_FILE")

  if [ "$temp" -ge "$SOFT_LIMIT" ] && [ "$throttled" -eq 0 ]; then
    echo "$(date '+%H:%M:%S') Junction at $((temp/1000))°C — engaging soft throttle, capping to $((THROTTLE_CAP/1000000))W"
    echo "$THROTTLE_CAP" > "$POWER_CAP_FILE"
    throttled=1
  elif [ "$temp" -le "$RESTORE_LIMIT" ] && [ "$throttled" -eq 1 ]; then
    echo "$(date '+%H:%M:%S') Junction cooled to $((temp/1000))°C — restoring normal cap $((NORMAL_CAP/1000000))W"
    echo "$NORMAL_CAP" > "$POWER_CAP_FILE"
    throttled=0
  fi

  sleep "$POLL_INTERVAL"
done
