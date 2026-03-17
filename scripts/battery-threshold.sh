#!/bin/bash
# Sets battery charge end threshold and persists it via a udev rule.
# Usage: sudo ./battery-threshold.sh [threshold]
# Default threshold: 95

set -euo pipefail

THRESHOLD="${1:-95}"
UDEV_RULE="/etc/udev/rules.d/80-battery-threshold.rules"

bat=$(grep -rl '^Battery$' /sys/class/power_supply/*/type 2>/dev/null | head -1 | xargs dirname)

if [ -z "$bat" ]; then
    echo "No battery found." >&2
    exit 1
fi

if [ ! -f "$bat/charge_control_end_threshold" ]; then
    echo "charge_control_end_threshold not supported on this device." >&2
    exit 1
fi

bat_name=$(basename "$bat")

echo "Setting charge threshold to ${THRESHOLD}% for ${bat_name}..."
echo "$THRESHOLD" > "$bat/charge_control_end_threshold"

echo "Writing udev rule to ${UDEV_RULE}..."
cat > "$UDEV_RULE" <<EOF
# Set battery charge end threshold on boot
SUBSYSTEM=="power_supply", KERNEL=="${bat_name}", ATTR{charge_control_end_threshold}="${THRESHOLD}"
EOF

udevadm control --reload-rules

echo "Done. Threshold set to ${THRESHOLD}% and will persist across reboots."
