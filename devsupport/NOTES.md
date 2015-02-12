Random development notes that might be useful to colleagues / contributors

2015-02-09 - Blue Box personalization use case
================================================

To be transcribed into ../README.md at some point. DRAFT STATE - There may be a way to suppress step 

1. The VPN operator procures a Blue Box and installs a standard OpenWRT image onto it.
2. The VPN operator configures network access on the Blue box
3. The VPN operator access the NOC and logs into the Web UI
4. Using the Web UI, the VPN operator creates a new Blue Box and is prompted the following information:
   * hostname of the Blue Box (must be unique)
   * VPN to insert the Blue Box into
5. The NOC prepares a .tgz file ready for uploading through the Blue Box's "backup/restore" Web UI. The .tgz contains either files (e.g. `/etc/dropbear/authorized_keys`), or scripts (e.g. `/etc/rc.local`, `/etc/hotplug.d/iface/br-wan`) that together will effect the following configuration changes inside the target Blue Box:
   * the hostname is set as per the information requested at step 4
   * The VPN's public SSH key will become authorized to access as root
   * Access to SSH with a password will be disabled (only the aforementioned public key can access)
   * The firewall configuration will be updated to allow access to port 22 (SSH) through the Blue Box's WAN interface
   * Upon every successful configuration of the Blue Box's WAN interface, and periodically thereafter unless the Tinc VPN is up (at step 11 below), the Blue Box will send an unauthenticated HTTP request to the NOC containing its WAN-side IPv4 address, VPN name, and a cryptographic token identifying the tar.gz that was built
