#!/bin/bash

# Function to print status messages
print_status() {
    echo "===> $1"
}

# Check if script is run as root
if [ "$EUID" -eq 0 ]; then 
    print_status "Please run this script as a normal user (not root)"
    exit 1
fi

# Function to check Docker access
check_docker() {
    if docker ps &>/dev/null; then
        print_status "Docker is now accessible without sudo!"
        return 0
    else
        print_status "Docker is still not accessible without sudo"
        return 1
    fi
}

print_status "Starting Docker permission fix..."

# Stop all Docker services
print_status "Stopping Docker services..."
sudo systemctl stop docker.socket
sudo systemctl stop docker.service

#  Reset Docker group
print_status "Resetting Docker group..."
sudo groupdel docker || true
sudo groupadd docker

# Add current user to Docker group
print_status "Adding current user to Docker group..."
sudo usermod -aG docker $USER

# Remove existing socket
print_status "Removing existing Docker socket..."
sudo rm -rf /var/run/docker.sock

# Restart Docker daemon
print_status "Restarting Docker daemon..."
sudo systemctl daemon-reload
sudo systemctl start docker

# Fix socket permissions
print_status "Setting Docker socket permissions..."
sudo chown root:docker /var/run/docker.sock
sudo chmod 666 /var/run/docker.sock

# Start Docker services
print_status "Starting Docker services..."
sudo systemctl start docker.socket
sudo systemctl start docker.service

# Verify Docker service status
print_status "Verifying Docker service status..."
sudo systemctl status docker --no-pager

# Check current groups
print_status "Current group membership:"
groups

# Check socket permissions
print_status "Docker socket permissions:"
ls -l /var/run/docker.sock

print_status "Testing Docker access..."
if check_docker; then
    print_status "Setup  completed successfully!"
else
    print_status "Additional steps required:"
    echo "1. Log out of your current session completely"
    echo "2. Log back in"
    echo "3. Run: docker ps"
    echo ""
    echo "Or, start a new shell session with:"
    echo "exec su -l $USER"
fi

print_status "Script completed! If Docker is still not accessible without sudo,"
print_status "please log out of your system completely and log back in."
