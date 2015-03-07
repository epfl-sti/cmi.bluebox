os_name() {
    if test "$(uname -s)" = "Darwin"; then
        echo Darwin
        return
    elif [ -f "/etc/redhat-release" ]; then
        case "$(cat /etc/redhat-release)" in
            CentOS*) echo "CentOS" ;;
            *Enterprise*) echo "RedHat" ;;
        esac
        return
    elif grep -q DISTRIB_ID "/etc/lsb-release"; then
        . "/etc/lsb-release"
        echo "$DISTRIB_ID"
        return
    fi
    echo "Unknown"
}

bannermsg() {
    echo >&2
    for msg in "$@" ; do echo "$msg" >&2; done
    echo >&2
}

fatal() {
    set +x
    bannermsg "$@"
    exit 2
}

running_as_root() {
    test "$(id -u)" = 0
}

ensure_running_as_root() {
    running_as_root || fatal "Please re-run $0 as root."
}

check_docker() {
    local minversion=$1
    [ -z "$minversion" ] && minversion=1.4.0
    perl -w -Mstrict -Mversion \
         -e 'my $dockerversionstring = `docker --version`;' \
         -e 'my ($dockerversion) = $dockerversionstring =~
                       m/Docker version (\S+?)(,|\s)/i;' \
         -e 'if (! $dockerversion) { exit 2 };' \
         -e 'my $minversion = "'"$minversion"'";' \
         -e 'if (version->parse($dockerversion) <
                 version->parse($minversion)) {
               die "Docker version is $dockerversion, $minversion or higher required\n";
             }'
}

ensure_docker() {
    local minversion=$1
    check_docker "$minversion" && return
    
    case "$(os_name)" in
        Darwin)
            which boot2docker || {
                which brew || fatal "Please install Homebrew from http://brew.sh/" \
                                    "and run the script again."
                brew install boot2docker
            }
            which boot2docker || fatal "Unable to install boot2docker automatically." \
                                       "Please install manually and run the script again."

            # What follows is a transcription of the instructions at the end of
            # brew install boot2docker
            test -f ~/Library/LaunchAgents/*.boot2docker.plist || {
                ln -sfv /usr/local/opt/boot2docker/*.plist ~/Library/LaunchAgents
            }
            launchctl load ~/Library/LaunchAgents/*.boot2docker.plist 2>/dev/null
            ;;
        Ubuntu)
            ensure_running_as_root
            # https://docs.docker.com/installation/ubuntulinux/
            [ -e /usr/lib/apt/methods/https ] || {
                apt-get update
                apt-get install apt-transport-https
            }
            apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 \
                    --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9
            echo "deb https://get.docker.com/ubuntu docker main" \
                 > /etc/apt/sources.list.d/docker.list
            apt-get update
            apt-get install lxc-docker
            ;;
        RedHat|CentOS)
            ensure_running_as_root
            yum -y install docker-io
            ;;
    esac
    check_docker "$minversion"  || fatal "Unable to install Docker." \
        "Please install Docker $minversion or higher, and run the script again."
}

confirm_yesno() {
    local question="$1"
    if which dialog >/dev/null 2>&1; then
        dialog --yesno "$question" 12 60
    else
        echo "$question [Yn]"
        read answer
        case "$answer" in
            n*|N*) return 1;;
            *) return 0;;
        esac
    fi
}

has_puppet() {
    which puppet >/dev/null 2>&1
}

# Whether puppet agent is configured.
has_puppet_agent() {
    grep -q "\[agent\]" $(puppet config print config 2>/dev/null)
}

# Substitute default variables in shell script with the values currently
# in force
# Usage: substitute_shell VARPREFIX_ < filename
substitute_shell() {
    set | grep "^$1" > /tmp/substvars
    perl -Mstrict -MText::ParseWords \
         -wpe 'our %substs;
              BEGIN {
                 open(SUBSTVARS, "</tmp/substvars");
                 while(<SUBSTVARS>) {
                    chomp;
                    my ($var, $qval) = m/^(.*?)=(.*)$/ or next;
                    my ($val) = Text::ParseWords::shellwords($qval);
                    $substs{$var} = $val;
                 }
              }
              foreach my $subst (keys %substs) {
                s|^: \$\{$subst:=.*\}|sprintf(q/: ${%s:="%s"}/, $subst, $substs{$subst})|e;
              }'
}
