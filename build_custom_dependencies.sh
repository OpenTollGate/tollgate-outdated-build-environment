#!/bin/bash

set -e

# Define necessary variables
SCRIPT_DIR="$HOME/TollGateNostrToolKit"
OPENWRT_DIR="$HOME/openwrt"
ROUTERS_DIR="$SCRIPT_DIR/routers"

# Get commit hashes for all repos
GUI_COMMIT=$(git -C "$HOME/TollGateGui" rev-parse -- short HEAD)
TOOLKIT_COMMIT=$(git -C "$HOME/TollGateNostrToolKit" rev-parse --short HEAD)
FEED_COMMIT=$(git -C "$HOME/TollGateFeed" rev-parse --short HEAD)


# Define a function to map router types to target and subtarget
get_target_subtarget() {
    local router_type=$1
    case $router_type in
        "ath79_gl-ar300m-nor")
            echo "ath79 nand"
            ;;
        "ramips_mt7621")
            echo "ramips mt7621"
            ;;
        # Add more mappings here as needed
        *)
            echo "unknown unknown"
            ;;
    esac
}

# Debug: Print current paths and variables
echo "SCRIPT_DIR: $SCRIPT_DIR"
echo "OPENWRT_DIR: $OPENWRT_DIR"

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <router_type>"
    echo "Available options:"
    for file in "$ROUTERS_DIR"/*_config; do
        basename "${file}" | sed 's/_config$//'
    done
    tail -f /dev/null
    exit 1
fi

ROUTER_TYPE=$1

# Function to get the latest commit hash
get_latest_commit() {
    git -C "$1" rev-parse HEAD
}

# Function to check if router configs have changed
check_router_changes() {
    echo "Checking for router config changes..."
    if [ ! -f "$OPENWRT_DIR/.last_build_commit" ]; then
        echo "Change detected: No previous build commit file found."
        return 0
    fi
    local last_commit=$(cat "$OPENWRT_DIR/.last_build_commit")
    echo "Last build commit: $last_commit"
    echo "Current commit: $(git -C "$SCRIPT_DIR" rev-parse HEAD)"
    echo "Checking for changes in routers/ directory since last build..."
    if git -C "$SCRIPT_DIR" diff --quiet "$last_commit" HEAD -- routers/; then
        echo "No changes detected in routers/ directory."
        return 1
    else
        echo "Changes detected in routers/ directory."
        git -C "$SCRIPT_DIR" diff --name-only "$last_commit" HEAD -- routers/
        return 0
    fi
}

# Function to check if custom feeds have changed
check_custom_feed_changes() {
    echo "Checking for custom feed changes..."
    if [ ! -f "$OPENWRT_DIR/.last_build_info" ]; then
        echo "Change detected: No previous build info file found."
        return 0
    fi
    local last_custom_feed_commit=$(grep CUSTOM_FEED_COMMIT "$OPENWRT_DIR/.last_build_info" | cut -d= -f2)
    echo "Last custom feed commit: $last_custom_feed_commit"
    echo "Current custom feed commit: $CUSTOM_FEED_COMMIT"
    if [ "$CUSTOM_FEED_COMMIT" != "$last_custom_feed_commit" ]; then
        echo "Custom feed commit has changed."
        return 0
    else
        echo "No changes in custom feed commit."
        return 1
    fi
}

# Function to extract custom feed info from feeds.conf
get_custom_feed_info() {
    local feeds_conf="$1"
    grep "^src-git-full custom" "$feeds_conf" | awk '{print $3}' | sed 's/;/ /'
}

# Get custom feed URL and branch
read CUSTOM_FEED_URL CUSTOM_FEED_BRANCH <<< $(get_custom_feed_info "$SCRIPT_DIR/feeds.conf")
CUSTOM_FEED_NAME=$(basename "$CUSTOM_FEED_URL" .git)
CUSTOM_FEED_DIR="$HOME/$CUSTOM_FEED_NAME"

# Clone or update custom feed repository
if [ ! -d "$CUSTOM_FEED_DIR" ]; then
    git clone -b "$CUSTOM_FEED_BRANCH" "$CUSTOM_FEED_URL" "$CUSTOM_FEED_DIR"
else
    git -C "$CUSTOM_FEED_DIR" fetch
    git -C "$CUSTOM_FEED_DIR" checkout "$CUSTOM_FEED_BRANCH"
    git -C "$CUSTOM_FEED_DIR" pull origin "$CUSTOM_FEED_BRANCH"
fi

echo "CUSTOM_FEED_DIR: $CUSTOM_FEED_DIR"
echo "CUSTOM_FEED_BRANCH: $CUSTOM_FEED_BRANCH"

cd $OPENWRT_DIR

# Get current commit hashes
SCRIPT_COMMIT=$(get_latest_commit "$SCRIPT_DIR")
CUSTOM_FEED_COMMIT=$(get_latest_commit "$CUSTOM_FEED_DIR")

# Check if rebuild is necessary
REBUILD_NEEDED=false
if check_router_changes || check_custom_feed_changes; then
    REBUILD_NEEDED=true
    echo "Changes detected. Rebuild needed."
else
    REBUILD_NEEDED=false
    echo "No changes detected. Using existing build."
fi

# Check if only configuration has changed
CONFIG_CHANGED=false
if [ "$SCRIPT_COMMIT" != "$(grep SCRIPT_COMMIT .last_build_info | cut -d= -f2)" ]; then
    CONFIG_CHANGED=true
fi

cp $SCRIPT_DIR/feeds.conf $OPENWRT_DIR/feeds.conf

# Update and install feeds if needed
if [ "$REBUILD_NEEDED" = true ] || [ ! -f .feeds_updated ]; then
    ./scripts/feeds update -a
    ./scripts/feeds install -a
    touch .feeds_updated
fi

# Copy configuration files
CONFIG_FILE="$ROUTERS_DIR/${ROUTER_TYPE}_config"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Configuration file for ${ROUTER_TYPE} not found!"
    echo "Available options:"
    for file in "$ROUTERS_DIR"/*_config; do
        basename "${file}" | sed 's/_config$//'
    done
    tail -f /dev/null
    exit 1
fi
cp $CONFIG_FILE $OPENWRT_DIR/.config

make oldconfig

# Clean the build environment if rebuild is needed
if [ "$REBUILD_NEEDED" = true ]; then
    echo "Cleaning the build environment..."
    make clean
fi

# Install toolchain if needed
if [ "$REBUILD_NEEDED" = true ] || [ ! -f .toolchain_installed ]; then
    make -j$(nproc) toolchain/install
    touch .toolchain_installed
fi

# Run install_script.sh
$SCRIPT_DIR/install_script.sh "$SCRIPT_DIR" "$OPENWRT_DIR"

echo "Checking if rebuild is needed..."
if check_router_changes; then
    REBUILD_NEEDED=true
    echo "Rebuild needed due to router config changes."
elif check_custom_feed_changes; then
    REBUILD_NEEDED=true
    echo "Rebuild needed due to custom feed changes."
else
    REBUILD_NEEDED=false
    echo "No changes detected. Using existing build."
fi

# Use make if needed, else use image builder
if [ "$REBUILD_NEEDED" = true ] || [ ! -f .firmware_built ] || [ .feeds_updated -nt .firmware_built ]; then
    echo "Building OpenWrt..."
    make -j$(nproc) V=sc > make_logs.md 2> >(tee -a make_logs.md >&2)

    touch .firmware_built
    
    # Update the last build commit and build info
    git -C "$SCRIPT_DIR" rev-parse HEAD > "$OPENWRT_DIR/.last_build_commit"
    echo "SCRIPT_COMMIT=$SCRIPT_COMMIT" > "$OPENWRT_DIR/.last_build_info"
    echo "CUSTOM_FEED_COMMIT=$CUSTOM_FEED_COMMIT" >> "$OPENWRT_DIR/.last_build_info"
elif [ "$CONFIG_CHANGED" = true ]; then
    echo "Configuration changed. Generating new sysupgrade.bin from existing binaries."

    # Get target and subtarget based on router type
    read TARGET SUBTARGET <<< $(get_target_subtarget "$ROUTER_TYPE")

    if [ "$TARGET" = "unknown" ] || [ "$SUBTARGET" = "unknown" ]; then
        echo "Error: Unknown router type $ROUTER_TYPE"
	tail -f /dev/null
        exit 1
    fi


    # Define a boolean variable to toggle between approaches
    USE_MAKE_APPROACH=true

    if [ "$USE_MAKE_APPROACH" = true ]; then
	cp -Ru files/* build_dir/target-mips_24kc_musl/root-ath79/
	make target/install -j$(nproc) V=sc
    else
	# Use the conventional build_images.sh approach
	# Get the profile name from the config file
	PROFILE=$(grep 'CONFIG_TARGET_PROFILE' $CONFIG_FILE | cut -d'"' -f2)
	
	# Get the list of packages from the config file
	PACKAGES=$(grep 'CONFIG_PACKAGE_' $CONFIG_FILE | grep '=y' | sed 's/CONFIG_PACKAGE_//g' | sed 's/=y//g' | tr '\n' ' ')

	# Use build_images.sh to create the firmware
	$SCRIPT_DIR/build_images.sh "${TARGET}/${SUBTARGET}" "$PROFILE" "$PACKAGES"
    fi
else
    echo "No changes detected. Using existing build."
fi

# Find and display the generated IPK files
echo "Finding the generated IPK files..."
TARGET_DIR="$OPENWRT_DIR/bin/packages"

# Array of file patterns to search for
file_patterns=(
    "libwebsockets*.ipk"
    "libwally*.ipk"
    "opennds*.ipk"
    "gltollgate*.ipk"
    "relaylink*.ipk"
    "signevent*.ipk"
)

# Flag to track if all files are found
all_files_found=true

# Loop through each file pattern
for pattern in "${file_patterns[@]}"; do
    # Find the file
    found_file=$(find "$TARGET_DIR" -type f -name "$pattern")
    
    # Check if the file was found
    if [ -z "$found_file" ]; then
        echo "Error: $pattern not found"
        all_files_found=false
    else
        echo "Found: $found_file"
    fi
done

# Exit with status 1 if any file wasn't found
if [ "$all_files_found" = false ]; then
    echo "One or more required IPK files were not found."
    tail -f /dev/null
    exit 1
fi

echo "All required IPK files were found successfully."

# Find the sysupgrade.bin file
SYSUPGRADE_FILE=$(find "$OPENWRT_DIR/bin" -type f -name "*sysupgrade.bin")

# Check if file was found
if [ -z "$SYSUPGRADE_FILE" ]; then
    echo "No sysupgrade.bin file found."
    tail -f /dev/null
    exit 1
fi

# Determine build type based on REBUILD_NEEDED
BUILD_TYPE="quick"
if [ "$REBUILD_NEEDED" = true ]; then
    BUILD_TYPE="full"
fi

# Generate new filename using the shared script
BASE_FILENAME=$(basename "$SYSUPGRADE_FILE")
NEW_FILENAME=$("$SCRIPT_DIR/generate_firmware_name.sh" \
    "$BASE_FILENAME" \
    "$BUILD_TYPE" \
    "$GUI_COMMIT"  \
    "$TOOLKIT_COMMIT" \
    "$FEED_COMMIT")

# Copy the file to the destination directory with the new filename
cp "$SYSUPGRADE_FILE" "$HOME/TollGateNostrToolKit/binaries/$NEW_FILENAME"

# Check if copy was successful
if [ $? -eq 0 ]; then
    echo "Successfully copied $NEW_FILENAME to ~/TollGateNostrToolKit/binaries/."
else
    echo "Failed to copy file."
    tail -f /dev/null
    exit 1
fi

echo "OpenWrt build completed successfully!"
