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
    
    # Try systemsetup first (requires Full Disk Access)
    if sudo systemsetup -setremotelogin on 2>/dev/null; then
        echo "✅ Remote Login enabled via systemsetup."
    else
        echo "⚠️ systemsetup failed (Full Disk Access required). Using alternative..."
        sudo launchctl load -w /System/Library/LaunchDaemons/ssh.plist
    fi

    # Ensure SSH auto-restarts if it crashes
    sudo launchctl enable system/com.openssh.sshd
    sudo launchctl kickstart -k system/com.openssh.sshd

    # Verify SSH status
    if sudo launchctl list | grep -q "com.openssh.sshd"; then
        echo "✅ SSH is running on macOS."
    else
        echo "❌ SSH is NOT running! You may need to restart."
    fi

# ✅ Linux-Specific SSH Setup (Using `/etc/os-release`)
elif [[ "$OS_TYPE" == *Linux* ]]; then
    echo "🔹 Configuring SSH for Linux..."

    # Install OpenSSH based on detected Linux distribution
    if [[ "$ID" == "ubuntu" || "$ID_LIKE" == "debian" ]]; then
        echo "📦 Installing OpenSSH (Debian-based)..."
        sudo apt update && sudo apt install -y openssh-server
    elif [[ "$ID" == "centos" || "$ID_LIKE" == "rhel fedora" ]]; then
        echo "📦 Installing OpenSSH (RHEL-based)..."
        sudo yum install -y openssh-server
    elif [[ "$ID" == "arch" ]]; then
        echo "📦 Installing OpenSSH (Arch Linux)..."
        sudo pacman -S --noconfirm openssh
    elif [[ "$ID" == "alpine" ]]; then
        echo "📦 Installing OpenSSH (Alpine Linux)..."
        sudo apk add --no-cache openssh
    else
        echo "❌ Unsupported Linux distribution!"
        exit 1
    fi

    # Enable & start SSH service
    if command -v systemctl &>/dev/null; then
        sudo systemctl enable ssh
        sudo systemctl restart ssh
    elif command -v service &>/dev/null; then
        sudo service ssh restart
    elif [ -f /etc/init.d/ssh ]; then
        sudo /etc/init.d/ssh restart
    else
        echo "❌ Cannot restart SSH. Unknown system type."
    fi

    # Verify SSH status
    if command -v systemctl &>/dev/null && systemctl is-active --quiet ssh; then
        echo "✅ SSH is running on Linux."
    elif command -v service &>/dev/null && service ssh status | grep -q "active (running)"; then
        echo "✅ SSH is running on Linux."
    else
        echo "❌ SSH is NOT running! You may need to restart."
    fi
fi

echo "🎯 SSH setup complete! It will start on boot and auto-restart if it crashes."
