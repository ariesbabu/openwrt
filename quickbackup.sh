# Create comprehensive backup
BACKUP_NAME="openwrt-vpn-backup-$(date +%Y%m%d)"
mkdir -p "/tmp/$BACKUP_NAME"

# Standard system backup
sysupgrade -b "/tmp/$BACKUP_NAME/system.tar.gz"

# Export all UCI configs
uci export > "/tmp/$BACKUP_NAME/all-configs.txt"

# Backup our custom scripts
cp /etc/rc.local "/tmp/$BACKUP_NAME/"
mkdir -p "/tmp/$BACKUP_NAME/hotplug"
cp /etc/hotplug.d/iface/* "/tmp/$BACKUP_NAME/hotplug/" 2>/dev/null || true
cp /usr/bin/fix-vpn-routing "/tmp/$BACKUP_NAME/" 2>/dev/null || true

# Create archive
cd /tmp && tar -czf "$BACKUP_NAME.tar.gz" "$BACKUP_NAME"
echo "Backup created: /tmp/$BACKUP_NAME.tar.gz"

# Copy to external location (choose one):
# scp "/tmp/$BACKUP_NAME.tar.gz" user@server:/backup/path/
# cp "/tmp/$BACKUP_NAME.tar.gz" /mnt/usb/