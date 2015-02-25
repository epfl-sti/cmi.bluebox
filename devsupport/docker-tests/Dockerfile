# Run the Blue Box NOC's tests in a Docker image
#
# The tests are run as part of the develop_noc.sh script, and can be
# re-run with .
#
# To test out your changes:
#   1. Install Docker as per the instructions at
#      https://docs.docker.com/installation/, or just run the
#      develop_noc.sh script and follow the instructions
#   2. cd to the top-level of the source tree
#   3. ./develop_noc.sh
#   4. test.sh shell

FROM epflsti/blueboxnoc
MAINTAINER Dominique Quatravaux <dominique.quatravaux@epfl.ch>

RUN cpanm Test::Group
