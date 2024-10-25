#!/bin/bash

# generate_firmware_name.sh

# Parameters:
# $1: Base sysupgrade filename
# $2: Build type (full/quick)
# $3: TollGateGui commit hash
# $4: TollGateNostrToolKit commit hash
# $5: TollGateFeed commit hash

generate_firmware_name() {
    local base_filename=$1
    local build_type=$2
    local gui_commit=$3
    local toolkit_commit=$4
    local feed_commit=$5

    # Remove .bin extension if present
    base_filename=${base_filename%.bin}

    # Create the new filename with all commit hashes an d build type
    echo "${base_filename}_gui-${gui_commit}_toolkit-${toolkit_commit}_feed-${feed_commit}_${build_type}.bin"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Script is being run directly
    if [ "$#" -ne 5 ]; then
        echo "Usage: $0 <base_filename> <build_type> <gui_commit> <toolkit_commit> <feed_commit>"
        echo "Example: $0 openwrt-ath79-nand-glinet_gl-ar300m-nor-squashfs-sysupgrade full abc123 def456 ghi789"
        exit 1
    fi

    generate_firmware_name "$1" "$2" "$3" "$4" "$5"
fi
