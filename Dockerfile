# Installation script for the Blue Box NOC
#
# To test out your changes:
#   1. Install Docker as per the instructions at
#      https://docs.docker.com/installation/, or just run the
#      develop_noc.sh script and follow the instructions
#   2. cd to the directory of this file
#   3. docker build -t epflsti/blueboxnoc:dev .
#      docker run -ti epflsti/blueboxnoc:dev /bin/bash
#
# To enact the changes, run build.sh again and restart the container
# with start_stop.sh restart.

FROM ubuntu
MAINTAINER Dominique Quatravaux <dominique.quatravaux@epfl.ch>

RUN apt-get update && apt-get -y upgrade && apt-get install -y tinc curl

# https://github.com/joyent/node/wiki/installing-node.js-via-package-manager#debian-and-ubuntu-based-linux-distributions
RUN curl -sL https://deb.nodesource.com/setup | sudo bash -
RUN apt-get install -y nodejs

# http://www.rexify.org/get
RUN apt-get -y install build-essential libexpat1-dev libxml2-dev libssh2-1-dev libssl-dev
RUN curl -L get.rexify.org | perl - --sudo -n Rex

# Apache
RUN apt-get install -y apache2

# Remove all setuid privileges to lock down non-root users in the container
RUN find / -xdev -perm /u=s,g=s -print -exec chmod u-s,g-s '{}' \;
# Something really fishy is going on with
# /usr/bin/mail-{lock,touchlock,unlock}; these are all hard links to the same
# file, but chmod'ing any of these breaks the hard link ?! Probably a side
# effect of the filesystem fakes that Docker uses. Take no risk and just nuke
# the whole Debian package from orbit.
RUN dpkg --purge lockfile-progs
# Double check there are no setuid / setgid files left over.
RUN find / -xdev -perm /u=s,g=s | sed '/./q1'

# Expected mount points (see shlib/start_stop.sh):
# Code directory (top of the git checkout) -> /opt/blueboxnoc
# Data directory (w/ all persistent state) -> /srv
CMD ["/opt/blueboxnoc/plumbing/init.pl"]

EXPOSE 80
# For tinc:
EXPOSE 655
EXPOSE 655/udp
