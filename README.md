cmi.bluebox
===========

DevOps'ed _Blue Boxes_: OpenWRT routers used at EPFL for various network
security purposes.

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
