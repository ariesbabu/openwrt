# Extract backup (assumes backup file is in /tmp/)
cd /tmp
tar -xzf openwrt-vpn-backup-*.tar.gz
BACKUP_DIR=$(ls -d openwrt-vpn-backup-* | head -1)

# Restore system backup (this restarts the router)
sysupgrade -r "$BACKUP_DIR/system.tar.gz"

# OR manual restore (no reboot):
cp "$BACKUP_DIR/rc.local" /etc/
cp "$BACKUP_DIR/hotplug/"* /etc/hotplug.d/iface/ 2>/dev/null || true
cp "$BACKUP_DIR/fix-vpn-routing" /usr/bin/ 2>/dev/null || true
chmod +x /etc/rc.local /etc/hotplug.d/iface/* /usr/bin/fix-vpn-routing

# Import configurations
uci import < "$BACKUP_DIR/all-configs.txt"
uci commit

# Restart services
/etc/init.d/network restart
/etc/init.d/firewall restart
reboot