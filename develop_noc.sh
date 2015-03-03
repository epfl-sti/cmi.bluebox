#!/bin/sh
#
# Developer support for the Blue Box NOC
#
# Not required for installation only; see install_noc.sh
#
# Runs a shell modded for development (e.g. updated PATH, environment
# variables to reach boot2docker on Mac OS X)
#
# Variables in BLUEBOXNOC_ALL_CAPS style below, as well as in all the
# scripts in the shlib subdirectoryb, may be overridden in the
# environment like so:
#
#   export BLUEBOXNOC_VAR_DIR=/var/snazzy/blueboxnoc
#   export BLUEBOXNOC_DEV_ONLY_INSTALL=1
#   ./develop_noc.sh

set -e -x

: ${BLUEBOXNOC_CODE_DIR:="$(cd "$(dirname "$0")"; pwd)"}
. "${BLUEBOXNOC_CODE_DIR}"/shlib/functions.sh

[ -n "$DEVELOP_NOC_SHELL" ] && fatal \
    "Already within a $(basename "$0") shell. Type 'exit' and try again."

if [ "$(os_name)" = "Darwin" ]; then
    # boot2docker requires some serious prepping
    [ $(boot2docker status) = "running" ] || boot2docker start
    [ -z "$DOCKER_HOST" ] && eval "`boot2docker shellinit`"
    DOCKER_IP="$(echo "$DOCKER_HOST" | perl -ne 'm|tcp://([0-9.]+)| && print $1')"
    DOCKER_NET="$(echo "$DOCKER_IP" | cut -d. -f1-3)"
    [ -n "$DOCKER_NET" ] || {
        fatal "Unable to parse DOCKER_NET." \
              "DOCKER_HOST=$DOCKER_HOST DOCKER_IP=$DOCKER_IP DOCKER_NET=$DOCKER_NET"
    }

    docker_reachable() {
        ping -c 1  -t 1 "$DOCKER_IP"
    }
    docker_reachable || {
        # https://stackoverflow.com/questions/26686358/docker-cant-connect-to-boot2docker-because-of-tcp-timeout
        for iface in $(ifconfig -l); do
            ifconfig $iface | grep "$DOCKER_NET" >/dev/null || continue
            DOCKER_VBOX_IFACE=$iface
            break
        done
        case "$DOCKER_VBOX_IFACE" in
            "")
                fatal "Cannot find interface pointing to network $DOCKER_VBOX_NET"
                ;;
            vboxnet*)
                : ;;
            *)
                fatal "Unlikely interface $DOCKER_VBOX_IFACE found for $DOCKER_VBOX_NET" \
                      "(should be vboxnetN)"
                ;;
        esac
        sudo route -nv add -net "$DOCKER_NET" -interface "$DOCKER_VBOX_IFACE"

        docker_reachable || {
            fatal "Still cannot ping $DOCKER_IP despite setting the route." \
                  "Hint: this may be caused by your VPN software. Stop it and "\
                  "try again."
        }
    }  # ! docker_reachable
fi  # Darwin

set +x

"$BLUEBOXNOC_CODE_DIR"/shlib/build.sh

if [ "$(os_name)" = "Darwin" ]; then
    bannermsg "Spawning a developer shell with Docker access." \
              "Try:      boot2docker ssh" \
              "          docker ps" \
              "          docker images" \
              "          build.sh" \
              "          start_stop.sh start shell" \
              "          test.sh"
else
    is_in_docker_group() {
        groups | grep docker >/dev/null
    }
    if is_in_docker_group; then
        sudo_needed=""
    else
        sudo_needed="sudo "
    fi

    bannermsg "Spawning a developer shell." \
              "Try:      ${sudo_needed}docker ps" \
              "          ${sudo_needed}docker images" \
              "          ${sudo_needed}build.sh" \
              "          start_stop.sh start shell" \
              "          ${sudo_needed}test.sh"

    is_in_docker_group || bannermsg \
       "Consider adding yourself to group docker, so that sudo is not needed."
fi

export PATH="$BLUEBOXNOC_CODE_DIR"/shlib:$PATH
DEVELOP_NOC_SHELL=1 $SHELL
