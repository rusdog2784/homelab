#!/bin/bash

# =============================================
# Fresh Debian 12 Installation with Docker
# and Network Configuration
# =============================================

# Function to display help message
display_help() {
    echo "Usage: $0 [OPTIONS]"
    echo "This script performs a fresh Debian 12 installation with Docker and network configuration."
    echo "It will walk you through each step, asking for confirmation before proceeding."
    echo ""
    echo "OPTIONS:"
    echo "  -h, --help    Display this help message and exit."
    echo ""
    echo "SECTIONS (requires 'y' to proceed):"
    echo "  1. Change sudo password."
    echo "  2. Update System Packages: Updates package lists, upgrades installed packages, and installs qemu-guest-agent."
    echo "  3. Install and Configure OpenSSH: Installs OpenSSH server and configures it for root login."
    echo "  4. Install Docker: Installs Docker CE, CLI, containerd, buildx-plugin, and docker-compose-plugin."
    echo "  5. Network Configuration with Netplan: Configures a static IP address and gateway."
    echo "     - Prompts for static IP and gateway."
    echo "     - Optionally backs up existing netplan configurations."
    echo "  6. Hostname Configuration: Sets the system hostname."
    echo "     - Prompts for a hostname."
    echo "  7. Disk resizing: attempts to resize the disk."
    echo "     - Prompts for disk to resize."
    echo "     - Prompts for partition to resize."
    echo "  8. Reboot System: Reboots the system to apply all changes."
    echo ""
    echo "Example: sudo $0"
    exit 0
}

# Check for help flag
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    display_help
fi

# Check if script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "\e[31mERROR: This script must be run as root\e[0m"
    echo -e "Please run with: sudo $0"
    exit 1
fi

# Function to print colored section headers
print_section() {
    echo -e "\n\e[1;34m============================================\e[0m"
    echo -e "\e[1;34m $1 \e[0m"
    echo -e "\e[1;34m============================================\e[0m"
}

# Function to print success messages
print_success() {
    echo -e "\e[1;32m✓ $1\e[0m"
}

# Function to print error messages
print_error() {
    echo -e "\e[1;31m✗ $1\e[0m"
}

# Function to print info messages
print_info() {
    echo -e "\e[1;33mℹ $1\e[0m"
}

# 1. Change sudo password
read -p "Do you want to proceed with changing the root password? (y/n) " confirm_updates
if [ "$confirm_updates" == "y" ]; then
    print_section "Changing root password"
    passwd root
    print_success "Root password updated successfully"
fi

# 2. Update and upgrade packages
read -p "Do you want to proceed with updating system packages? (y/n) " confirm_updates
if [ "$confirm_updates" == "y" ]; then
    print_section "Updating System Packages"
    echo "Updating package lists..."
    apt update || { print_error "Failed to update package lists"; exit 1; }
	echo "Upgrading packages..."
	apt -y upgrade || { print_error "Failed to upgrade packages"; exit 1; }
	echo "Installing qemu-guest-agent for Proxmox..."
	apt-get -y install qemu-guest-agent || { print_error "Failed to install qemu-guest-agent"; exit 1; }
    print_success "System packages updated successfully"
fi

# 3. Install and configure OpenSSH
read -p "Do you want to proceed with installing and configuring OpenSSH? (y/n) " confirm_ssh
if [ "$confirm_ssh" == "y" ]; then
    print_section "Installing and Configuring OpenSSH"
    echo "Installing OpenSSH server..."
    apt install -y openssh-server || { print_error "Failed to install OpenSSH server"; exit 1; }
	echo "Configuring SSH to allow root login..."
	sed -i -e 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' -e 's/^PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
	echo "Restarting SSH service..."
	systemctl restart sshd || { print_error "Failed to restart SSH service"; exit 1; }
    print_success "OpenSSH installed and configured successfully"
fi

