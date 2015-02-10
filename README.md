cmi.bluebox
===========
DevOps'ed Blue Boxes (OpenWRT routers for various computer security uses)

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
