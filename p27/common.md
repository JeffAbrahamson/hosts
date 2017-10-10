# Common tasks for all p27.eu hosts.

## Start

Set up a user for myself and other basic setup.

    # With DigitalOcean, I start out with only root.  So create
    # myself, then logout and log back in as me.  For password,
    # cf. srd nantes.p27.eu
    adduser jeff
    addgroup jeff sudo

    # For the rest of this, I will assume I am me and so need to sudo.
    su - jeff

    sudo apt-get -y update
    sudo apt-get -y upgrade
    sudo apt-get -y install git emacs-nox letsencrypt ufw

    # Set my timezone.  For a production server I would normally set
    # to UTC.  But here I think I'd like to see mail headers in my
    # home timezone.  So I set to Europe/Paris.
    sudo dpkg-reconfigure tzdata

    # I want en_GB.utf8 and fr_FR.utf8 added to the host.
    sudo dpkg-reconfigure locales

    mkdir /home/jeff/.ssh
    chmod 700 $HOME/.ssh

    mkdir -p src/jma
    cd src/jma
    git clone https://github.com/JeffAbrahamson/dotfiles.git
    (cd dotfiles && ./install.sh)
    git clone https://github.com/JeffAbrahamson/hosts.git
    cd hosts/p27
    # In the rest of this, I will assume that cwd=hosts/p27.


## firewall

The dotfile install installed a rudimentary firewall.  As of the time
I'm writing this, I think that should be at least the below, but in
fact it will be more than what dotfiles creates.  Cf. the individual
host readme's in this directory.

    sudo ufw default allow outgoing
    sudo ufw default deny incoming
    sudo ufw allow ssh/tcp
    sudo ufw limit ssh
    sudo ufw enable
    sudo ufw status verbose

## ssh

Make sure sshd is secure.

    # On my workstation.
    rsync .ssh/id_rsa.pub www.p27.eu:.ssh/authorized_keys
    # I'll also want to append the public key from any other hosts I use.

    # Probably I want my sshd_config, but double-check that the
    # distribution isn't offering anything new.
    #
    # Don't do this on vagrant where I needn't set up ssh certificates.
    diff sshd/sshd_config /etc/ssh/sshd_config
    sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.orig
    sudo cp sshd/sshd_config /etc/ssh/sshd_config
    sudo service sshd restart
    ## And now from another window confirm that ssh access still works. ####

    sudo apt-get install -y fail2ban

