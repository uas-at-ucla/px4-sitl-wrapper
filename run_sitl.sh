#!/bin/bash

#   _    _               _____     ____     _    _    _____   _
#  | |  | |     /\      / ____|   / __ \   | |  | |  / ____| | |          /\
#  | |  | |    /  \    | (___    / / _` |  | |  | | | |      | |         /  \
#  | |  | |   / /\ \    \___ \  | | /_|_|  | |  | | | |      | |        / /\ \
#  | |__| |  / ____ \   ____) |  \ \__,_|  | |__| | | |____  | |____   / ____ \
#   \____/  /_/    \_\ |_____/    \____/    \_____/  \_____| |______| /_/    \_\

################################################################################

# Exit if any errors are encountered.
set -e

# Load arguments into variables.
LOCATION=$1
PX4_FIRMWARE_PATH="./Firmware"

# Select lat/lng/alt based on selected location
unset LATITUDE
unset LONGITUDE
unset ALTITUDE
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
  echo "Unknown location given!"
  exit 1
fi

if [ ! -d "$PX4_FIRMWARE_PATH" ]
then
  echo "Must clone submodules first!"
  exit 1
fi

./build_dockerfile.sh

# Set root path of the repository volume on the host machine.
# Note: If docker is called within another docker instance & is trying to start
#       the UAS@UCLA docker environment, the root will need to be set to the
#       path that is used by wherever dockerd is running.
ROOT_PATH=$(pwd)
if [ ! -z $HOST_ROOT_SEARCH ] && [ ! -z $HOST_ROOT_REPLACE ]
then
  # Need to use path of the host container running dockerd.
  ROOT_PATH=${ROOT_PATH/$HOST_ROOT_SEARCH/$HOST_ROOT_REPLACE}
fi

docker run                                                                     \
  -it                                                                           \
  --rm                                                                         \
  -v $ROOT_PATH/$PX4_FIRMWARE_PATH:/home/user/Firmware                         \
  --net host                                                                   \
  -e DISPLAY=:0                                                                \
  -v /tmp/.X11-unix:/tmp/.X11-unix:ro                                          \
  --name uas-at-ucla_px4-simulator                                             \
  uas-at-ucla_px4-simulator                                                    \
  bash -c "
  set -e
  getent group $(id -g) || groupadd -g $(id -g) host_group
  usermod -u $(id -u) -g $(id -g) user
  chown user /home/user
  cd /home/user/Firmware
  sudo -u user -H sh -c \"HEADLESS=1 make px4_sitl_default gazebo\""
