#!/bin/bash
#
# Download and install prerequisites for the Blue Box NOC
#
# Supported platforms: Linux (production or development) and Mac OS X
# (development only)

cd "$(dirname "$0")/.."
. shlib/functions.sh

set -e -x

case "$(os_name)" in
    Darwin)
        ensure_docker 1.3.0 ;;
    *)
        ensure_docker 1.4.0 ;;
esac
