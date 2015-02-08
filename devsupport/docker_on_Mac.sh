#!/bin/sh

# Run the Docker container on a Mac.
# Usage: path/to/checkout/devsupport/docker_on_Mac.sh

set -e -x

: ${BLUEBOXNOC_CODE_DIR:="$(cd "$(dirname "$0")"/..; pwd)"}
. "${BLUEBOXNOC_CODE_DIR}"/shlib/functions.sh

[ -n "$RUNNING_DOCKER_ON_MAC" ] && fatal \
    "Already within a $(basename "$0") shell. Type 'exit' and try again."

which boot2docker || {
    which brew || fatal "Please install Homebrew from http://brew.sh/" \
                        "and run the script again."
    brew install boot2docker
}
which boot2docker || fatal "Unable to install boot2docker automatically." \
                           "Please install manually and run the script again."

# What follows is a transcription of the instructions at the end of
# brew install boot2docker
test -f ~/Library/LaunchAgents/*.boot2docker.plist || {
    ln -sfv /usr/local/opt/boot2docker/*.plist ~/Library/LaunchAgents
}
launchctl load ~/Library/LaunchAgents/*.boot2docker.plist 2>/dev/null

ensure_docker 1.3.0

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
}

${BLUEBOXNOC_CODE_DIR}/install_noc.sh   # Darwin implies dev-only install

case "$PWD" in
    "$BLUEBOXNOC_CODE_DIR") runnocsh="./run_noc.sh" ;;
    "$BLUEBOXNOC_CODE_DIR/devsupport") runnocsh="../run_noc.sh" ;;
    *) runnocsh="{$BLUEBOXNOC_CODE_DIR}"/run_noc.sh ;;
esac

set +x

bannermsg "Spawning a shell with Docker access." \
          "Try:      boot2docker ssh" \
          "          docker ps" \
          "          docker images" \
          "          $runnocsh start shell"

bannermsg "Note: the main Web interface will be accessible at http://$DOCKER_IP/"

RUNNING_DOCKER_ON_MAC=1 bash || true
