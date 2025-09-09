#!/bin/bash
# Comprehensive OpenWrt VPN Router Backup Script

# Create backup directory with timestamp
BACKUP_DIR="/tmp/full-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "Creating comprehensive backup in $BACKUP_DIR"

# 1. Standard OpenWrt system backup
echo "Creating system backup..."
sysupgrade -b "$BACKUP_DIR/system-backup.tar.gz"

# 2. Export all UCI configurations
echo "Exporting UCI configurations..."
uci export > "$BACKUP_DIR/uci-all-configs.txt"
uci export network > "$BACKUP_DIR/uci-network.txt"
uci export firewall > "$BACKUP_DIR/uci-firewall.txt"
uci export wireless > "$BACKUP_DIR/uci-wireless.txt"
uci export dhcp > "$BACKUP_DIR/uci-dhcp.txt"
uci export system > "$BACKUP_DIR/uci-system.txt"

# 3. Backup custom scripts and configurations
echo "Backing up custom scripts..."

# RC.local (startup script)
cp /etc/rc.local "$BACKUP_DIR/" 2>/dev/null || echo "#!/bin/sh\nexit 0" > "$BACKUP_DIR/rc.local"

# Hotplug scripts (our VPN routing script)
mkdir -p "$BACKUP_DIR/hotplug.d/iface"
cp /etc/hotplug.d/iface/* "$BACKUP_DIR/hotplug.d/iface/" 2>/dev/null || echo "No hotplug scripts found"

# Custom scripts in /usr/bin (if any)
mkdir -p "$BACKUP_DIR/usr-bin"
cp /usr/bin/fix-vpn-routing "$BACKUP_DIR/usr-bin/" 2>/dev/null || echo "No custom fix-vpn-routing script"

# 4. Backup configuration files
echo "Backing up config files..."
mkdir -p "$BACKUP_DIR/etc-config"
cp -r /etc/config/* "$BACKUP_DIR/etc-config/"

# Backup other important files
cp /etc/passwd "$BACKUP_DIR/" 2>/dev/null || true
cp /etc/shadow "$BACKUP_DIR/" 2>/dev/null || true
cp /etc/hosts "$BACKUP_DIR/" 2>/dev/null || true
cp /etc/resolv.conf "$BACKUP_DIR/" 2>/dev/null || true

# 5. WireGuard configuration (if custom files exist)
if [ -d /etc/wireguard ]; then
    echo "Backing up WireGuard configs..."
    cp -r /etc/wireguard "$BACKUP_DIR/" 2>/dev/null || true
fi

# 6. Document current network state
echo "Documenting current network state..."
cat > "$BACKUP_DIR/network-state.txt" << 'NETEOF'
# Network State Documentation
# Generated: $(date)

## IP Rules:
$(ip rule show)

## Main Routing Table:
$(ip route show table main)

## VPN Routing Table (100):
$(ip route show table 100)

## WireGuard Status:
$(wg show 2>/dev/null || echo "WireGuard not running")

## Interface Status:
$(ip addr show)

## Firewall Rules:
$(nft list ruleset 2>/dev/null || echo "nftables not available")

## Running Processes:
$(ps | grep -E "(wg|vpn|dhcp|dns)" || true)
NETEOF

# 7. Create restoration script
echo "Creating restoration script..."
cat > "$BACKUP_DIR/restore.sh" << 'RESTEOF'
#!/bin/sh
# OpenWrt VPN Router Restoration Script
# Run this script after uploading backup to /tmp/

RESTORE_DIR="$(dirname "$0")"
echo "Restoring from: $RESTORE_DIR"

# Restore system backup (this will restore most configs)
echo "Restoring system configuration..."
# sysupgrade -r "$RESTORE_DIR/system-backup.tar.gz"
echo "NOTE: Uncomment the above line to restore system backup"
echo "WARNING: This will reboot the router"

# Alternative: Manual restoration
echo "Restoring configuration files..."
cp "$RESTORE_DIR/rc.local" /etc/ 2>/dev/null && echo "RC.local restored"
chmod +x /etc/rc.local

# Restore hotplug scripts
mkdir -p /etc/hotplug.d/iface
cp "$RESTORE_DIR/hotplug.d/iface/"* /etc/hotplug.d/iface/ 2>/dev/null && echo "Hotplug scripts restored"
chmod +x /etc/hotplug.d/iface/*

# Restore custom scripts
cp "$RESTORE_DIR/usr-bin/"* /usr/bin/ 2>/dev/null && echo "Custom scripts restored"
chmod +x /usr/bin/fix-vpn-routing 2>/dev/null

# Restore configs
cp -r "$RESTORE_DIR/etc-config/"* /etc/config/ 2>/dev/null && echo "Config files restored"

# Restore WireGuard (if exists)
if [ -d "$RESTORE_DIR/wireguard" ]; then
    cp -r "$RESTORE_DIR/wireguard" /etc/ && echo "WireGuard configs restored"
fi

echo "Manual restoration complete!"
echo "Now run:"
echo "  uci commit"
echo "  /etc/init.d/network restart"
echo "  /etc/init.d/firewall restart"
echo "  reboot"
RESTEOF
chmod +x "$BACKUP_DIR/restore.sh"

# 8. Create archive
echo "Creating final backup archive..."
cd /tmp
tar -czf "openwrt-complete-backup-$(date +%Y%m%d-%H%M%S).tar.gz" "$(basename "$BACKUP_DIR")"

echo "==================================="
echo "BACKUP COMPLETE!"
echo "==================================="
echo "Backup location: /tmp/openwrt-complete-backup-*.tar.gz"
echo ""
echo "Files included:"
echo "- System backup (sysupgrade format)"
echo "- All UCI configurations"  
echo "- Custom scripts (/etc/rc.local, hotplug scripts)"
echo "- Network state documentation"
echo "- Automatic restoration script"
echo ""
echo "To copy backup off the router:"
echo "scp /tmp/openwrt-complete-backup-*.tar.gz user@backup-server:/path/"
echo ""
echo "Or download via web interface:"
echo "System > Software > Upload Package"

# Cleanup temporary directory
rm -rf "$BACKUP_DIR"