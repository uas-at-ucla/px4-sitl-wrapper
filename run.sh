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
FRAME_TYPE=$2
LOCATION=$3

DOCKER_IP="192.168.3.20" # drone's docker network ip

unset GAZEBO_MODE
if [ "$FRAME_TYPE" = "" ] || [ "$FRAME_TYPE" = "quad" ]
then
  GAZEBO_MODE="none"
elif [ "$FRAME_TYPE" = "plane" ]
then
  GAZEBO_MODE="plane"
else
  echo "Unknown frame type: $FRAME_TYPE"
  exit 1
fi

SITL_RUN_CMD="cd /Firmware/build/px4_sitl_default/tmp && /Firmware/Tools/sitl_run.sh /Firmware/build/px4_sitl_default/bin/px4 none gazebo $GAZEBO_MODE /Firmware /Firmware/build/px4_sitl_default"

# Determine what action to perform.
if [ "$ACTION" = "build" ]
then
  RUN_CMD="echo 'Docker container built and ran successfully'"
elif [ "$ACTION" = "simulate_headless" ]
then
  RUN_CMD="HEADLESS=1 $SITL_RUN_CMD"
elif [ "$ACTION" = "simulate" ]
then
  RUN_CMD="$SITL_RUN_CMD"
elif [ "$ACTION" = "mavlink_router" ]
then
  while true
  do
    unset PX4_RUNNING_CONTAINER
    while [ -z $PX4_RUNNING_CONTAINER ]
    do
      PX4_RUNNING_CONTAINER=$(docker ps \
        --filter status=running \
        --filter name="uasatucla_px4-simulator" \
        --format "{{.ID}}" \
        --latest
      )

      sleep 0.5
    done

    echo "PX4 simulator docker started!"

    docker exec -it $PX4_RUNNING_CONTAINER \
      bash -c "
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

# Build the docker image.
docker build -t uasatucla/px4-simulator --cache-from uasatucla/px4-simulator --build-arg BUILDKIT_INLINE_CACHE=1 docker

# Run the docker image.
docker run                                                                     \
  -it                                                                          \
  --rm                                                                         \
  -p 14570:14570/udp                                                           \
  -p 14580:14580/udp                                                           \
  -p 5760:5760/tcp                                                             \
  -e DISPLAY=:0                                                                \
  -v /tmp/.X11-unix:/tmp/.X11-unix:ro                                          \
  --name uasatucla_px4-simulator                                               \
  uasatucla/px4-simulator                                                      \
  bash -c "
  set -e
  cd ./Firmware
  export PX4_HOME_LAT=$LATITUDE
  export PX4_HOME_LON=$LONGITUDE
  export PX4_HOME_ALT=$ALTITUDE
  sh -c \"$RUN_CMD\""
