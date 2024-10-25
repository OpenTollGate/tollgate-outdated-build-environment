#!/bin/bash

# Define repositories and their branches
declare -A REPOS=(
    ["$HOME/TollGateGui"]="main"
    ["$HOME/TollGateNostrToolKit"]="dockerize"
)

WATCH_INTERVAL=60 # Check every 60 seconds

# Function to get current commit hash for a repo and branch
get_commit_hash() {
    local repo_path=$1
    local branch=$2
    cd "$repo_path"
    git rev-parse --short HEAD
}

# Function to check for updates in a repository
check_repo_updates() {
    local repo_path=$1
    local branch=$2 
    
    cd "$repo_path"
    git fetch origin $branch
    
    LOCAL=$(git rev-parse $branch)
    REMOTE=$(git rev-parse origin/$branch)
    
    if [ "$LOCAL" != "$REMOTE" ]; then
        git pull origin $branch
        return 0  # Changes detected
    fi
    return 1  # No changes
}

while true; do
    CHANGES_DETECTED=false
    CONTAINER_SUFFIX=""
    
    # Check each repository for updates
    for REPO_PATH in "${!REPOS[@]}"; do
        BRANCH=${REPOS[$REPO_PATH]}
        
        # Create directory if it doesn't exist
        if [ ! -d "$REPO_PATH" ]; then
            REPO_NAME=$(basename "$REPO_PATH")
            cd $(dirname "$REPO_PATH")
            git clone "https://github.com/OpenTollGate/$REPO_NAME.git"
            cd "$REPO_PATH"
            git checkout $BRANCH
        fi
        
        if check_repo_updates "$REPO_PATH" "$ BRANCH"; then
            CHANGES_DETECTED=true
        fi
        
        # Add commit hash to container suffix
        COMMIT_HASH=$(get_commit_hash "$REPO_PATH" "$BRANCH")
        REPO_NAME=$(basename "$REPO_PATH")
        CONTAINER_SUFFIX="${CONTAINER_SUFFIX}-${REPO_NAME}-${COMMIT_HASH}"
    done
    
    if [ "$CHANGES_DETECTED" = true ]; then
        echo "Changes detected. Rebuilding Docker container..."
        
        # Remove initial dash from container suffix
        CONTAINER_SUFFIX=${CONTAINER_SUFFIX#-}
        CONTAINER_NAME="openwrt-builder-${CONTAINER_SUFFIX}"
        
        # Stop and remove existing container if it exists
        if [ "$(docker ps -aq -f name=$CONTAINER_NAME)" ]; then
            sudo docker stop $CONTAINER_NAME || true
            sudo docker rm $CONTAINER_NAME || true
        fi
        
        # Build and run new container
        cd "$HOME/TollGateNostrToolKit"
        sudo docker build -t openwrt-builder .
        sudo docker run -d --name $CONTAINER_NAME \
            -v "$(pwd)/binaries:/home/builduser/TollGateNostrToolKit/binaries" \ 
            openwrt-builder
        
        echo "New container started: $CONTAINER_NAME"
    else
        echo "No changes detected. Checking again in $WATCH_INTERVAL seconds..."
    fi
    
    sleep $WATCH_INTERVAL
done
