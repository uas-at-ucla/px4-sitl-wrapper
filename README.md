# UAS@UCLA PX4 SITL Wrapper

# Intro to MAVLink, QGroundControl, and the PX4 Simulator

# Contents
* [Overview](/uas-at-ucla/px4-sitl-wrapper/blob/master/README.md#overview)
* [Installing QGroundControl](/uas-at-ucla/px4-sitl-wrapper/blob/master/README.md#installing-qgroundcontrol)
* [Setting Up the Simulator](/uas-at-ucla/px4-sitl-wrapper/blob/master/README.md#setting-up-the-simulator)
* [Using QGroundControl](/uas-at-ucla/px4-sitl-wrapper/blob/master/README.md#using-qgroundcontrol)

# Overview
* [MAVLink](https://mavlink.io/en/): "a very lightweight messaging protocol for communicating with drones"
* [QGroundControl](http://qgroundcontrol.com/): "provides full flight control and mission planning for any MAVLink enabled drone"
* [PX4](https://px4.io/): "an open source flight control software for drones and other unmanned vehicles"
  * [PX4 Simulation](https://dev.px4.io/v1.9.0/en/simulation/index.html): Use the PX4 Firmware in a simulated environment to enable [HITL and/or SITL](https://www.quora.com/What-is-Software-in-the-Loop-SIL) testing.
    * [Gazebo](https://dev.px4.io/v1.9.0/en/simulation/gazebo.html): One of several simulators compatible with PX4 (which we use)

## Diagram
![mavlink-qground-px4-diagram.png](https://uasatucla.org/images/subsystems/controls/mavlink-qgound-px4sim/mavlink-qground-px4-diagram.png)

# Installing QGroundControl
Installing is easy!
**[Installation Instructions](https://docs.qgroundcontrol.com/en/getting_started/download_and_install.html)**

You can also get the iOS/Android app for fun.

# Setting Up the Simulator
[Clone our px4-sitl-wrapper repository](https://github.com/uas-at-ucla/px4-sitl-wrapper.git), which contains the PX4 Firmware and scripts for setting up simulation.
## Running with Docker
See the [Docker Setup instructions on the Software Setup page](https://uasatucla.org/docs/software/tutorials/environment_setup#docker-setup) if you need to install Docker.

If you have Docker, simply run:
```bash
./run.sh simulate_headless
```
The general usage of the script is:
```bash
./run.sh [action] [frame_type] [location] # 'action' is reqiured
```
Take a peak at the script to see what the options are.

### Explanation
The ```simulate_headless``` action runs the PX4 Firmware, which is fed simulated data by Gazebo. You can also use the ```simulate``` action (without "headless") to get a nice GUI that shows the simulated drone, at the expense of more computing resources. The GUI won't work with Docker out of the box (see below for running natively), but you typically don't need it.

## Running Natively on Mac
### Setup
Requires [Python 3](https://docs.python-guide.org/starting/installation/) and [Homebrew](https://brew.sh/).
```bash
cd path/to/px4-sitl-wrapper
./setup_mac.sh
```
There may be an issue with how this script installs python packages. The most reliable way to overcome this is by setting up a virtual environment, which the following script does automatically:
```bash
./setup_python_venv.sh 
```

Message @Ryan Nemiroff if you have any issues running on Mac, the setup script may not cover everything yet.

### Run
```bash
./run_native.sh simulate_headless
```
The usage is the same as for ```run.sh```

**Clean your build:**
Sometimes a good thing to do if you run into problems building:
```cd ./Firmware && make clean && cd ..```

## Running Natively on Linux & Raspberry Pi
Similar to the above, the following may work on desktop Ubuntu, although it hasn't been tested. There is also no support for Ubuntu 19 yet, and you might as well use Docker if on desktop Linux.
```bash
./setup_debian.sh # install px4 & gazebo dependiencies
./setup_python_venv.sh # setup python virtual env & install python dependencies
./run_native.sh simulate_headless # build & run
```
This *has* been tested on [Raspbian Stretch](http://downloads.raspberrypi.org/raspbian_lite/images/raspbian_lite-2019-04-09/) on Raspberry Pi (no support for Buster yet). It takes a while (few hours) so you'll want to run everything at once and leave it running: 
`./setup_debian.sh && ./setup_python_venv.sh && ./run_native.sh simulate_headless`
Optionally, you could use [screen](https://raspi.tv/2012/using-screen-with-raspberry-pi-to-avoid-leaving-ssh-sessions-open) to allow you to close the terminal while it runs.

**Warning:** It's possible to encounter network timeouts in setup_python_venv.sh. If this happens you will just have to re-run it until it works.

You can also just flash [this disk image](https://drive.google.com/open?id=1LZpyXgj1KRLo2XchZBEVLvgntEhZt0Yn) with everything already set up to the SD card. *Note that the disk image is a fixed size, regardless of your SD card capacity, unless you look up how to expand it. This shouldn't matter if you don't plan on using the image for anything else, but you should prefer the "16GB" one (only a 3.4GB download) if your SD card is at least that size.*

**There are a few reasons why you might use Raspberry Pi for the simulator:**
1. You have a Windows computer and don't want to run a virtual machine.
2. A Pi can be easily shared around so people don't have to spend time installing/building on their own machines.
3. It more accurately models having the flight controller software and ground control software on different machines.

# Using QGroundControl
## Establishing Communication
If you run QGroundControl on the same computer as the simulator, QGroundControl will automatically connect to it. However, it is important to know how to connect to a remote machine, whether it be a simulator or the real drone.

The PX4 Firmware uses TCP to communicate with the Gazebo simulator and UDP to communicate with outside world, using [the ports documented here](https://dev.px4.io/master/en/simulation/#default-px4-mavlink-udp-ports) (scroll down on that page to see a nice diagram).

As per the documentation, we will be listening on UDP port 14550 in QGroundControl. We also need to know that the port used to send and receive on the other end (where the PX4 Firmware is running) is 14570.

### Instructions
1. Click on the `Q` icon in the top left in QGroundControl.
2. Select `Comm Links` and then `Add` at the bottom of the screen.
3. In the Type dropdown, select `UDP`.
4. The Listening Port should default to 14550.
5. Click `Add` under Target Hosts.
6. Type in `<address>:14570`, where `<address>` is the IP address or hostname of the machine the simulator is running on. For example, if you are using a Raspberry Pi plugged in to your computer or on your local network, enter `raspberrypi.local:14570`. Note that if you use a hostname like this, it will be converted to the IPv4 address before the configuration is saved.
7. Click `Ok`.
8. Start the simulator and click `Connect` from the `Comm Links` tab.
9. You should see the state of the drone in the status bar, and no longer see "Waiting for Vehicle Connection."
![qground-connection.png](https://uasatucla.org/images/subsystems/controls/mavlink-qgound-px4sim/qground-connection.png)

### How This Works
#### MAVLink Messages
All the messages sent between QGroundControl and the PX4 Firmware are [MAVLink messages](https://mavlink.io/en/messages/common.html#messages).
#### How a Connection is Established
The connection is established like this:
1) QGroundControl sends initial message to simulator w/ destination port **14570**
2) Simulator is listening on this port, so it receives the message and thinks, "Gotcha, I will send all my data to you w/ destination port **14550**," and proceeds to send data.
3) QGroundControl is able to receive data and thinks, "Great! Glad I was listening on port **14550**."

Because of how this works, even if you close QGroundControl, the simulator will still be sending data to your computer. If you were to reopen QGroundControl, it would automatically reconnect since it automatically listens on UDP port 14550. 

Similarly, QGroundControl remembers its last connection, so even if you restart the simulator, QGroundControl would be looking for it and automatically re-establish the connection. These features are a result of the AutoConnect feature in QGrounControl, which can be turned off from Application Settings.

Only if you restart the simulator AND QGroundControl will you have to manually reconnect.

#### Unique Connection
The simulator can only establish a link with one "partner" or ground station. When you establish a connection, the simulator will log your IP address:
```
INFO  [mavlink] partner IP: 192.168.0.11
```
After this, the simulator is forever locked into sending data to that IP address. You cannot connect from a different computer unless you restart the simulator.

Obviously, it could be helpful to connect multiple computers to the drone, so in practice we use [mavlink-router](https://github.com/intel/mavlink-router), which connects to the drone and can route the MAVLink data stream to multiple specific IP addresses.

## Units of Measurement
From the AUVSI SUAS rules, the ground station display "must indicate the UAS speed in KIAS or ground speed in knots" (KIAS is just knots but specifically refers to airspeed). You can switch to these units from General Settings (click on the `Q` icon).
