#!/bin/bash

# Pi-hole Automated Backup Script
# This script creates both Teleporter and full config backups
# Author: Backup Assistant
# Version: 1.0

# Configuration
SMB_SERVER="10.10.10.101"
SMB_SHARE="Backups"
BACKUP_NAME="PiHole"
SMB_PATH="//$SMB_SERVER/$SMB_SHARE/$BACKUP_NAME"
SMB_CREDENTIALS_FILE="/root/.smb-backup-credentials"
LOCAL_MOUNT_POINT="/mnt/pihole-backups"
DOCKER_CONTAINER_NAME="pihole"
PIHOLE_CONFIG_PATH="/opt/pihole/config"
RETENTION_DAYS=14
LOG_FILE="/var/log/pihole-backup.log"



# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Function to check if command succeeded
check_status() {
    if [ $? -eq 0 ]; then
        log_message "SUCCESS: $1"
    else
        log_message "ERROR: $1"
        cleanup_and_exit 1
    fi
}

# Function to cleanup and exit
cleanup_and_exit() {
    if mountpoint -q "$LOCAL_MOUNT_POINT"; then
        umount "$LOCAL_MOUNT_POINT" 2>/dev/null
        log_message "Unmounted backup share"
    fi
    exit $1
}

# Function to setup SMB credentials file
setup_smb_credentials() {
    if [ ! -f "$SMB_CREDENTIALS_FILE" ]; then
        log_message "ERROR: SMB credentials file not found at $SMB_CREDENTIALS_FILE"
        log_message "Please create the file with the following format:"
        log_message "username=your_username"
        log_message "password=your_password"
        log_message "domain=your_domain_or_workgroup"
        exit 1
    fi
    
    # Secure the credentials file
    chmod 600 "$SMB_CREDENTIALS_FILE"
    check_status "Secured SMB credentials file permissions"
}

# Function to mount SMB share
mount_smb_share() {
    # Create mount point if it doesn't exist
    mkdir -p "$LOCAL_MOUNT_POINT"
    check_status "Created mount point directory"
    
    # Mount the SMB share
    mount -t cifs "$SMB_PATH" "$LOCAL_MOUNT_POINT" -o credentials="$SMB_CREDENTIALS_FILE",uid=root,gid=root,iocharset=utf8,vers=3.0
    check_status "Mounted SMB share at $LOCAL_MOUNT_POINT"
}

# Function to create Teleporter backup
create_teleporter_backup() {
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_filename="pihole-teleporter-${timestamp}.zip"
    local temp_backup_path="/tmp/$backup_filename"
    
    log_message "Starting Teleporter backup..."
    
    # Execute teleporter backup inside the Docker container
	pihole_backup_filename=$(docker exec pihole pihole-FTL --teleporter | grep -o '.*\.zip$')
    check_status "Created Teleporter backup inside container: $pihole_backup_filename"
    
    # Copy the backup from container to host
    docker cp "$DOCKER_CONTAINER_NAME:/$pihole_backup_filename" "$temp_backup_path"
    check_status "Copied Teleporter backup from container to host"
    
    # Copy to SMB share
    cp "$temp_backup_path" "$LOCAL_MOUNT_POINT/"
    check_status "Copied Teleporter backup to SMB share"
    
    # Clean up temporary files
    rm -f "$temp_backup_path"
    docker exec "$DOCKER_CONTAINER_NAME" rm -f "/$pihole_backup_filename"
    
    log_message "Teleporter backup completed: $backup_filename"
}

# Function to create full config backup
create_config_backup() {
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_filename="pihole-config-${timestamp}.tar.gz"
    local temp_backup_path="/tmp/$backup_filename"
    
    log_message "Starting full config backup..."
    
    # Create compressed backup of the entire config directory
    tar -czf "$temp_backup_path" -C "$(dirname "$PIHOLE_CONFIG_PATH")" "$(basename "$PIHOLE_CONFIG_PATH")"
    check_status "Created compressed config backup"
    
    # Copy to SMB share
    cp "$temp_backup_path" "$LOCAL_MOUNT_POINT/"
    check_status "Copied config backup to SMB share"
    
    # Clean up temporary file
    rm -f "$temp_backup_path"
    
    log_message "Config backup completed: $backup_filename"
}

# Function to clean old backups
cleanup_old_backups() {
    log_message "Cleaning up backups older than $RETENTION_DAYS days..."
    
    # Remove old teleporter backups
    find "$LOCAL_MOUNT_POINT" -name "pihole-teleporter-*.zip" -type f -mtime +$RETENTION_DAYS -delete
    check_status "Cleaned old Teleporter backups"
    
    # Remove old config backups
    find "$LOCAL_MOUNT_POINT" -name "pihole-config-*.tar.gz" -type f -mtime +$RETENTION_DAYS -delete
    check_status "Cleaned old config backups"
}

# Function to verify Docker container is running
verify_container_running() {
    if ! docker ps --format '{{.Names}}' | grep -q "^${DOCKER_CONTAINER_NAME}$"; then
        log_message "ERROR: Docker container '$DOCKER_CONTAINER_NAME' is not running"
        exit 1
    fi
    log_message "Verified Docker container '$DOCKER_CONTAINER_NAME' is running"
}

# Function to test SMB connectivity
test_smb_connectivity() {
    log_message "Testing SMB connectivity..."
    if ! ping -c 1 -W 5 "$SMB_SERVER" >/dev/null 2>&1; then
        log_message "ERROR: Cannot reach SMB server at $SMB_SERVER"
        exit 1
    fi
    log_message "SMB server is reachable"
}

# Main execution
main() {
	# Reset the log every time to save space.
	rm -f "$LOG_FILE"

    log_message "Starting Pi-hole backup process"
    
    # Pre-flight checks
    verify_container_running
    test_smb_connectivity
    setup_smb_credentials
    
    # Mount backup location
    mount_smb_share
    
    # Create backups
    create_teleporter_backup
    create_config_backup
    
    # Cleanup old backups
    cleanup_old_backups
    
    # Cleanup and finish
    cleanup_and_exit 0
}

# Trap signals for cleanup
trap 'cleanup_and_exit 1' INT TERM

# Run main function
main "$@"