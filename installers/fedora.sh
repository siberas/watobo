#!/bin/bash
# TODO: Check for Ruby

echo -e "\e[1;31m* install necessary packages ...\e[0m"
sudo dnf install git wget fox-devel libXrandr-devel libpng-devel \
libXcursor-devel \
libtiff-devel libjpeg-turbo-devel libnfnetlink-devel \
libnetfilter_queue-devel xterm gcc-c++

echo -e "\e[1;31m* cloning watobo from git ...\e[0m"
git clone https://github.com/siberas/watobo.git
cd watobo
bundle install

