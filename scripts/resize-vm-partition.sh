#!/bin/bash

# =========================================================
# Partition Resize Guide Script
# =========================================================
# This script provides instructions for resizing a VM's
# partition to use the maximum available disk space.
# =========================================================

# Set text colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Helper function to print formatted messages
print_message() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if script is run as root
if [ "$(id -u)" -ne 0 ]; then
    print_error "This script must be run as root or with sudo privileges."
    exit 1
fi

# Welcome message
clear
echo "========================================================="
echo "         Partition Resize Guide Script                   "
echo "========================================================="
print_message "This script will guide you through resizing a partition."
echo "========================================================="
echo ""

# Check if parted is installed
if ! command -v parted &> /dev/null; then
    print_warning "The parted package is not installed."
    
    read -p "Would you like to install parted? (y/n): " response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        print_message "Installing parted..."
        apt-get update && apt-get install -y parted
        if [ $? -ne 0 ]; then
            print_error "Failed to install parted. Exiting."
            exit 1
        fi
        print_success "Parted has been installed successfully."
    else
        print_error "parted is required for this process. Exiting."
        exit 1
    fi
else
    print_success "parted is already installed."
fi

# Show available disks
print_message "Available disks:"
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT | grep disk
echo ""

# Try to determine the main disk
MAIN_DISK=""
if [ -b "/dev/sda" ]; then
    MAIN_DISK="/dev/sda"
elif [ -b "/dev/vda" ]; then
    MAIN_DISK="/dev/vda"
elif [ -b "/dev/xvda" ]; then
    MAIN_DISK="/dev/xvda"
elif [ -b "/dev/nvme0n1" ]; then
    MAIN_DISK="/dev/nvme0n1"
fi

# Ask user to confirm or enter a different disk
if [ -n "$MAIN_DISK" ]; then
    print_message "The main system disk appears to be: $MAIN_DISK"
    read -p "Would you like to use $MAIN_DISK? (y/n): " response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        DISK_TO_RESIZE="$MAIN_DISK"
    else
        read -p "Please enter the disk path (e.g., /dev/sda): " DISK_TO_RESIZE
    fi
else
    read -p "Please enter the disk path (e.g., /dev/sda): " DISK_TO_RESIZE
fi

# Validate that the disk exists
if [ ! -b "$DISK_TO_RESIZE" ]; then
    print_error "The disk $DISK_TO_RESIZE does not exist. Exiting."
    exit 1
fi

# Show current disk info
print_message "Current partition information for $DISK_TO_RESIZE:"
parted $DISK_TO_RESIZE print
echo ""

# Default to partition 1 with option to change
PARTITION_NUMBER=1
read -p "Enter partition number to resize [1]: " input_partition
[ -n "$input_partition" ] && PARTITION_NUMBER=$input_partition

# Display the manual steps
echo ""
echo "========================================================="
echo "          MANUAL STEPS TO RESIZE YOUR PARTITION          "
echo "========================================================="
echo ""
print_message "Follow these steps to resize partition $PARTITION_NUMBER on $DISK_TO_RESIZE:"
echo ""
print_message "1. $ parted $DISK_TO_RESIZE"
echo ""
print_message "2. (parted) resizepart $PARTITION_NUMBER"
echo ""
print_message "3. Fix/Ignore? Fix"
echo ""
print_message "4. Partition number? $PARTITION_NUMBER"
echo ""
print_message "5. Yes/No? Yes"
echo ""
print_message "6. End? [2146MB]? -0"
echo ""
print_message "7. (parted) quit"
echo ""
print_message "8. reboot now"
echo ""
print_warning "After resizing the partition, you may also need to resize the filesystem."
print_message "For ext4 filesystems, use: sudo resize2fs ${DISK_TO_RESIZE}${PARTITION_NUMBER}"
print_message "For xfs filesystems mounted at /mnt, use: sudo xfs_growfs /mnt"
print_message "For btrfs filesystems mounted at /mnt, use: sudo btrfs filesystem resize max /mnt"
echo ""
print_success "Instructions complete! Follow the steps above to resize your partition."
echo "========================================================="

exit 0