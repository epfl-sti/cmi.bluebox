#!/bin/bash
#
# This script is invoked by ../.travis.yml inside an UML (User-Mode Linux) box
# 
# To develop it, you need a Linux host whose config matches that of a
# Travis VM (i.e. Ubuntu, and with Docker and UML installed as per the
# script in .travis.yml). Then cd to the top of the source tree and
# run (again like Travis would)
#
#   mkdir -p var/uml-docker/data
#   (cd var/uml-docker/data; sudo humfsify root root 4G)
#   linux quiet mem=4G rootfstype=hostfs rw \
#     eth0=slirp,,/usr/bin/slirp-fullbolt \
#     init=$(pwd)/travis/uml.sh WORKDIR=$(pwd) HOME=$HOME

# Exit on first error
set -e -x

save_and_shutdown() {
  # save built for host result
  # force clean shutdown
  halt -f
}

# make sure we shut down cleanly
trap save_and_shutdown EXIT SIGINT SIGTERM

# go back to where we were invoked
cd $WORKDIR

# configure path to include /usr/local
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# can't do much without proc!
mount -t proc none /proc

# pseudo-terminal devices
mkdir -p /dev/pts
mount -t devpts none /dev/pts

# shared memory a good idea
mkdir -p /dev/shm
mount -t tmpfs none /dev/shm

# sysfs a good idea
mount -t sysfs none /sys

# pidfiles and such like
mkdir -p /var/run
mount -t tmpfs none /var/run

# takes the pain out of cgroups
cgroups-mount

# Overlay-mount Docker directories somewhere in the host
# This makes no difference on Travis, but speeds up rebuilds
# in dev mode
mkdir -p var/uml-docker/etc var/uml-docker/varlib
mount -o bind $PWD/var/uml-docker/etc /etc/docker
mount -o bind $PWD/var/uml-docker/varlib /var/lib/docker

# enable ipv4 forwarding for docker
echo 1 > /proc/sys/net/ipv4/ip_forward

# configure networking
ip addr add 127.0.0.1 dev lo
ip link set lo up
ip addr add 10.1.1.1/24 dev eth0
ip link set eth0 up
ip route add default via 10.1.1.254

# configure dns (google public)
mkdir -p /run/resolvconf
echo 'nameserver 8.8.8.8' > /run/resolvconf/resolv.conf
mount --bind /run/resolvconf/resolv.conf /etc/resolv.conf

# Start docker daemon
bash -i  # XXX

docker -d &
sleep 5

# Use docker
: ${BLUEBOXNOC_CODE_DIR:="$(cd "$(dirname "$0")/.."; pwd)"}
: ${BLUEBOXNOC_DOCKER_TESTS_NAME:="epflsti/blueboxnoc-tests"}

docker pull "${BLUEBOXNOC_DOCKER_TESTS_NAME}"

docker run -v "$BLUEBOXNOC_CODE_DIR":/opt/blueboxnoc \
         "${BLUEBOXNOC_DOCKER_TESTS_NAME}" "/opt/blueboxnoc/devsupport/docker-tests/run_all_tests_from_docker.sh"

touch "$WORKDIR"/success
