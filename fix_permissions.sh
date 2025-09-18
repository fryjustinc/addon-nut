#!/bin/bash

# Fix all permissions for the addon

echo "Fixing file permissions..."

# Make all scripts executable
chmod +x *.sh 2>/dev/null

# Fix addon structure permissions
find nut -type f -name "*.sh" -exec chmod +x {} \;
chmod +x nut/rootfs/etc/cont-init.d/*.sh
chmod +x nut/rootfs/etc/services.d/*/run
chmod +x nut/rootfs/etc/services.d/*/finish
chmod +x nut/rootfs/usr/bin/* 2>/dev/null

echo "✓ Permissions fixed"
echo ""
echo "Ready to deploy with:"
echo "  ./deploy_complete.sh"
