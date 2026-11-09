#!/bin/bash
# thermal_watchdog.sh — soft power-cap governor for MI50 (card1)
# Run on the HOST as root, not inside the container.
# if the GPU dissaperas and reappers list the name in the render group by calling: 
# ls -l /dev/dri/render*

CARD_PATH="/sys/class/drm/card1/device/hwmon/hwmon2"
TEMP_FILE="$CARD_PATH/temp2_input"      # junction/hotspot sensor — verify index matches your card
POWER_CAP_FILE="$CARD_PATH/power1_cap"

HARD_LIMIT=95000     # millidegrees C (95.0°C) — hard limit, enforce HARD_CAP
SOFT_LIMIT=85000     # millidegrees C (85.0°C) — trigger point
RESTORE_LIMIT=72000  # millidegrees C (72.0°C) — hysteresis before restoring from throttle to normal
HARD_RECOVER_LIMIT=50000         # millidegrees C (50.0°C) — step up from hard cap to intermediate cap
INTERMEDIATE_RECOVER_LIMIT=80000 # millidegrees C (80.0°C) — step up from intermediate cap to throttle cap
NORMAL_CAP=250000000 # µW (250W) — your normal operating cap
THROTTLE_CAP=150000000 # µW (150W) — emergency step-down cap
INTERMEDIATE_CAP=120000000 # µW (120W) — recovery step between hard cap and throttle cap
HARD_CAP=100000000 # µW (100W) — hard limit, enforce if temperature exceeds HARD_LIMIT
POLL_INTERVAL=1      # seconds

# state: 0=normal, 1=throttled (THROTTLE_CAP), 2=hard-throttled (HARD_CAP), 3=recovering (INTERMEDIATE_CAP)
# Recovery only ever steps up one level at a time (2->3->1->0) so a cooldown
# from a hard-cap event doesn't jump straight back to full power.
state=0

echo "Thermal watchdog started. Soft limit: $(<(SOFT_LIMIT/1000))°C, restore below: $((RESTORE_LIMIT/1000))°C"

while true; do
  temp=$(cat "$TEMP_FILE")

  if [ "$temp" -ge "$HARD_LIMIT" ] && [ "$state" -ne 2 ]; then
    echo "$(date '+%H:%M:%S') Junction at $((temp/1000))°C — exceeding hard limit, enforcing $((HARD_CAP/1000000))W cap"
    echo "$HARD_CAP" > "$POWER_CAP_FILE"
    state=2
  elif [ "$temp" -ge "$SOFT_LIMIT" ] && [ "$state" -eq 0 ]; then
    echo "$(date '+%H:%M:%S') Junction at $((temp/1000))°C — engaging soft throttle, capping to $((THROTTLE_CAP/1000000))W"
    echo "$THROTTLE_CAP" > "$POWER_CAP_FILE"
    state=1
  elif [ "$state" -eq 2 ] && [ "$temp" -lt "$HARD_RECOVER_LIMIT" ]; then
    echo "$(date '+%H:%M:%S') Junction cooled to $((temp/1000))°C — stepping up from hard cap to $((INTERMEDIATE_CAP/1000000))W"
    echo "$INTERMEDIATE_CAP" > "$POWER_CAP_FILE"
    state=3
  elif [ "$state" -eq 3 ] && [ "$temp" -lt "$INTERMEDIATE_RECOVER_LIMIT" ]; then
    echo "$(date '+%H:%M:%S') Junction at $((temp/1000))°C — stepping up to throttle cap $((THROTTLE_CAP/1000000))W"
    echo "$THROTTLE_CAP" > "$POWER_CAP_FILE"
    state=1
  elif [ "$state" -eq 1 ] && [ "$temp" -le "$RESTORE_LIMIT" ]; then
    echo "$(date '+%H:%M:%S') Junction cooled to $((temp/1000))°C — restoring normal cap $((NORMAL_CAP/1000000))W"
    echo "$NORMAL_CAP" > "$POWER_CAP_FILE"
    state=0
  fi

  sleep "$POLL_INTERVAL"
done
