#!/bin/bash

set -e

echo "Installing Azure CLI on Ubuntu..."

# Step 1: Download Microsoft signing key using wget and install it
echo "Adding Microsoft signing key..."
wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/microsoft.gpg

# Step 2: Add the Azure CLI software repository
echo "Adding Azure CLI repository..."
AZ_REPO=$(lsb_release -cs)
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | sudo tee /etc/apt/sources.list.d/azure-cli.list

# Step 3: Update package information
echo "Updating package list..."
sudo apt-get update

# Step 4: Install the Azure CLI
echo "Installing Azure CLI..."
sudo apt-get install -y azure-cli

# Step 5: Verify installation
echo -e "\n✅ Azure CLI installation complete. Version:"
az version
