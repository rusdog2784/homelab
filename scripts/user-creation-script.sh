#!/bin/bash

# =========================================================
# User Creation Automation Script for Debian 12
# =========================================================
# This script creates a new user with SSH access
# and adds the user to the docker group without sudo permissions.
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
echo "         User Creation Script for Debian 12              "
echo "========================================================="
print_message "This script will create a new user with SSH access"
print_message "and add the user to the docker group without sudo permissions."
echo "========================================================="
echo ""

# Function to get and validate username
get_username() {
    local username
    while true; do
        read -p "Enter the username to create: " username
        
        # Check if username is empty
        if [ -z "$username" ]; then
            print_error "Username cannot be empty. Please try again."
            continue
        fi
        
        # Check if username contains only valid characters (alphanumeric, underscore, hyphen)
        if [[ ! "$username" =~ ^[a-zA-Z0-9_-]+$ ]]; then
            print_error "Username can only contain letters, numbers, underscores, and hyphens. Please try again."
            continue
        fi
        
        # Check if username starts with a letter or underscore
        if [[ ! "$username" =~ ^[a-zA-Z_] ]]; then
            print_error "Username must start with a letter or underscore. Please try again."
            continue
        fi
        
        # Check if username is too long (most systems limit to 32 characters)
        if [ ${#username} -gt 32 ]; then
            print_error "Username is too long (maximum 32 characters). Please try again."
            continue
        fi
        
        # Check if username is a reserved system name
        case "$username" in
            root|bin|daemon|adm|lp|sync|shutdown|halt|mail|operator|games|ftp|nobody|systemd*|_*|backup|www-data|proxy|syslog|list|irc|gnats|uucp|man|postfix|postgres)
                print_error "Username '$username' is reserved by the system. Please choose a different name."
                continue
                ;;
        esac
        
        echo "$username"
        return 0
    done
}

# Get username from user input
USERNAME=$(get_username)
print_success "Username '$USERNAME' will be used for this setup."
echo ""

# Function to check if a package is installed
is_package_installed() {
    dpkg -l "$1" &> /dev/null
    return $?
}

# Function to prompt for user confirmation
confirm_action() {
    local prompt="$1"
    local response
    
    while true; do
        read -p "${prompt} (y/n): " response
        case "${response}" in
            [yY]|[yY][eE][sS])
                return 0
                ;;
            [nN]|[nN][oO])
                return 1
                ;;
            *)
                print_warning "Please answer with y (yes) or n (no)."
                ;;
        esac
    done
}

# Step 1: Check if the user already exists
print_message "Step 1: Checking if user '$USERNAME' already exists..."
if id "$USERNAME" &>/dev/null; then
    print_warning "User '$USERNAME' already exists."
    if confirm_action "Would you like to remove the existing user and create a new one?"; then
        print_message "Removing existing user '$USERNAME'..."
        userdel -r "$USERNAME" 2>/dev/null
        if [ $? -eq 0 ]; then
            print_success "User '$USERNAME' has been removed."
        else
            print_error "Failed to remove user '$USERNAME'."
        fi
    else
        print_message "Keeping existing user '$USERNAME'. Moving to the next step."
    fi
else
    print_message "User '$USERNAME' does not exist. Proceeding with creation."
fi

# Step 2: Create the user
print_message "Step 2: Creating user '$USERNAME'..."
if ! id "$USERNAME" &>/dev/null; then
    if confirm_action "Would you like to create the user '$USERNAME'?"; then
        useradd -m -s /bin/bash "$USERNAME"
        if [ $? -eq 0 ]; then
            print_success "User '$USERNAME' has been created."
            
            # Set default password
            print_message "Setting default password 'ChangeMe!' for user '$USERNAME'..."
            echo "$USERNAME:ChangeMe!" | chpasswd
            print_success "Password has been set."
            print_warning "Please change this default password after first login!"
        else
            print_error "Failed to create user '$USERNAME'."
        fi
    else
        print_message "User creation skipped. Moving to the next step."
    fi
else
    print_message "User '$USERNAME' already exists. Moving to the next step."
fi

