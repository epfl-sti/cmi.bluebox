Random development notes that might be useful to colleagues / contributors

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
