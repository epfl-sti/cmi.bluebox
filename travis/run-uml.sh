#!/bin/sh
# 
# Set up environment to run the tests under Docker on Travis
#
# Also useable as non-root to develop / debug the Travis support code
# (for which an Ubuntu host is required)

set -e -x

fail() {
    echo >&2 "$@"
    exit 1
}

[ -f ".travis.yml" ] || \
  fail "Please run this script from the top of the source tree."

. /etc/lsb-release
case "$DISTRIB_ID" in
    Ubuntu) : ;;
    *) fail "Sorry, the Travis tests require Ubuntu." ;;
esac

missing_packages=
for package_to_check in lxc-docker slirp cgroup-lite uml-utilities; do
    if ! dpkg -L $package_to_check >/dev/null; then missing_packages=1; fi
done
[ -n "$missing_packages" ] && fail \
  "Please install the missing packages (see instructions in .travis.yml)"

which linux >/dev/null || \
  fail "Please install User Mode Linux in your PATH" \
       "(see the instructions in .travis.yml)"

which humfsify >/dev/null || \
  fail "Please install humfsify."

# Prepare humfs mount points. This is pointless on Travis, but on the
# developer's workstation it speeds up subsequent "docker pull" commands
# when running UML several times.
for subdir in etc varlib; do
    humfsdir=var/uml-docker/$subdir
    [ -d "$humfsdir/data" ] && continue
    mkdir -p "$humfsdir/data"
    (cd "$humfsdir"; sudo humfsify $(whoami) $(whoami) 4G)
done

linux quiet mem=4G rootfstype=hostfs rw \
  eth0=slirp,,/usr/bin/slirp-fullbolt \
  init=$(pwd)/travis/run_all_tests_from_uml.sh WORKDIR=$(pwd) HOME=$HOME
# You can't really trust the exit code of a *kernel*:
test -f ./var/uml-docker/success
