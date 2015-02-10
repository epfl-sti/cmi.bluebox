# Installation script for a fake (i386) OpenWRT Blue Box
#
# To test out your changes:
#
#   1. Install Docker as per the instructions at
#      https://docs.docker.com/installation/, or just run the
#      develop_noc.sh script and follow the instructions
#   2. cd to the directory of this file
#   3. docker build -t epflsti/blueboxfake .
#      docker run -ti epflsti/blueboxfake /bin/bash

FROM solarkennedy/openwrt
MAINTAINER Dominique Quatravaux <dominique.quatravaux@epfl.ch>

RUN mkdir -p /var/lock
RUN opkg update
RUN opkg install tinc

RUN mkdir -p /etc/tinc
