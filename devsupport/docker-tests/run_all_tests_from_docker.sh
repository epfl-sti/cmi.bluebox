#!/bin/bash
#
# Run the test suite.
#
# Ran from shlib/test.sh inside Docker

set -e

# Run the Perl test suite
mkdir /tmp/perltests
cd /tmp/perltests
perl /opt/blueboxnoc/plumbing/perllib/Build.PL
./Build test || {
    echo >&2 "Perl test suite failed."
    echo >&2 "You can inspect the results, then type \`exit'."
    bash
}

# TODO: Run the JavaScript test suite
