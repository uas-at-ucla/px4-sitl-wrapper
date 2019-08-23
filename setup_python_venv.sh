#!/bin/bash

cd "$(dirname "$0")"

python3 -m venv px4_venv
source px4_venv/bin/activate
pip install -r ./Firmware/Tools/setup/requirements.txt

cd ./Firmware
make clean
