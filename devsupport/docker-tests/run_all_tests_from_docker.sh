#!/bin/bash
#
# Run the test suite.
#
# Ran from shlib/test.sh inside Docker

usage() {
    echo >&2 "Usage: $(basename $0) [--noperl] [--nonode] [--debug]"
    echo >&2 "     --debug: drop to a shell in case of test failure."
}

debug_mode=
noperl=
nonode=

while [ -n "$1" ]; do case "$1" in
    --help) usage; exit 0 ;;
    --debug) debug_mode=1; shift ;;
    --noperl) noperl=1; shift ;;
    --nonode) nonode=1; shift ;;
    *)
        echo >&2 "Unknown argument $1"
        exit 2 ;;
esac; done



fail() {
    local exitcode_orig=$?
    if [ -z "$debug_mode" ]; then
        echo >&2 "$1."
    else
        echo >&2 "$1 - Inspect and type exit to proceed"
        bash
    fi
    exit $exitcode_orig
}

run_perl_tests() {
    mkdir /tmp/perltests
    cd /tmp/perltests
    perl /opt/blueboxnoc/plumbing/perllib/Build.PL
    ./Build test || fail "Perl tests failed"
}

run_node_tests() {
    Xvfb :0 > /tmp/Xvfb.log 2>&1 &
    export DISPLAY=:0
    while ! xlsclients; do sleep 1; done
    x11vnc >/tmp/x11vnc.log 2>&1 &
    cd /opt/blueboxnoc/blueboxnoc-ui
    mocha --recursive tests/ || fail 'node tests failed'
}

set -e -x
[ -z "$noperl" ] && run_perl_tests
[ -z "$nonode" ] && run_node_tests
exit 0
