#!/bin/sh
#
# Run the test suite in a Docker container.

set -e

: ${BLUEBOXNOC_CODE_DIR:="$(cd "$(dirname "$0")/.."; pwd)"}
: ${BLUEBOXNOC_DOCKER_TESTS_NAME:="epflsti/blueboxnoc-tests"}

cd "${BLUEBOXNOC_CODE_DIR}"

docker build -t "${BLUEBOXNOC_DOCKER_TESTS_NAME}" devsupport/docker-tests

run_docker_test() {
  docker run -ti \
         -v "$BLUEBOXNOC_CODE_DIR":/opt/blueboxnoc \
         "${BLUEBOXNOC_DOCKER_TESTS_NAME}" "$@"
}

case "$1" in
    ""|test)
        echo >&2 "Should run the test suite now"
        exit 2 ;;
    shell)
        run_docker_test /bin/bash
        ;;
esac
