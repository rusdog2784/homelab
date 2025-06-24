# Pi-hole Automated Backup Setup Guide

## Overview
This setup creates automated daily backups of your Pi-hole configuration using two methods:
1. **Teleporter backup** - Pi-hole's native backup tool (recommended for restore)
2. **Full config directory backup** - Complete backup of `/opt/pihole/config` directory

Both backups are stored on your TrueNAS SMB share at `\\10.10.10.101\Backups\PiHole`.

## Installation Steps

### 1. Create the Backup Script
Save the backup script as `/usr/local/bin/pihole-backup.sh`:

```bash
sudo mkdir -p /usr/local/bin
sudo cp pihole-backup.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/pihole-backup.sh
```

### 2. Create SMB Credentials File
Create the credentials file at `/root/.smb-backup-credentials`:

```bash
sudo tee /root/.smb-backup-credentials > /dev/null << 'EOF'
username=your_truenas_username
password=your_truenas_password
domain=WORKGROUP
EOF

sudo chmod 600 /root/.smb-backup-credentials
```

**Replace the placeholders:**
- `your_truenas_username` - Your TrueNAS SMB username
- `your_truenas_password` - Your TrueNAS SMB password
- `WORKGROUP` - Your domain/workgroup (usually WORKGROUP for home setups)

### 3. Install Required Packages
Ensure SMB client tools are installed:

```bash
sudo apt update
sudo apt install cifs-utils -y
```

### 4. Choose Your Scheduling Method

You have two options for scheduling the backup:

#### Option A: Using systemd (Recommended)

**Advantages**: Better logging, dependency management, failure handling, service isolation

Create the service file:
```bash
sudo tee /etc/systemd/system/pihole-backup.service > /dev/null << 'EOF'
[Unit]
Description=Pi-hole Backup Service
After=network-online.target docker.service
Wants=network-online.target
Requires=docker.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/pihole-backup.sh
User=root
Group=root
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
```

#### Create the timer file for daily execution:
```bash
sudo tee /etc/systemd/system/pihole-backup.timer > /dev/null << 'EOF'
[Unit]
Description=Run Pi-hole backup daily
Requires=pihole-backup.service

[Timer]
# Execute daily at 2:30 AM (change time as needed)
OnCalendar=*-*-* 02:30:00
# Add random delay up to 30 minutes to avoid all services running simultaneously
RandomizedDelaySec=30m
# Run missed executions on boot if system was down
Persistent=true

[Install]
WantedBy=timers.target
EOF
```

**Alternative time examples:**
- `OnCalendar=*-*-* 03:15:00` - Daily at 3:15 AM
- `OnCalendar=Sun *-*-* 04:00:00` - Sundays at 4:00 AM  
- `OnCalendar=*-*-* 00,06,12,18:00:00` - Every 6 hours

#### Option B: Using cron (Simpler)

**Advantages**: Simple, familiar, lightweight

```bash
# Edit root's crontab
sudo crontab -e

# Add one of these lines (choose your preferred time):
# Daily at 2:30 AM
30 2 * * * /usr/local/bin/pihole-backup.sh >> /var/log/pihole-backup.log 2>&1

# Daily at 3:15 AM
15 3 * * * /usr/local/bin/pihole-backup.sh >> /var/log/pihole-backup.log 2>&1

# Sundays at 4:00 AM
0 4 * * 0 /usr/local/bin/pihole-backup.sh >> /var/log/pihole-backup.log 2>&1

# Every 6 hours
0 */6 * * * /usr/local/bin/pihole-backup.sh >> /var/log/pihole-backup.log 2>&1
```

### 5. Enable and Start Your Chosen Method

#### If you chose systemd:

```bash
# Reload systemd daemon
sudo systemctl daemon-reload

# Enable the timer to start on boot
sudo systemctl enable pihole-backup.timer

# Start the timer
sudo systemctl start pihole-backup.timer

# Check timer status
sudo systemctl status pihole-backup.timer

# View when timer will next run
sudo systemctl list-timers | grep pihole-backup
```

#### If you chose cron:

```bash
# Verify the cron job was added
sudo crontab -l

# Check if cron service is running
sudo systemctl status cron
```

### 6. Test the Backup

Run a manual backup to test:

```bash
sudo /usr/local/bin/pihole-backup.sh
```

Check the logs:
```bash
sudo tail -f /var/log/pihole-backup.log
```

## Configuration Options

You can modify these variables in the backup script:

- `RETENTION_DAYS=14` - How many days of backups to keep
- `SMB_SERVER="10.10.10.101"` - Your TrueNAS IP address
- `SMB_SHARE="Backups"` - Your SMB share name
- `DOCKER_CONTAINER_NAME="pihole"` - Your Pi-hole container name

## Backup Contents

### Teleporter Backup Includes:
- Domains (whitelist/blacklist)
- Adlists
- Clients and Groups
- DHCP static leases
- Local DNS records
- Configuration settings

### Config Directory Backup Includes:
- All files in `/opt/pihole/config/`
- Database files (gravity.db, pihole-FTL.db)
- Custom configurations
- TLS certificates

## Monitoring and Maintenance

### For systemd:
```bash
# Check backup status and next run time
sudo systemctl list-timers | grep pihole-backup

# View service logs
sudo journalctl -u pihole-backup.service -f

# View general logs
sudo tail -f /var/log/pihole-backup.log

# Manual backup execution
sudo systemctl start pihole-backup.service
```

### For cron:
```bash
# View cron logs (varies by distribution)
sudo journalctl -u cron -f
# OR
sudo tail -f /var/log/syslog | grep CRON

# View backup logs
sudo tail -f /var/log/pihole-backup.log

# Manual backup execution
sudo /usr/local/bin/pihole-backup.sh
```

### List backups on TrueNAS:
```bash
sudo mount -t cifs //10.10.10.101/Backups/PiHole /mnt/temp -o credentials=/root/.smb-backup-credentials
ls -la /mnt/temp/
sudo umount /mnt/temp
```

## Restore Process

### From Teleporter Backup:
1. Access Pi-hole web interface: `http://your-pihole-ip/admin`
2. Go to Settings → Teleporter
3. Use the "Restore" section to upload your `.tar.gz` backup file
4. Click "Restore" and wait for completion

### From Config Directory Backup:
1. Stop the Pi-hole container:
   ```bash
   cd /opt/pihole
   docker-compose down
   ```

2. Restore the config directory:
   ```bash
   sudo rm -rf /opt/pihole/config
   sudo tar -xzf pihole-config-YYYYMMDD_HHMMSS.tar.gz -C /opt/pihole/
   ```

3. Start the container:
   ```bash
   docker-compose up -d
   ```

## Troubleshooting

### Common Issues:

1. **SMB mount fails**: Check firewall rules between VLANs
2. **Container not found**: Verify container name in script
3. **Permission denied**: Ensure script runs as root
4. **Network timeout**: Check TrueNAS connectivity

### Firewall Configuration:
Make sure your OPNSense allows traffic from the Pi-hole VM VLAN to the TrueNAS VLAN on ports:
- TCP 445 (SMB)
- TCP 139 (NetBIOS)
- UDP 137-138 (NetBIOS name service)

## Security Notes

- SMB credentials file is secured with 600 permissions (root only)
- Backups are transferred over your local network
- Consider setting up SMB encryption in TrueNAS for added security
- Regular backup testing is recommended