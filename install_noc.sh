#!/bin/bash
#
# Blue Box NOC build + install script
#
# To install for production, run the script as root on a Linux box.
#
# Variables in BLUEBOXNOC_ALL_CAPS style below, as well as in all the
# scripts in the shlib subdirectoryb, may be overridden in the
# environment like so:
#
#   export BLUEBOXNOC_VAR_DIR=/var/snazzy/blueboxnoc
#   export BLUEBOXNOC_DEV_ONLY_INSTALL=1
#   sudo install_noc.sh

set -e -x

cd "$(dirname "$0")"
. shlib/functions.sh

# After install, the git directory will still be used.
: ${BLUEBOXNOC_CODE_DIR:="$PWD"}
: ${BLUEBOXNOC_VAR_DIR:=/srv/blueboxnoc}

[ "$(os_name)" = "Darwin" ] && \
  fatal "Mac OS X platform supported for development only, cannot install."

ensure_running_as_root
bash "$BLUEBOXNOC_CODE_DIR"/shlib/build.sh
substitute_shell BLUEBOXNOC_ < shlib/start_stop.sh > /etc/init.d/blueboxnoc
chmod a+x /etc/init.d/blueboxnoc

# TODO: chkconfig / update-rc.d here

set +x

bannermsg "Installation successful. " \
          "Service may be started with /etc/init.d/blueboxnoc restart"
