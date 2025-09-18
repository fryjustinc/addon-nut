#!/bin/bash
# Fix all references to use the correct powerman-pdu driver name

# This script updates all configuration files and documentation to use
# the correct driver name "powerman-pdu" instead of "powerman"

echo "Fixing PowerMan driver references..."

# Files to update
files=(
    "nut/DOCS.md"
    "nut/examples/apc-ap7900b-config.yaml"
    "nut/examples/apc-complete-setup.yaml"
    "nut/config.yaml"
    "POWERMAN_CHANGES.md"
    "APC_DEVICE_SUPPORT.md"
)

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "Updating $file..."
        # Replace driver: powerman with driver: powerman-pdu
        sed -i.bak 's/driver: powerman$/driver: powerman-pdu/g' "$file"
        sed -i.bak 's/driver: powerman /driver: powerman-pdu /g' "$file"
        sed -i.bak 's/"powerman"/"powerman-pdu"/g' "$file"
        # Clean up backup files
        rm -f "${file}.bak"
    fi
done

echo "Done! All references updated to use powerman-pdu driver."
