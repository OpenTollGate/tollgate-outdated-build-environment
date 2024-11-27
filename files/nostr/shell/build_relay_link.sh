#!/bin/bash

# Define variables
PROGRAM_NAME="RelayLink"
C_FILE="${PROGRAM_NAME}.c"
REPO_URL="https://raw.githubusercontent.com/your-repo/your-project/main/${C_FILE}"

# Function to check if apt-get update has been run today
update_today() {
    last_update=$(stat -c %Y /var/cache/apt/pkgcache.bin)
    current_time=$(date +%s)
    time_difference=$((current_time - last_update))
    # 86400 seconds in a day
    if [ $time_difference -lt 86400 ]; then
        return 0
    else
        return 1
    fi
}

# Function to install dependencies
install_dependencies() {
    echo "Installing dependencies..."
    if update_today; then
        echo "apt-get update was run today. Skipping update."
    else
        sudo apt-get update
    fi
    sudo apt-get install -y libwebsockets-dev libjansson-dev gcc libssl-dev
}

# Function to compile the C program
compile_program() {
    echo "Compiling ${C_FILE}..."
    gcc -o "${PROGRAM_NAME}" "${C_FILE}" -lwebsockets -ljansson -lssl -lcrypto
    if [ $? -eq 0 ]; then
        echo "Compilation successful. The binary is named ${PROGRAM_NAME}."
    else
        echo "Compilation failed."
        exit 1
    fi
}

# Main script execution
install_dependencies
compile_program

echo "Setup complete. You can now run ./${PROGRAM_NAME}"

