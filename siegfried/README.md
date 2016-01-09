# Make myself at home

## Set up my environment

    mkdir -p $HOME/src/jma
    cd $HOME/src/jma
    git clone https://github.com/JeffAbrahamson/dotfiles.git
    git clone https://github.com/JeffAbrahamson/hosts.git
    cd dotfiles
    ./install.sh

## Install needed software

    sudo apt-get install emacs python


# Disks

sudo mkdir /d1 /d2

The disk labels are fs-2TB-1  fs-2TB-2.

    $ ls /dev/disk/by-label/

The lsblk command can also be helpful in exploring attached block devices.

So add these lines to /etc/fstab:

LABEL=fs-2TB-1    /d1    ext4    errors=remount-ro    0    2
LABEL=fs-2TB-2    /d2    ext4    errors=remount-ro    0    3

# Accounts

Setup an account for Stéphane.  For password, cf. srd -> raspberry pi.

    sudo adduser stephane

Confirm proper ownerships.

    sudo chown -R jeff:jeff /d2/jeff
    sudo chown -R stephane:stephane /d1/stephane

Add my ssh keys.

    cd
    mkdir .ssh
    chmod 700 .ssh
    cd .ssh
    cat > authorized_keys
    # And paste my current keys, available in /d2/jeff/machines/*/.ssh/id_rsa.pub
    

# Apps

## Provide a data directory

    mkdir -p $HOME/data/hosts/$(hostname)

## Install speedtest

    cd $HOME/src
    git clone https://github.com/sivel/speedtest-cli.git
    cd speedtest
    cp speedtest_cli.py $HOME/bin
    # Test it
    $HOME/bin/speedtest_cli.py --simple

## Install crontab

    It should live in $DATA/hosts/$(hostname)

## Setup timemachine for Stéphane

    sudo apt-get install netatalk
    # Copy configuration from $HOME/src/jma/hosts/siegfried/
    #   /etc/netatalk/AppleVolumes.default (setup serving directory and turn on time machine support)
    #   /etc/default/netatalk (turn on CNID_MEATD_RUN and AFPD_RUN)
