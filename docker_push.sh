#!/bin/bash
echo "$DOCKER_PASSWORD" | docker login -u uasatucla --password-stdin
docker push uasatucla/px4-simulator
