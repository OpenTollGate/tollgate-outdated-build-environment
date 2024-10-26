#!/bin/bash

# Repository directory within the container
REPO_DIR="/home/builduser/TollGateNostrToolKit"
BRANCH="dockerize"
WATCH_INTERVAL=30 # Check every 5 minutes to reduce load

cd $REPO_DIR

# Initialize the local repository with the latest state
git fetch origin $BRANCH
git checkout $BRANCH

while true; do
  git fetch origin $BRANCH

  LOCAL=$(git rev-parse $BRANCH)
  REMOTE=$(git rev-parse origin/$BRANCH)

  if [ $LOCAL != $REMOTE ]; then
    echo "New changes detected. Pulling changes and running build_coordinator.sh..."
    git pull origin $BRANCH

    # Run the build coordinator script
    ./build_coordinator.sh
  else
    echo "No new changes. Checking again in $WATCH_INTERVAL seconds..."
  fi

  sleep $WATCH_INTERVAL
done
