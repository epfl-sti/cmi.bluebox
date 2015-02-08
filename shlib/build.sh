#!/bin/bash
#
# Build the Docker image for the Blue Box NOC

set -e -x

cd "$(dirname "$0")/.."
. shlib/functions.sh

bash shlib/prereqs.sh

: ${BLUEBOXNOC_DOCKER_NAME:=epflsti/blueboxnoc}
docker build -t "$BLUEBOXNOC_DOCKER_NAME":latest .
