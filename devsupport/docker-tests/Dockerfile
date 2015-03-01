# Run the Blue Box NOC's tests in a Docker image
#
# Run the test.sh script to rebuild the Docker image and re-run the tests.
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

########################################################################
# General-purpose stuff
RUN apt-get -y install \
  # Handy for debugging failing tests:
  strace \
  # Needed below
  unzip

########################################################################
# Dependencies of the Perl tests
RUN cpanm Test::Group

########################################################################
# Dependencies of the node.js tests
RUN npm install -g mocha

# Latest chrome - Procedure inspired from
# https://registry.hub.docker.com/u/robcherry/docker-selenium/dockerfile/
RUN curl -sL https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
RUN echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list
RUN apt-get -y update
RUN apt-get -y install google-chrome-stable
# Disable the SUID sandbox so that Chrome can launch without being in a privileged container.
RUN echo "#!/bin/bash\nexec /opt/google/chrome/google-chrome --disable-setuid-sandbox \"\$@\"" > /usr/local/bin/google-chrome
RUN chmod 755 /usr/local/bin/google-chrome

# fake X11 support (x11vnc is available to debug failing tests)
RUN apt-get -y install xvfb x11vnc

# Chromedriver
RUN curl -sL https://chromedriver.storage.googleapis.com/`curl -sL https://chromedriver.storage.googleapis.com/LATEST_RELEASE`/chromedriver_linux64.zip > /tmp/chromedriver_linux64.zip
RUN cd /usr/local/bin; unzip /tmp/chromedriver_linux64.zip
RUN chmod 755 /usr/local/bin/chromedriver

########################################################################
EXPOSE 5900

