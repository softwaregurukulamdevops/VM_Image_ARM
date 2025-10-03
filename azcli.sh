#!/bin/bash

set -e

echo "Installing Azure CLI on Ubuntu..."

# Ensure script is run with sudo/root
if [[ "$EUID" -ne 0 ]]; then
  echo "❌ Please run this script with sudo:"
  echo "   sudo $0"
  exit 1
fi

# Install prerequisites
echo "Installing required packages..."
apt-get update -y
apt-get install -y wget apt-transport-https gnupg lsb-release software-properties-common

# Create GPG directory if it doesn't exist
GPG_DIR="/etc/apt/trusted.gpg.d"
if [ ! -d "$GPG_DIR" ]; then
  echo "Creating missing directory: $GPG_DIR"
  mkdir -p "$GPG_DIR"
fi

# Download and install Microsoft signing key
echo "Adding Microsoft GPG key..."
wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | gpg --dearmor > microsoft.gpg
install -o root -g root -m 644 microsoft.gpg "$GPG_DIR/microsoft.gpg"
rm microsoft.gpg

# Add Azure CLI repository
AZ_REPO=$(lsb_release -cs)
echo "Adding Azure CLI repository for $AZ_REPO..."
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" > /etc/apt/sources.list.d/azure-cli.list

# Update package lists and install Azure CLI
echo "Updating package list and installing Azure CLI..."
apt-get update
apt-get install -y azure-cli

echo -e "\n✅ Azure CLI installed successfully!"
az version
