#!/bin/bash

# Variables
USRP_DIR="/opt/USRP2M17"
GIT_DIR=~/git  # Path to the cloned repository directory
SIGCONTEXT_FILE="/usr/include/asm/sigcontext.h"  # Path to the sigcontext.h file

# Determine the OS type based on the kernel version
KERNEL_VERSION=$(uname -r)
if [[ "$KERNEL_VERSION" == *"hamvoip"* ]]; then
    OS_TYPE="HAMVOIP"
else
    OS_TYPE="ASL"
fi

echo "Operating system type determined: $OS_TYPE"  # Debugging output

# Function to install pip for Python 3.5 (if pip is not installed)
install_pip() {
    echo "Checking and installing pip for Python 3.5..."
    if ! command -v pip3 &> /dev/null; then
        wget https://bootstrap.pypa.io/pip/3.5/get-pip.py
        python3 get-pip.py
    else
        echo "pip3 is already installed."
    fi
}

# Function to check and install pip requests
install_pip_requests() {
    echo "Installing Python requests..."
    pip3 install requests
}

# Function to install packages based on the OS
install_packages() {
    echo "Updating package list and installing required packages..."
    if [ "$OS_TYPE" == "HAMVOIP" ]; then
        # Install pip using get-pip.py if not already installed
        install_pip
    else
        # For Allstarlink (ASL), use apt
        sudo apt update
        sudo apt install -y python3 python3-pip
    fi
}

# Function to backup the original sigcontext.h file
backup_sigcontext() {
    echo "Backing up the original sigcontext.h..."
    sudo cp "$SIGCONTEXT_FILE" "${SIGCONTEXT_FILE}.bak"
}

# Function to modify sigcontext.h
modify_sigcontext() {
    echo "Modifying sigcontext.h to use uint64_t instead of __uint128_t..."
    sudo sed -i 's/__uint128_t/uint64_t/' "$SIGCONTEXT_FILE"
}

# Function to revert sigcontext.h to its original state
revert_sigcontext() {
    echo "Reverting sigcontext.h to its original state..."
    sudo mv "${SIGCONTEXT_FILE}.bak" "$SIGCONTEXT_FILE"
}

# Main Installation Process
echo "Starting installation for $OS_TYPE..."

# Install necessary packages
install_packages

# Stop the USRP2M17 service if it's running
sudo systemctl stop usrp2m17.service

# Backup the sigcontext.h file
backup_sigcontext

# Modify the sigcontext.h file
modify_sigcontext

# Clone the repository if it doesn't exist
if [ ! -d "$GIT_DIR/MMDVM_CM" ]; then
    git clone https://github.com/g4klx/MMDVM_CM.git "$GIT_DIR"
fi

# Navigate to the USRP2M17 directory and compile
cd "$GIT_DIR/MMDVM_CM/USRP2M17" || { echo "Failed to change directory"; exit 1; }

# Compile the USRP2M17 code
make
if [ $? -ne 0 ]; then
    echo "Errors occurred during compilation. Reverting sigcontext.h and exiting."
    revert_sigcontext
    exit 1
fi

# Revert the sigcontext.h file after compiling
revert_sigcontext

# Create necessary directories
sudo mkdir -p $USRP_DIR
sudo mkdir -p /var/log/usrp

# Copy compiled files to the installation directory
sudo cp USRP2M17 $USRP_DIR
sudo cp *.ini $USRP_DIR

# Set permissions
sudo chown -R root:root $USRP_DIR
sudo chmod -R 755 $USRP_DIR

# Configure and start the service
sudo cp usrp2m17.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl start usrp2m17.service
sudo systemctl enable usrp2m17.service

echo "Installation complete."
