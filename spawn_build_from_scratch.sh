#!/bin/bash


# Function to check if Docker image exists
check_docker_image() {
    docker image inspect openwrt-builder >/dev/null 2>&1
    return $?
}

# Function to build Docker image
build_docker_image() {
    echo "Building Docker image 'openwrt-builder'..."
    docker build -t openwrt-builder .
    if [ $? -ne 0 ]; then
        echo "Failed to build Docker image!"
        exit 1
    fi
    echo "Docker image built successfully"
}

# Check and build Docker image if needed
if ! check_docker_image; then
    echo "Docker image 'openwrt-builder' not found"
    build_docker_image
fi


# Function to find a successfully completed container
find_successful_container() {
    # List all stopped containers with openwrt-builder prefix, newest first
    docker ps -a --filter "name=openwrt-builder" --filter "status=exited" --format "{{.Names}}" | while read container; do
        # Check exit code
        exit_code=$(docker inspect --format='{{.State.ExitCode}}' "$container")
        
        # Check for binary file
        docker  exec -i "$container" bash -c '[ -f "/home/builduser/TollGateNostrToolKit/binaries/*sysupgrade*.bin" ]' >/dev/null 2>&1
        has_binary=$?
        
        # Check build logs for success message
        docker logs "$container" | grep -q "OpenWrt build completed successfully!" >/dev/null 2>&1
        has_success_message=$?
        
        if [ "$exit_code" = "0" ] && [ "$has_binary" = "0" ] && [ "$has_success_message" = "0" ]; then
            echo "$container"
            return 0
        fi
    done
}


# Define repositories and their branches
declare -A REPOS=(
    ["$HOME/TollGateGui"]="master"
    ["$HOME/TollGateNostrToolKit"]="dockerize"
    ["$HOME/TollGateFeed"]="main"
)

WATCH_INTERVAL=60 # Check every 60 seconds

# Function to get current commit hash for a repo and branch
get_commit_hash() {
    local repo_path=$1
    local branch=$2
    cd "$repo_path"
    git rev-parse --short HEAD
}

# Function to initialize repository
initialize_repo() {
    local repo_path=$1
    local branch=$2
    local repo_name=$(basename "$repo_path")
    
    echo "Initializing repository: $repo_name"
    
    # Create directory if it doesn't exist
    if [ ! -d "$repo_path" ]; then
        cd $(dirname "$repo_path")
        git clone "https://github.com/OpenTollGate/$repo_name.git"
    fi
    
    # Enter repository and set up branch
    cd "$repo_path"
    
    # Fetch all branches
    git fetch origin
    
    # Check if branch exists locally
    if ! git rev-parse --verify "${branch}" >/dev/null 2>&1; then
        # Create local branch tracking remote branch
        git checkout -b "${branch}" "origin/${branch}"
    else
        # Switch to existing branch
        git checkout "${branch}"
    fi
}

# Function to check for updates in a repository
check_repo_updates() {
    local repo_path=$1
    local branch=$2
    
    cd "$repo_path"
    echo "Checking updates for ${repo_path} on branch ${branch}"
    
    # Fetch latest changes 
    git fetch origin "${branch}"
    
    # Get the latest commit hashes
    if ! LOCAL=$(git rev-parse "${branch}" 2>/dev/null); then
        echo "Local branch not found, creating it..."
        git checkout -b "${branch}" "origin/${branch}"
        return 0
    fi
    
    if ! REMOTE=$(git rev-parse "origin/${branch}" 2>/dev/null); then
        echo "Remote branch not found!"
        return 1
    fi
    
    if [ "$LOCAL" != "$REMOTE" ]; then
        echo "Changes detected, pulling updates..."
        git pull origin "${branch}"
        return 0  # Changes detected
    fi
    return 1  # No changes
}

# Main loop
while true; do
    CHANGES_DETECTED=false
    CONTAINER_SUFFIX=""
    
    # Check each repository for updates
    for REPO_PATH in "${!REPOS[@]}"; do
        BRANCH=${REPOS[$REPO_PATH]}
        
        # Initialize repository if needed
        initialize_repo "$REPO_PATH" "${BRANCH}"
        
        if check_repo_updates "$REPO_PATH" "${BRANCH}"; then
            CHANGES_DETECTED=true
        fi
        
        # Add commit hash to container suffix
        COMMIT_HASH=$(get_commit_hash "$REPO_PATH" "${BRANCH}")
        REPO_NAME=$(basename "$REPO_PATH")
        CONTAINER_SUFFIX="${CONTAINER_SUFFIX}-${REPO_NAME}-${COMMIT_HASH}"
    done

    # Get commit hashes for all repos
    GUI_COMMIT=$(get_commit_hash "$HOME/TollGateGui" "${REPOS["$HOME/TollGateGui"]}")
    TOOLKIT_COMMIT=$(get_commit_hash "$HOME/TollGateNostrToolKit" "${REPOS["$HOME/TollGateNostrToolKit"]}")
    FEED_COMMIT=$(get_commit_hash "$HOME/TollGateFeed" "${REPOS["$HOME/TollGateFeed"]}")
    
    if [ "$CHANGES_DETECTED" = true ]; then
        echo "Changes detected. Rebuilding Docker container..."
        
        # Remove initial dash from container suffix
        CONTAINER_SUFFIX=${CONTAINER_SUFFIX#-}
        
        # Names for both containers
        FULL_BUILD_CONTAINER="openwrt-builder-full-${CONTAINER_SUFFIX}"
        QUICK_BUILD_CONTAINER="openwrt-builder-quick-${CONTAINER_SUFFIX}"
        
        # 1. Start full build from scratch
        echo "Starting full build in container: $FULL_BUILD_CONTAINER"
        sudo docker run -d --name "$FULL_BUILD_CONTAINER" \
            -v "$(pwd)/binaries:/home/builduser/TollGateNostrToolKit/binaries" \
            -e BUILD_TYPE="full" \
            -e GUI_COMMIT="$GUI_COMMIT" \
            -e TOOLKIT_COMMIT="$TOOLKIT_COMMIT" \
            -e FEED_COMMIT="$FEED_COMMIT" openwrt-builder

        # 2. Try to start quick build using existing successful container
        RECENT_CONTAINER=$(find_successful_container)
        
        if [ -n "$RECENT_CONTAINER" ]; then
            echo "Found existing successful container: $RECENT_CONTAINER"

            # Create new container using existing container's image
            EXISTING_IMAGE=$(docker inspect --format='{{.Config.Image}}' "$RECENT_CONTAINER")
    
            echo "Starting quick build in container: $QUICK_BUILD_CONTAINER"
            sudo docker run -d --name "$QUICK_BUILD_CONTAINER" \
                -v "$(pwd)/binaries:/home/builduser/TollGateNostrToolKit/binaries" \
                -e BUILD_TYPE="quick" \
                -e GUI_COMMIT="$GUI_COMMIT" \
                -e TOOLKIT_COMMIT="$TOOLKIT_COMMIT" \
                -e FEED_COMMIT="$FEED_COMMIT" \
                "$EXISTING_IMAGE" \
                /bin/bash -c "cd /home/builduser/TollGateNostrToolKit && \
                            git pull && \
                            ./build_coordinator.sh"
        else
            echo "No successful containers found for quick build"
        fi
        
        echo "Build processes initiated"
    else
        echo "No changes detected. Checking again in $WATCH_INTERVAL seconds..."
    fi
    
    sleep $WATCH_INTERVAL 
done

# docker stop $(docker ps -q --filter "name=openwrt-builder")
# docker container prune
# docker rmi openwrt-builder
# docker build -t openwrt-builder .
