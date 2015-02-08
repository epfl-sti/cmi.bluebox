Random development notes that might be useful to colleagues / contributors

<2015-02-08 Sun> Installing Tinc on Mac OS X Yosemite
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


