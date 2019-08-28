#!/bin/bash

cd "$(dirname "$0")"
cd ./Firmware

# Setup script provided by PX4
./Tools/setup/OSX.sh

# Install gazebo
brew tap osrf/simulation
brew install gazebo10

# Needed to compile sitl gazebo code (there's probably a lot missing that I just happened to already have installed)
brew install opencv
