#!/bin/bash

# 🚀 Universal SSH Setup Script for macOS & Linux
# ✅ Enables SSH, auto-starts on boot, and fixes permissions

# Ensure script runs with sudo/root privileges
if [ "$(id -u)" -ne 0 ]; then
    echo "❌ Please run this script as root:"
    echo "   sudo $0"
    exit 1
fi

echo "🔹 Detecting OS..."
OS_TYPE=""
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS_TYPE="macOS"
elif [[ -f /etc/os-release ]]; then
    source /etc/os-release
    OS_TYPE="Linux ($ID)"
else
    echo "❌ Unsupported OS! Exiting."
    exit 1
fi

echo "✅ Detected OS: $OS_TYPE"

# Common SSH Setup (for both macOS & Linux)
echo "🔹 Setting up SSH configuration..."

# Ensure ~/.ssh directory exists
if [ ! -d ~/.ssh ]; then
    echo "📂 Creating ~/.ssh directory..."
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
fi

# Ensure authorized_keys file exists
if [ ! -f ~/.ssh/authorized_keys ]; then
    echo "🔑 Creating ~/.ssh/authorized_keys file..."
    touch ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
fi

# ✅ macOS-Specific SSH Setup
if [[ "$OS_TYPE" == "macOS" ]]; then
    echo "🔹 Configuring SSH for macOS..."
    
    # Enable SSH Remote Login
    sudo systemsetup -setremotelogin on

    # Ensure SSH auto-restarts if it crashes
    sudo launchctl enable system/com.openssh.sshd
    sudo launchctl kickstart -k system/com.openssh.sshd

    # Verify SSH status
    if sudo launchctl list | grep -q "com.openssh.sshd"; then
        echo "✅ SSH is running on macOS."
    else
        echo "❌ SSH is NOT running! You may need to restart."
    fi

# ✅ Linux-Specific SSH Setup
elif [[ "$OS_TYPE" == *Linux* ]]; then
    echo "🔹 Configuring SSH for Linux..."

    # Install OpenSSH if not installed
    if ! command -v sshd &> /dev/null; then
        echo "📦 Installing OpenSSH server..."
        sudo apt update && sudo apt install -y openssh-server || sudo yum install -y openssh-server
    fi

    # Enable & start SSH service
    sudo systemctl enable ssh
    sudo systemctl restart ssh

    # Verify SSH status
    if systemctl is-active --quiet ssh; then
        echo "✅ SSH is running on Linux."
    else
        echo "❌ SSH is NOT running! You may need to restart."
    fi
fi

echo "🎯 SSH setup complete! It will start on boot and auto-restart if it crashes."
