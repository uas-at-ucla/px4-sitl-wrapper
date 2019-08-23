#!/bin/bash

cd "$(dirname "$0")"
cd ./Firmware

# setup script provided by PX4
./Tools/setup/OSX.sh

# install gazebo
brew tap osrf/simulation
brew install gazebo10
brew install opencv
