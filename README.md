cmi.bluebox
===========

DevOps'ed _Blue Boxes_: orchestrate OpenWRT routers for ad-hoc network
security tasks.

* Full-mesh VPNs between boxes with [tinc](http://www.tinc-vpn.org/)
* VNC access over the Web with [noVNC](https://kanaka.github.io/noVNC/)
* Multi-tenant administration UI ([node.js](http://nodejs.org/) + [ng-admin](https://github.com/marmelab/ng-admin))
* Plumbing with [Perl](http://www.perl.org/), Blue Box orchestration with ssh
* Packaged with [Docker](http://www.docker.com/)

![screenshot](doc/images/screenshot-dashboard.png?raw=true)

Installation
------------

You need a Linux machine with root access to install the NOC (Network
Operations Center) on.

```bash
sudo bash
cd /opt
git clone --recursive https://github.com/epfl-sti/cmi.bluebox.git
cd cmi.bluebox
./install_noc.sh
```

**Do not remove the git directory after installation** – All script
files in there will be used directly from the Docker container.

Development
-----------

Development is supported on Linux and Mac OS X.

```bash
git clone --recursive https://github.com/epfl-sti/cmi.bluebox.git
cd cmi.bluebox
./develop_noc.sh
```

Afterwards, follow the instructions given by `develop_noc.sh`.
