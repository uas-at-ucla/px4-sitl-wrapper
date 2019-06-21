#!/bin/bash

echo "Waiting for PX4 simulator docker to start..."

DOCKER_IP="192.168.3.20" # drone's docker network ip

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
