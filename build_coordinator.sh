#!/bin/bash

# Exit on any error
set -e

# Function to check if the script is run as root
if [ "$EUID" -eq 0 ]; then
  echo "Please do not run this script as root"
  exit 1
fi

# Function to check and run a script if it hasn't been run today
execute_if_new_day() {
  local script_name=$1
  local base_name=$(basename $script_name)
  local timestamp_file="/tmp/my_script_${base_name}.timestamp"  # Adding unique prefix

  if [ ! -f "$timestamp_file" ] || [ "$(date +%Y-%m-%d)" != "$(cat $timestamp_file)" ]; then
    echo "Running $script_name"
    ./$script_name
    if [ $? -eq 0 ]; then
      echo "$(date +%Y-%m-%d)" > "$timestamp_file"
    else
      echo "Error: $script_name failed to run."
      exit 1
    fi
  else
    echo "$script_name has already been run today"
  fi
}

# Clear all script-related timestamps
rm -f /tmp/my_script_*.timestamp
# rm sign_event_mips sign_event_local RelayLink_mips generate_npub_optimized


##### MIPS Architecture #####

execute_if_new_day "setup_dependencies.sh"
execute_if_new_day "clone_openwrt_sdk.sh"
execute_if_new_day "build_all_dependencies.sh"

##### Generate checksum  #####

# execute_if_new_day "build_all_images.sh"
# execute_if_new_day "extract_ipks.sh"
execute_if_new_day "generate_checksums.sh"
nsite-cli upload binaries/

echo "All tasks completed successfully."

