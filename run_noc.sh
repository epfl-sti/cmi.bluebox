#!/bin/sh

# Start or stop the Docker image for blueboxnoc
#
# Can be used / installed as a SysV startup script (and install_noc.sh
# installs it in this way), or directly from the source code checkout
# (need to either be in the docker group, or use sudo).

: ${BLUEBOXNOC_DOCKER_NAME:="epflsti/blueboxnoc"}
: ${BLUEBOXNOC_VAR_DIR:="/srv/blueboxnoc"}
: ${BLUEBOXNOC_CODE_DIR:="$(cd $(dirname "$0"); pwd)"}


start() {
    test 0 '!=' $(docker ps -q "$BLUEBOXNOC_DOCKER_NAME" | wc -l) && return
    docker run --net=host --device=/dev/net/tun -d \
           -v "$BLUEBOXNOC_VAR_DIR":/srv \
           -v "$BLUEBOXNOC_CODE_DIR":/opt/blueboxnoc \
           "$BLUEBOXNOC_DOCKER_NAME" \
           node /opt/blueboxnoc/blueboxnoc-ui/helloworld.js # XXX Must start tinc too
    # Profit!!
}

stop() {
    docker ps -q "$BLUEBOXNOC_DOCKER_NAME" | \
      xargs --no-run-if-empty docker kill
}

is_running() {
    test 0 != $(docker ps -q "$BLUEBOXNOC_DOCKER_NAME" | wc -l)
}

while [ -n "$1" ]; do
    case "$1" in
        status)
            docker ps "$BLUEBOXNOC_DOCKER_NAME" ;;
        start)
            start ;;
        stop)
            stop ;;
        shell)
            is_running || {
            echo >&2 "$BLUEBOXNOC_DOCKER_NAME" is not running
            exit 2
        }
            docker exec -it $(docker ps -q "$BLUEBOXNOC_DOCKER_NAME") bash ;;
        restart)
            stop
            start ;;
    esac
    shift
done
