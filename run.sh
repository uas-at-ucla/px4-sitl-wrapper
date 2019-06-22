#!/bin/bash

#   _    _               _____     ____     _    _    _____   _
#  | |  | |     /\      / ____|   / __ \   | |  | |  / ____| | |          /\
#  | |  | |    /  \    | (___    / / _` |  | |  | | | |      | |         /  \
#  | |  | |   / /\ \    \___ \  | | /_|_|  | |  | | | |      | |        / /\ \
#  | |__| |  / ____ \   ____) |  \ \__,_|  | |__| | | |____  | |____   / ____ \
#   \____/  /_/    \_\ |_____/    \____/    \_____/  \_____| |______| /_/    \_\

################################################################################

cd "$(dirname "$0")";

# Exit if any errors are encountered.
set -e

# Load arguments into variables.
ACTION=$1
LOCATION=$2

PX4_FIRMWARE_PATH="./Firmware"
DOCKER_IP="192.168.3.20" # drone's docker network ip

# Helper functions.
function check-and-reinit-submodules {
    if git submodule status | egrep -q '^[-]|^[+]'
    then
            echo "Need to initialize git submodules"
            git submodule update --init --recursive
    fi
}

# Determine what action to perform.
if [ "$ACTION" = "build" ]
then
  MAKE_CMD="make px4_sitl_default"
elif [ "$ACTION" = "simulate_headless" ]
then
  MAKE_CMD="HEADLESS=1 make px4_sitl_default gazebo"
elif [ "$ACTION" = "simulate" ]
then
  MAKE_CMD="make px4_sitl_default gazebo"
elif [ "$ACTION" = "mavlink_router" ]
then
  while true
  do
    unset PX4_RUNNING_CONTAINER
    while [ -z $PX4_RUNNING_CONTAINER ]
    do
      PX4_RUNNING_CONTAINER=$(docker ps \
        --filter status=running \
        --filter name="uas-at-ucla_px4-simulator" \
        --format "{{.ID}}" \
        --latest
      )

      sleep 0.5
    done

    echo "PX4 simulator docker started!"

    docker exec -it $PX4_RUNNING_CONTAINER \
      su - user bash -c "
      set -e
      mavlink-routerd -e \$HOST_IP:9010 -e $DOCKER_IP:9011 0.0.0.0:14550"
    sleep 1
  done
  exit
else
  echo "Unknown action given: $ACTION"
  exit 1
fi

# Select lat/lng/alt based on selected location
unset LATITUDE
unset LONGITUDE
unset ALTITUDE

if [ "$LOCATION" = "" ]
then
  LOCATION="auvsi_competition"
fi

if [ "$LOCATION" = "apollo_practice" ]
then
  LATITUDE=34.173103
  LONGITUDE=-118.482008
  ALTITUDE=141.122
elif [ "$LOCATION" = "auvsi_competition" ]
then
  LATITUDE=38.147483
  LONGITUDE=-76.427778
  ALTITUDE=141.122
elif [ "$LOCATION" = "ucla_sunken_gardens" ]
then
  LATITUDE=34.071680
  LONGITUDE=-118.440213
  ALTITUDE=141.122
else
  echo "Unknown location given: $LOCATION"
  exit 1
fi

# Check if submodules need to be cloned.
check-and-reinit-submodules

# Set root path of the repository volume on the host machine.
# Note: If docker is called within another docker instance & is trying to start
#       the UAS@UCLA docker environment, the root will need to be set to the
#       path that is used by wherever dockerd is running.
ROOT_PATH=$(git rev-parse --show-superproject-working-tree)
if [ -z "$ROOT_PATH" ]
then
  ROOT_PATH=$(pwd)
fi

if [ ! -z $HOST_ROOT_SEARCH ] && [ ! -z $HOST_ROOT_REPLACE ]
then
  # Need to use path of the host container running dockerd.
  ROOT_PATH=${ROOT_PATH/$HOST_ROOT_SEARCH/$HOST_ROOT_REPLACE}
fi

CURRENT_DIRECTORY=$(pwd)
PWD_LOC=$(python -c "import os.path; print os.path.relpath(\"$CURRENT_DIRECTORY\", \"$ROOT_PATH\")")

# Build and run the docker image. Adjust file permissions of the docker user to
# match the host.
docker build -t uas-at-ucla_px4-simulator docker
docker run                                                                     \
  -it                                                                          \
  --rm                                                                         \
  -v $ROOT_PATH:/home/user/repo                                                \
  --net host                                                                   \
  -e DISPLAY=:0                                                                \
  -v /tmp/.X11-unix:/tmp/.X11-unix:ro                                          \
  --name uas-at-ucla_px4-simulator                                             \
  uas-at-ucla_px4-simulator                                                    \
  bash -c "
  set -e
  cd /home/user/repo
  HOST_USER=\$(stat -c '%u' .)
  HOST_GROUP=\$(stat -c '%u' .)
  getent group \$HOST_USER || groupadd -g \$HOST_GROUP host_group
  usermod -u \$HOST_USER -g \$HOST_GROUP user
  cd $PWD_LOC/Firmware
  sudo -u user -H sh -c \"$MAKE_CMD\""