6. The VPN operator downloads the .tgz file of Step 5 and uploads it through the Blue Box's Web restore interface. There are two modes of operation for this: either download to administrator's browser / upload from same, or by cutting/pasting a companion shell one-liner into the /etc/rc.local script (http://192.168.1.1/cgi-bin/luci/admin/system/startup , bottom of the page) and rebooting.
   * To prevent replay attacks, either of these downloads is only feasible once, and the URL contains a token that only the administrator can get access to. If the step fails, the tar.gz needs to be recreated.
7. The Blue Box reboots and applies the requested changes. Because a restore performed from an incomplete .tgz "backup" (crafted as per point 5) only overlays the files in the .tgz and doesn't wipe out the rest of the configuration, the rest of the Blue Box's pre-existing configuration (in particular, its network parameters) stay unchanged.
8. The Blue Box starts accessing the NOC over the aforementioned unauthenticated HTTP request.
9. The NOC responds to these HTTP pings by ssh'ing into the Blue Box automatically, and performing the following changes:
   * a keypair is generated for tinc, unless already present
   * the tinc configuration (in particular, the public key exchange) is carried out and tinc is set up to start automatically at boot, and is started at once
   * the vpn0 interface (the one that tinc creates) is bridged into br-lan
10. The Blue Box reboots to apply the changes and joins the tinc VPN.
11. Upon successfully joining the VPN for the first time, the Blue Box fences the HTTP pings (condition on whether the VPN is up in the ping script). It resumes pinging if the connectivity drops.
12. The NOC figures out from the tincd logs that the Blue Box joined the VPN successfully, and thereafter periodically ssh's into the Blue Box (over its WAN-side IP address) to sync new changes (e.g. set of tinc public keys) and collect statistics.

The administrator is also able to trigger steps 9 and 12 manually, by entering the WAN-side IP address of an existing but yet unconfigured / unresponding Blue Box.

From the point of view of the NOC, the Blue Boxes' state diagram is as follows:

* *INIT* : the NOC UI has been told to enroll a new Blue Box, and a handful of security-irrelevant info (pseudo-DNS name) but cannot securely communicate with the Blue Box. A .tar.gz has been made ready for download, under an URL that contains a secret token.
  * Transition to *DOWNLOADED*: the administrator downloads the .tar.gz
  * Transition to *DOWNLOADED*: the administrator has the Blue Box download the .tar.gz.
* *DOWNLOADED*: the .tar.gz has started download at least once, and is no longer accessible (e.g. deleted from the file system). The NOC still doesn't know any cryptographically secure information about the Blue Box.
  * Transition to *INIT*: using the web UI, the administrator regenerates the .tar.gz with a fresh HTTP-ping token inside; the new .tar.gz is available under a different URL that contains a distinct, also fresh token.
  * Transition to *NEEDS_UPDATE*: the NOC receives news of the HTTP ping / is directed by the administrator to attempt an enrollment, and successfully completes an SSH handshake (far enough to update the .ssh/known_hosts).
* *NEEDS_UPDATE*: the NOC knows about the SSH identity of the Blue Box, but knows for a fact that its configuration needs updating (e.g.: never synced successfully, set of public keys to accept has changed etc). It may or may not know the Blue Box's tinc public key.
  * Transition to *ACTIVE*: the NOC completes a sync to the Blue Box.
  * Transition to *FAILING*: the Blue Box stayed in NEEDS_UPDATE state for too long (say, more than a day)
  * Transition to *FAILING*: the NOC-initiated sync fails (ssh session proceeds to completion, but remote command fails)
* *ACTIVE*: the NOC has successfully pushed the tinc keys, configuration etc. into the Blue Box, and obtained the Blue Box's tinc key in return.
  * Additional information, impacting the "hue" of the state (possibly literally in the UI): time since last successful communication as seen in tinc logs
  * Transition to *NEEDS_UPDATE*: a new Blue Box in the same VPN has transitioned from DOWNLOADED to NEEDS_UPDATE
  * Transition to *NEEDS_UPDATE*: a Blue Box has been deleted from the VPN
  * Transition to *NEEDS_UPDATE*: en masse upon backward-compatible software update on the NOC
  * Transition to *FAILING*: a routine sync fails (ssh session proceeds to completion, but remote command fails)
  * Transition to *FAILING*: the time since last successful communication in the tinc logs is too old (more than a few hours)
  * Transition to *FAILING*: en masse upon backward-incompatible software update on the NOC
* *FAILING*: correct operation of the Blue Box is no longer guaranteed (regardless of whether it shows up successfully in the tinc logs)
  * Transition to *NEEDS_UPDATE*: by operator intervention in the Web UI (meaning they attempted to correct the problem by some out-of-band means)

Additionally, the Blue Box can be deleted from any state.

There are exactly two NOC-side operations that take a long time and
are prone to failure: to prepare a .tar.gz, and to sync a Blue Box.
When these operations are initiated from the Web UI, progress will be
shown in "console" style (whence the administrator can see the output
of a shell command running on the NOC, piped through their browser in
real time).

2015-02-08 - Installing Tinc on Mac OS X Yosemite
=====================================================

With the Yosemite release, Apple appears to have [changed its policy](https://github.com/Homebrew/homebrew/issues/31164) regarding signing kernel extensions (kexts). The following is now required to get TUN/TAP working (which is in turn necessary to run tinc on your Mac laptop for tests):

1. Install [Homebrew](http://brew.sh/) if not already done
2. ``sudo chown -R `whoami` /usr/local /Library/Caches/Homebrew`` – Just in case you [mistakenly](https://apple.stackexchange.com/questions/150271/how-to-repair-homebrew-permissions-after-installing-as-root) `brew install`'d something as root at some point...
3. <pre>
    brew update
    brew unlink brew-cask
    brew install Caskroom/cask/tuntap
    </pre>
4. `kextstat | grep tuntaposx`

2015-02-08 - Desired tinc configuration
===========================================

```
root@cmibb2:~# cat /etc/tinc/CMi_Lausanne_Centrotherm/tinc.conf
name = cmibb2
mode = switch
ConnectTo = cmigevm1
interface = vpn0
```

```
quatrava@cmigevm1:~$ sudo /etc/init.d/tinc start
Starting tinc daemons: CMi_Lausanne_Centrotherm.
quatrava@cmigevm1:~$ cat /etc/tinc/CMi_Lausanne_Centrotherm/tinc.conf 
Name = cmigevm1
Mode = switch
```

```
quatrava@cmigevm1:~$ cat /etc/tinc/CMi_Lausanne_Centrotherm/hosts/cmigevm1 
Address = cmigevm1.epfl.ch


-----BEGIN RSA PUBLIC KEY-----
...
```

```
quatrava@cmigevm1:~$ sudo cat /etc/tinc/CMi_Lausanne_Centrotherm/hosts/cmibb2 

-----BEGIN RSA PUBLIC KEY-----
...
```

Note: The contents of `/etc/tinc/CMi_Lausanne_Centrotherm/hosts` is the same on all members of the tinc mesh.
