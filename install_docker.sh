#!/bin/bash

# Function to print status messages
print_status() {
    echo "===> $1"
}

# Update package index
print_status "Updating package index..."
sudo apt-get update

# Add GitHub CLI repository
print_status "Adding GitHub CLI repository..."
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

# Install prerequisites
print_status "Installing prerequisites..."
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    ls b-release \
    software-properties-common

# Add Docker's official GPG key
print_status "Adding Docker's GPG key..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up Docker repository
print_status "Setting up Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index again with all new repositories
print_status "Updating package index with new repositories..."
sudo apt-get update

# Install Docker and additional packages
print_status "Installing Docker and additional packages..."
sudo apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-compose-plugin \
    emacs \
    gh \
    git

# Add current user to docker group
print_status "Adding current user to docker group..."
sudo usermod -aG docker $USER

# Start and enable Docker service
print_status "Starting Docker service..."
sudo systemctl start docker
sudo systemctl enable docker

# Verify installations 
print_status "Verifying installations..."
echo "Docker version:"
docker --version
echo "Git version:"
git --version
echo "GitHub CLI version:"
gh --version
echo "Emacs version:"
emacs --version

./docker_permission_fix.sh

print_status "Installation complete!"
echo "Please log out and log back in for group changes to take effect."
echo "You can test Docker by running: docker run hello-world"