# 4. Install Docker and Docker Compose
read -p "Do you want to proceed with installing Docker? (y/n) " confirm_docker_install
if [ "$confirm_docker_install" == "y" ]; then
	# Add Docker's official GPG key
    print_section "Setting Up Docker Repository"
    echo "Installing prerequisites..."
	apt-get install -y ca-certificates curl || { print_error "Failed to install prerequisites"; exit 1; }
	echo "Creating Docker keyring directory..."
	install -m 0755 -d /etc/apt/keyrings
	echo "Downloading Docker's GPG key..."
	curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc || { print_error "Failed to download Docker's GPG key"; exit 1; }
	echo "Setting permissions for Docker's GPG key..."
	chmod a+r /etc/apt/keyrings/docker.asc
    print_success "Docker repository setup completed"
	
	# Add the repository to Apt sources
	print_section "Adding Docker Repository to APT Sources"
    echo "Adding Docker repository to APT sources..."
	echo \
		"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
		$(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
		tee /etc/apt/sources.list.d/docker.list > /dev/null
	echo "Updating package lists with Docker repository..."
	apt-get update || { print_error "Failed to update package lists with Docker repository"; exit 1; }
    print_success "Docker repository added to APT sources"
	
	# Install latest Docker packages
	print_section "Installing Docker"
    echo "Installing Docker packages..."
	apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || { print_error "Failed to install Docker packages"; exit 1; }
    print_success "Docker installed successfully"
fi

# 5. Configure network with netplan
read -p "Do you want to proceed with configuring the network? (y/n) " confirm_network
if [ "$confirm_network" == "y" ]; then
    print_section "Network Configuration with Netplan"

    # Ask for static IP address
	echo -e "\nPlease provide a static IP address (e.g., 10.10.10.10):"
	read static_ip

	# Validate IP address format
	if [[ ! $static_ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
		print_error "Invalid IP address format"
		exit 1
	fi

	# Extract default gateway from IP (replace last octet with 1)
	default_gateway=$(echo $static_ip | sed -E 's/([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})\.([0-9]{1,3})/\1.1/')

	# Ask for DNS server with default value
	echo -e "\nPlease provide a DNS server (default: $default_gateway):"
	read dns_server
	dns_server=${dns_server:-$default_gateway}

	# Validate DNS server format
	if [[ ! $dns_server =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
		print_error "Invalid DNS server format"
		exit 1
	fi

	# Ask for gateway address with default value
	echo -e "\nPlease provide a gateway address (default: $default_gateway):"
	read gateway
	gateway=${gateway:-$default_gateway}

	# Validate gateway address format
	if [[ ! $gateway =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
		print_error "Invalid gateway address format"
		exit 1
	fi

	print_info "Static IP: $static_ip"
	print_info "DNS Server: $dns_server"
	print_info "Gateway: $gateway"

	# Backup existing netplan configurations
	echo "Backing up existing netplan configurations..."
	for config in /etc/netplan/*.yaml; do
		if [ -f "$config" ]; then
	mv "$config" "${config}.backup"
	print_info "Backed up $config to ${config}.backup"
		fi
	done

	# Create new netplan configuration
	echo "Creating new netplan configuration..."
	cat > /etc/netplan/01-netcfg.yaml << EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    ens18:
      dhcp4: false
      addresses:
        - ${static_ip}/24
      nameservers:
        addresses:
        - ${dns_server}
      routes:
        - to: default
          via: ${gateway}
EOF
	
	chmod 600 /etc/netplan/01-netcfg.yaml
	print_success "Created new netplan configuration at /etc/netplan/01-netcfg.yaml"

	# Apply netplan configuration
	echo "Applying netplan configuration..."
	netplan apply && systemctl daemon-reload || { print_error "Failed to apply netplan configuration"; exit 1; }
    print_success "Network configuration applied successfully"
fi

# 6. Configure hostname
read -p "Do you want to proceed with configuring the hostname? (y/n) " confirm_hostname
if [ "$confirm_hostname" == "y" ]; then
    print_section "Hostname Configuration"

    # Ask for hostname with default as localhost
	echo -e "\nPlease provide a hostname (default: localhost): "
	read hostname
	hostname=${hostname:-"localhost"}

	# Validate hostname format
	if [[ ! $hostname =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?$ ]]; then
		print_error "Invalid hostname format"
		exit 1
	fi

	print_info "Setting hostname to: $hostname"

	# Set the hostname
	echo "Setting system hostname..."
	hostnamectl set-hostname "$hostname" || { print_error "Failed to set hostname"; exit 1; }

	# Update /etc/hosts file
	echo "Updating /etc/hosts file..."
	sed -i "2i127.0.1.1       $hostname" /etc/hosts || { print_error "Failed to update /etc/hosts"; exit 1; }

	print_success "Hostname configured successfully"
fi

# 7. Ensure full Disk utilization
read -p "Do you want to proceed with resizing the disk with 'parted'? (y/n) " confirm_parted
if [ "$confirm_parted" == "y" ]; then
    print_section "Disk Resize Configuration"

	# Install parted package
	apt install -y parted 

    # Show available disks
	print_info "Available disks:"
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
		print_info "The main system disk appears to be: $MAIN_DISK"
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

	# Default to partition 1 with option to change
	PARTITION_NUMBER=1
	read -p "Enter partition number to resize [1]: " input_partition
	[ -n "$input_partition" ] && PARTITION_NUMBER=$input_partition

	# Attempt to resize
	parted $DISK_TO_RESIZE resizepart $PARTITION_NUMBER 100%

	print_success "Disk resized successfully"
fi

# Final summary
print_section "Installation Summary"
echo -e "\e[1m- System packages:\e[0m Updated"
echo -e "\e[1m- OpenSSH server:\e[0m Installed and configured"
echo -e "\e[1m- Docker:\e[0m Installed"
echo -e "\e[1m- Network configuration:\e[0m Static IP: $static_ip, Gateway: $gateway"
echo -e "\e[1m- Hostname:\e[0m $hostname"

print_section "Next Steps"
echo "1. The system will now reboot to apply all changes"
echo "2. After reboot, reconnect using your new static IP"
echo "3. Your system will be identified as '$hostname'"
echo "4. You can start using Docker with the 'docker' command"

print_info "Installation completed successfully!"

read -p "Do you want to reboot the system now to apply all changes? (y/n) " confirm_reboot
if [ "$confirm_reboot" == "y" ]; then
    print_info "System will reboot in 5 seconds..."

    # Countdown before reboot
    for i in {5..1}; do
        echo -ne "\r\e[1;33mRebooting in $i...\e[0m"
        sleep 1
    done
    echo -e "\n"

    # Reboot the system
    reboot
else
    print_info "Reboot cancelled. Please reboot manually later to apply all changes."
fi
