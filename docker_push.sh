#!/bin/bash
docker build -t uasatucla/px4-simulator -f prod.Dockerfile .
echo "$DOCKER_PASSWORD" | docker login -u uasatucla --password-stdin
docker push uasatucla/px4-simulator-env
docker push uasatucla/px4-simulator
