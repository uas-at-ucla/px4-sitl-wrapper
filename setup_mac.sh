#!/bin/bash

cd "$(dirname "$0")"
cd Firmware
./Tools/setup/OSX.sh
brew tap osrf/simulation
brew install gazebo10
brew install opencv
