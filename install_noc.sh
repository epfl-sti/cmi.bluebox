#!/bin/bash
#
# Blue Box NOC installation script
#
# Run this as root from a fresh git checkout to install the Blue Box NOC.
#
# Variables in BLUEBOXNOC_ALL_CAPS style below may be overridden in
# the environment, e.g.
#
#   export BLUEBOXNOC_VAR_DIR=/var/snazzy/blueboxnoc
#   export BLUEBOXNOC_DEV_ONLY_INSTALL=1
#   sudo install_noc.sh

set -e -x

cd "$(dirname "$0")"
. shlib/functions.sh

: ${BLUEBOXNOC_CODE_DIR:="$PWD"}

: ${BLUEBOXNOC_DEV_ONLY_INSTALL:=""}
if running_on_mac && [ -z "$BLUEBOXNOC_DEV_ONLY_INSTALL" ]; then
    (set +x; bannermsg "Performing Mac OS X developer-only install")
    BLUEBOXNOC_DEV_ONLY_INSTALL=1
fi

if [ -n "$BLUEBOXNOC_DEV_ONLY_INSTALL" ]; then
    : ${BLUEBOXNOC_VAR_DIR:="$BLUEBOXNOC_CODE_DIR/var"}
    (set +x
     bannermsg "Performing dev install with app data in ${BLUEBOXNOC_VAR_DIR}")
else
    ensure_running_as_root
    ensure_docker 1.4.0
    : ${BLUEBOXNOC_VAR_DIR:="/srv/blueboxnoc"}
    (set +x
     bannermsg "Performing prod install with app data in ${BLUEBOXNOC_VAR_DIR}")
fi

# Create the data directory
mkdir -p "${BLUEBOXNOC_VAR_DIR}"
# Build the Docker image
: ${BLUEBOXNOC_DOCKER_NAME:=epflsti/blueboxnoc}
docker build -t "$BLUEBOXNOC_DOCKER_NAME":latest .

if [ -z "$BLUEBOXNOC_DEV_ONLY_INSTALL" ]; then
    substitute_shell BLUEBOXNOC_ < run_noc.sh > /etc/init.d/blueboxnoc
    chmod a+x /etc/init.d/blueboxnoc
fi

(set +x; bannermsg "All done, now see run_noc.sh")
