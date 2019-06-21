FROM ubuntu:18.04

# PX4 base development environment #############################################
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get -y --quiet --no-install-recommends install \
    bzip2 \
    ca-certificates \
    ccache \
    cmake \
    cppcheck \
    curl \
    dirmngr \
    doxygen \
    file \
    g++ \
    gcc \
    gdb \
    git \
    gnupg \
    gosu \
    lcov \
    libfreetype6-dev \
    libgtest-dev \
    libpng-dev \
    lsb-release \
    make \
    ninja-build \
    openjdk-8-jdk \
    openjdk-8-jre \
    openssh-client \
    pkg-config \
    python-pip \
    python-pygments \
    python-setuptools \
    rsync \
    shellcheck \
    tzdata \
    unzip \
    wget \
    xsltproc \
    zip \
  && apt-get -y autoremove \
  && apt-get clean autoclean \
  && rm -rf /var/lib/apt/lists/{apt,dpkg,cache,log} /tmp/* /var/tmp/*

# gtest
RUN cd /usr/src/gtest \
  && mkdir build && cd build \
  && cmake .. && make \
  && cp *.a /usr/lib \
  && cd .. && rm -rf build

RUN python -m pip install --upgrade pip \
  && pip install setuptools pkgconfig wheel \
  && pip install argparse argcomplete coverage jinja2 empy numpy requests serial toml pyyaml cerberus

# manual ccache setup
RUN ln -s /usr/bin/ccache /usr/lib/ccache/cc \
  && ln -s /usr/bin/ccache /usr/lib/ccache/c++

# astyle v2.06
RUN wget -q https://downloads.sourceforge.net/project/astyle/astyle/astyle%202.06/astyle_2.06_linux.tar.gz -O /tmp/astyle.tar.gz \
  && cd /tmp && tar zxf astyle.tar.gz && cd astyle/src \
  && make -f ../build/gcc/Makefile && cp bin/astyle /usr/local/bin \
  && rm -rf /tmp/*

# Gradle (Required to build Fast-RTPS)
RUN wget -q "https://services.gradle.org/distributions/gradle-5.4.1-bin.zip" -O /tmp/gradle-5.4.1-bin.zip \
  && mkdir /opt/gradle \
  && cd /tmp \
  && unzip -d /opt/gradle gradle-5.4.1-bin.zip \
  && rm -rf /tmp/*

ENV PATH "/opt/gradle/gradle-5.4.1/bin:$PATH"

# Fast-RTPS
RUN git clone --recursive https://github.com/eProsima/Fast-RTPS.git -b release/1.7.2 /tmp/Fast-RTPS-1.7.2 \
  && cd /tmp/Fast-RTPS-1.7.2 \
  && mkdir build && cd build \
  && cmake -DTHIRDPARTY=ON -DBUILD_JAVA=ON .. \
  && make && make install \
  && rm -rf /tmp/*

# create user with id 1001 (jenkins docker workflow default)
RUN useradd --shell /bin/bash -u 1001 -c "" -m user && usermod -a -G dialout user

# setup virtual X server
RUN mkdir /tmp/.X11-unix && \
  chmod 1777 /tmp/.X11-unix && \
  chown -R root:root /tmp/.X11-unix
ENV DISPLAY :99

ENV CCACHE_UMASK=000
ENV FASTRTPSGEN_DIR="/usr/local/bin/"
ENV PATH="/usr/lib/ccache:$PATH"
ENV TERM=xterm
ENV TZ=UTC

# SITL UDP PORTS
EXPOSE 14556/udp
EXPOSE 14557/udp

# PX4 gazebo development environment ###########################################
RUN wget --quiet http://packages.osrfoundation.org/gazebo.key -O - | apt-key add - \
  && sh -c 'echo "deb http://packages.osrfoundation.org/gazebo/ubuntu-stable `lsb_release -sc` main" > /etc/apt/sources.list.d/gazebo-stable.list' \
  && apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get -y --quiet --no-install-recommends install \
    ant \
    gazebo9 \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-ugly \
    libeigen3-dev \
    libgazebo9-dev \
    libgstreamer-plugins-base1.0-dev \
    libimage-exiftool-perl \
    libopencv-dev \
    libxml2-utils \
    pkg-config \
    protobuf-compiler \
  && apt-get -y autoremove \
  && apt-get clean autoclean \
  && rm -rf /var/lib/apt/lists/{apt,dpkg,cache,log} /tmp/* /var/tmp/*

# install MAVLink headers
RUN git clone --depth 1 https://github.com/mavlink/c_library_v2.git /usr/local/include/mavlink/v2.0 && rm -rf /usr/local/include/mavlink/v2.0/.git

# Some QT-Apps/Gazebo don't not show controls without this
ENV QT_X11_NO_MITSHM 1

# Gazebo 7 crashes on VM with OpenGL 3.3 support, so downgrade to OpenGL 2.1
# http://answers.gazebosim.org/question/13214/virtual-machine-not-launching-gazebo/
# https://www.mesa3d.org/vmware-guest.html
ENV SVGA_VGPU10 0

# Use UTF8 encoding in java tools (needed to compile jMAVSim)
ENV JAVA_TOOL_OPTIONS=-Dfile.encoding=UTF8

# PX4 ROS development environment ##############################################
ENV DEBIAN_FRONTEND noninteractive
ENV ROS_DISTRO melodic

RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-key C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654 \
  && sh -c 'echo "deb http://packages.ros.org/ros/ubuntu `lsb_release -sc` main" > /etc/apt/sources.list.d/ros-latest.list' \
  && sh -c 'echo "deb http://packages.ros.org/ros-shadow-fixed/ubuntu `lsb_release -sc` main" > /etc/apt/sources.list.d/ros-shadow.list' \
  && apt-get update \
  && apt-get -y --quiet --no-install-recommends install \
    geographiclib-tools \
    libeigen3-dev \
    libgeographic-dev \
    libopencv-dev \
    python-catkin-tools \
    python-tk \
    ros-$ROS_DISTRO-gazebo-ros-pkgs \
    ros-$ROS_DISTRO-mavlink \
    ros-$ROS_DISTRO-mavros \
    ros-$ROS_DISTRO-mavros-extras \
    ros-$ROS_DISTRO-pcl-conversions \
    ros-$ROS_DISTRO-pcl-msgs \
    ros-$ROS_DISTRO-pcl-ros \
    ros-$ROS_DISTRO-ros-base \
    ros-$ROS_DISTRO-rostest \
    ros-$ROS_DISTRO-rosunit \
    ros-$ROS_DISTRO-xacro \
    xvfb \
  && geographiclib-get-geoids egm96-5 \
  && apt-get -y autoremove \
  && apt-get clean autoclean \
  # pip
  && pip install --upgrade matplotlib numpy px4tools pymavlink \
  && rm -rf /var/lib/apt/lists/{apt,dpkg,cache,log} /tmp/* /var/tmp/*

RUN rosdep init && rosdep update

RUN apt-get install -y sudo libreadline-dev

# Install cmavnode #############################################################
RUN git clone https://github.com/MonashUAS/cmavnode.git && \
    cd cmavnode && \
    git submodule update --init && \
    mkdir build && cd build && \
    cmake .. && \
    make && \
    sudo make install

# Install mavlink-router #######################################################
RUN apt-get install -y autoconf automake libtool make pkg-config check g++ librsync-dev libz-dev libssl-dev uthash-dev libyajl-dev python3-pip
RUN pip2 install future
RUN pip3 install future
RUN git clone https://github.com/intel/mavlink-router.git && \
    cd mavlink-router && \
    git submodule update --init --recursive && \
    ./autogen.sh && ./configure CFLAGS='-g -O2' \
        --sysconfdir=/etc --localstatedir=/var --libdir=/usr/lib64 --disable-systemd \
    --prefix=/usr && \
    make && \
    sudo make install
