#!/bin/bash
# find_jrunner_comport.sh
# Usage: ./find_jrunner_comport.sh <VID> <PID> [output_file]
# Example: ./find_jrunner_comport.sh 1234 5678
# VID and PID should be 4-digit hex values (with or without 0x prefix)
#
# Output file defaults to /tmp/jrunner_comport.txt

set -euo pipefail

# --- Argument handling ---
if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <VID> <PID> [output_file]"
    echo "  VID/PID: USB vendor/product ID in hex (e.g. 1a86 or 0x1a86)"
    exit 1
fi

# Strip optional 0x prefix and lowercase
VID=$(echo "$1" | sed 's/^0x//I' | tr '[:upper:]' '[:lower:]')
PID=$(echo "$2" | sed 's/^0x//I' | tr '[:upper:]' '[:lower:]')
OUTPUT_FILE="${3:-/tmp/jrunner_comport.txt}"

# --- Find the tty device via sysfs ---
# Search for the device in /sys/bus/usb/devices by matching idVendor and idProduct
find_tty() {
    local vid="$1"
    local pid="$2"

    for dev_path in /sys/bus/usb/devices/*/; do
        local vendor_file="${dev_path}idVendor"
        local product_file="${dev_path}idProduct"

        [[ -f "$vendor_file" && -f "$product_file" ]] || continue

        local dev_vid
        local dev_pid
        dev_vid=$(cat "$vendor_file" | tr '[:upper:]' '[:lower:]')
        dev_pid=$(cat "$product_file" | tr '[:upper:]' '[:lower:]')

        if [[ "$dev_vid" == "$vid" && "$dev_pid" == "$pid" ]]; then
            # Walk subdirectories looking for a tty device
            local tty
            tty=$(find "$dev_path" -name "tty*" -maxdepth 5 2>/dev/null \
                  | grep -oP 'tty\w+' | grep -v '^tty$' | head -n1)
            if [[ -n "$tty" ]]; then
                echo "$tty"
                return 0
            fi
        fi
    done
    return 1
}

TTY_DEV=$(find_tty "$VID" "$PID") || {
    echo "Error: No tty device found for VID=$VID PID=$PID" >&2
    exit 2
}

TTY_PATH="/dev/${TTY_DEV}"

# --- Resolve the Wine COM port from the registry ---
# Wine maps COM ports in: HKLM\Software\Wine\Ports  (or via symlinks in ~/.wine/dosdevices)
resolve_jrunner_comport() {
    local tty="$1"

    # Preferred: check dosdevices symlinks (works without wine reg tool)
    local dosdevices
    dosdevices="${WINEPREFIX:-$HOME/.wine}/dosdevices"

    if [[ -d "$dosdevices" ]]; then
        for link in "$dosdevices"/com*; do
            [[ -L "$link" ]] || continue
            local target
            target=$(readlink -f "$link" 2>/dev/null || true)
            if [[ "$target" == "/dev/$tty" || "$target" == "/dev/$(basename "$tty")" ]]; then
                # Return just the COM port name in uppercase, e.g. COM3
                basename "$link" | tr '[:lower:]' '[:upper:]'
                return 0
            fi
        done
    fi

    # Fallback: query the Wine registry
    if command -v wine &>/dev/null; then
        local reg_output
        reg_output=$(wine reg query \
            "HKEY_LOCAL_MACHINE\\Software\\Wine\\Ports" 2>/dev/null || true)

        while IFS= read -r line; do
            # Lines look like:  COM3    REG_SZ    /dev/ttyUSB0
            if echo "$line" | grep -qi "/dev/$tty"; then
                echo "$line" | awk '{print $1}' | tr '[:lower:]' '[:upper:]'
                return 0
            fi
        done <<< "$reg_output"
    fi

    return 1
}

COM_PORT=$(resolve_jrunner_comport "$TTY_DEV") || {
    echo "Error: Device /dev/${TTY_DEV} found but no matching Wine COM port." >&2
    echo "Make sure the device is mapped in your Wine prefix dosdevices or registry." >&2
    exit 3
}

# --- Write just the COM port name to the output file ---
printf '%s' "$COM_PORT" > "$OUTPUT_FILE"

echo "Found: /dev/${TTY_DEV} -> ${COM_PORT}"
echo "Written to: ${OUTPUT_FILE}"