# Step 3: Configure SSH access
print_message "Step 3: Configuring SSH access for '$USERNAME'..."
if confirm_action "Would you like to configure SSH access for user '$USERNAME'?"; then
    # Check if SSH is installed
    if ! is_package_installed "openssh-server"; then
        print_warning "OpenSSH server is not installed."
        if confirm_action "Would you like to install OpenSSH server?"; then
            print_message "Installing OpenSSH server..."
            apt-get update && apt-get install -y openssh-server
            if [ $? -eq 0 ]; then
                print_success "OpenSSH server has been installed."
            else
                print_error "Failed to install OpenSSH server."
            fi
        else
            print_message "OpenSSH server installation skipped."
        fi
    fi
    
    # Ensure SSH service is running
    if systemctl is-active --quiet ssh; then
        print_success "SSH service is running."
    else
        print_warning "SSH service is not running."
        if confirm_action "Would you like to start and enable SSH service?"; then
            systemctl enable --now ssh
            if [ $? -eq 0 ]; then
                print_success "SSH service has been started and enabled."
            else
                print_error "Failed to start SSH service."
            fi
        else
            print_message "SSH service activation skipped."
        fi
    fi
    
    # Create .ssh directory for the user if it doesn't exist
    if id "$USERNAME" &>/dev/null; then
        USER_HOME=$(eval echo ~"$USERNAME")
        if [ ! -d "$USER_HOME/.ssh" ]; then
            mkdir -p "$USER_HOME/.ssh"
            chmod 700 "$USER_HOME/.ssh"
            chown "$USERNAME:$USERNAME" "$USER_HOME/.ssh"
            print_success "Created .ssh directory for user '$USERNAME'."
        fi
        
        # Ask if the user wants to add an SSH public key
        if confirm_action "Would you like to add an SSH public key for user '$USERNAME'?"; then
            read -p "Please paste the SSH public key: " ssh_key
            echo "$ssh_key" > "$USER_HOME/.ssh/authorized_keys"
            chmod 600 "$USER_HOME/.ssh/authorized_keys"
            chown "$USERNAME:$USERNAME" "$USER_HOME/.ssh/authorized_keys"
            print_success "SSH public key has been added for user '$USERNAME'."
        else
            print_message "SSH public key addition skipped."
            print_message "Password authentication will be used for SSH login."
        fi
    else
        print_warning "User '$USERNAME' does not exist. Cannot configure SSH access."
    fi
else
    print_message "SSH access configuration skipped. Moving to the next step."
fi

# Step 4: Verify user does not have sudo permissions
print_message "Step 4: Verifying user '$USERNAME' does not have sudo permissions..."
if id "$USERNAME" &>/dev/null; then
    if groups "$USERNAME" | grep -q '\bsudo\b'; then
        print_warning "User '$USERNAME' currently has sudo permissions."
        if confirm_action "Would you like to remove sudo permissions from user '$USERNAME'?"; then
            deluser "$USERNAME" sudo &>/dev/null
            if [ $? -eq 0 ]; then
                print_success "Sudo permissions have been removed from user '$USERNAME'."
            else
                print_error "Failed to remove sudo permissions from user '$USERNAME'."
            fi
        else
            print_message "Sudo permissions removal skipped."
        fi
    else
        print_success "User '$USERNAME' does not have sudo permissions, as requested."
    fi
else
    print_warning "User '$USERNAME' does not exist. Cannot verify sudo permissions."
fi

# Step 5: Summary and verification
print_message "Step 5: Summary and verification..."
echo ""
echo "==================== User Configuration Summary ===================="
if id "$USERNAME" &>/dev/null; then
    print_success "User '$USERNAME' exists"
    print_message "Home directory: $(eval echo ~"$USERNAME")"
    print_message "Shell: $(getent passwd "$USERNAME" | cut -d: -f7)"
    print_message "Groups: $(groups "$USERNAME")"
    
    if getent group docker | grep -q "\b$USERNAME\b"; then
        print_success "User '$USERNAME' is in the docker group"
    else
        print_warning "User '$USERNAME' is NOT in the docker group"
    fi
    
    if groups "$USERNAME" | grep -q '\bsudo\b'; then
        print_warning "User '$USERNAME' has sudo permissions (not as requested)"
    else
        print_success "User '$USERNAME' does NOT have sudo permissions (as requested)"
    fi
    
    if [ -d "$(eval echo ~"$USERNAME")/.ssh" ]; then
        print_success "SSH directory is configured"
    else
        print_warning "SSH directory is NOT configured"
    fi
else
    print_error "User '$USERNAME' does not exist"
fi
echo "=================================================================="

echo ""
print_success "User configuration process completed!"
print_message "You can now SSH into this VM as '$USERNAME' using the password 'ChangeMe!'"
print_warning "Remember to change the default password after first login!"
echo ""

exit 0