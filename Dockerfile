# Use an official Ubuntu as the base image
FROM ubuntu:latest

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV SCRIPT_DIR="/home/builduser/TollGateNostrToolKit"
ENV HOME="/home/builduser"
ENV NODE_VERSION=18.x
ENV NOSTR_RELAYS="wss://nos.lol,wss://relay.primal.net,wss://relay.nostr.band,wss://relay.damus.io"
ENV BLOSSOM_SERVERS="https://cdn.satellite.earth,https://files.v0l.io"
ENV DEBUG=nsite*

# Add all necessary tools and dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    git \
    wget \
    unzip \
    sudo \
    adduser \
    htop \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION} | bash - && \
    apt-get install -y nodejs && \
    npm install -g npm@latest

# Create a user with sudo privileges
RUN useradd -m builduser && echo "builduser:builduser" | chpasswd && adduser builduser sudo

# Let the user switch to root temporarily if needed
RUN echo "builduser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/builduser

# Copy the current directory contents into the container at the expected location
COPY . $SCRIPT_DIR

# Ensure all scripts are executable
RUN chmod +x $SCRIPT_DIR/*.sh $SCRIPT_DIR/spawn_build_in_container.sh

# Set the owner of the directory to builduser, including binaries directory
RUN chown -R builduser:builduser $SCRIPT_DIR /home/builduser/TollGateNostrToolKit/binaries

# Create nsite project directory and set permissions
RUN mkdir -p /home/builduser/nsite-project && \
    chown -R builduser:builduser /home/builduser/nsite-project

# Create .npm directory and set permissions
RUN mkdir -p /home/builduser/.npm && \
    chown -R builduser:builduser /home/builduser/.npm && \
    chown -R builduser:builduser /home/builduser

# Switch to the non-root user
USER builduser

# Set the working directory to the expected location
WORKDIR /home/builduser/nsite-project

# Initialize nsite project and install nsite-cli with its dependencies
RUN npm init -y && \
    npm install nsite-cli node-fetch@2 @noble/hashes @noble/secp256k1 @scure/base && \
    npm install

# Add nsite-cli to PATH
ENV PATH="/home/builduser/nsite-project/node_modules/.bin:${PATH}"

# Switch back to the original working directory
WORKDIR $SCRIPT_DIR

# Set the default command to execute the spawn script
# CMD ["./spawn_build_in_container.sh"]
CMD ["./build_coordinator.sh"]

# Keep container running
# CMD ["tail", "-f", "/dev/null"]
