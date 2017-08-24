# Setup for p27.eu

This assumes the domain exists and that I've set up DNS and reverse
correctly to point to it.


## DNS

In pseudo-code:

    ip=1.2.3.4        # Where my server is.
	www    A       $ip
	data   CNAME   www
	smtp   MX      www
	@      MX      www
	


## Start

    sudo apt-get -y update
	sudo apt-get -y upgrade
	sudo apt-get -y install git emacs-nox letsencrypt ufw
	
	# With DigitalOcean, I start out with only root.  So create
	# myself, then logout and log back in as me.  For password,
	# cf. srd nantes.p27.eu
	adduser jeff
	addgroup jeff sudo
	
	sudo su - jeff

	mkdir /home/jeff/.ssh
	chmod 700 $HOME/.ssh

	mkdir -p src/jma
	cd src/jma
	git clone https://github.com/JeffAbrahamson/dotfiles.git
	(cd dotfiles && ./install.sh)
	git clone https://github.com/JeffAbrahamson/hosts.git
	cd hosts/p27
	# In the rest of this, I will assume that cwd=hosts/p27.
	
	sudo dpkg-reconfigure locales
	# I want en_GB.utf8 and fr_FR.utf8 added to the host.

## firewall

The dotfile install installed a rudimentary firewall.  As of the time
I'm writing this, I think that should be this:

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

## nginx

Install nginx:

    sudo apt-get install -y nginx-full nginx-doc
	sudo cp nginx/sites-available/* /etc/nginx/sites-available/

	(cd /etc/nginx/sites-enabled && sudo rm default)
    (cd /etc/nginx/sites-enabled && sudo ln -s ../sites-available/01-www)
    (cd /etc/nginx/sites-enabled && sudo ln -s ../sites-available/05-isoldpurple)
	
	sudo ufw allow http/tcp
	sudo ufw allow https/tcp
	sudo service nginx reload

We want to serve https only.  The nginx site configs will promote http
to https.

    sudo apt-get install -y letsencrypt
	sudo add-apt-repository ppa:certbot/certbot
	sudo apt-get -y update
	sudo apt-get -y install python-certbot-nginx

    # In the following, I might need to manually edit files on the
    # server to remove the reference to the certs that don't exist
    # yet.
	sudo certbot --nginx -d p27.eu -d www.p27.eu
	# When asked, enter my email address.
	# Certbot config is saved in /etc/letsencrypt/
	sudo certbot --nginx -d isoldpurple.com -d www.isoldpurple.com

	# And keep the certificates updated by putting this in root
    # crontab (the time is arbitrary):
	17 5 * * *   /usr/bin/certbot renew --quiet

	# Populate my web sites.
	(cd ~/src/jma && git clone https://github.com/JeffAbrahamson/p27-www.git)
	sudo mkdir /var/www/p27
	sudo cp -r ~/src/jma/p27-www/site/ /var/www/p27/
	(cd ~/src/jma && git clone https://github.com/JeffAbrahamson/isoldpurple-www.git)
	sudo mkdir /var/www/isoldpurple
	sudo cp -r ~/src/jma/isoldpurple-www/site/ /var/www/isoldpurple/


## mail

### postfix and dovecot

The ubuntu package mail-stack-delivery installs postfix and dovecot
and configures them to talk to each other.

    sudo apt-get install -y ntp mail-stack-delivery

Answers to questions:
* internet site
* the system name is p27.eu (no trailing period).

Let's set up an SSL certificate for postfix:

    sudo letsencrypt certonly --standalone -d smtp.p27.eu

Question answers:
* email address: jeff@p27.eu
* TOS: agree

	sudo postconf -e 'smtpd_sasl_type = dovecot'
	sudo postconf -e 'smtpd_sasl_path = private/auth'
	sudo postconf -e 'smtpd_sasl_local_domain ='
	sudo postconf -e 'smtpd_sasl_security_options = noanonymous'
	sudo postconf -e 'broken_sasl_auth_clients = yes'
	sudo postconf -e 'smtpd_sasl_auth_enable = yes'
	sudo postconf -e 'smtpd_recipient_restrictions = permit_sasl_authenticated,permit_mynetworks,reject_unauth_destination'

    # Use TLS for both incoming and outgoing mail.
	sudo postconf -e 'smtp_tls_security_level = may'
	sudo postconf -e 'smtpd_tls_security_level = may'
	sudo postconf -e 'smtp_tls_note_starttls_offer = yes'
	sudo postconf -e 'smtpd_tls_loglevel = 1'
	sudo postconf -e 'smtpd_tls_received_header = yes'

	# Enable virtual alias mapping.
	sudo postconf -e 'virtual_alias_domains = $mydomain'
	sudo postconf -e 'virtual_alias_maps = hash:/etc/postfix/virtual'

And, finally, set up email aliases to map to users.

    sudo emacs /etc/postfix/virtual

cf. srd p27-postfix-aliases

Tell postfix to update its database:

    sudo postmap /etc/postfix/virtual
	sudo service postfix restart


### anti-spam


### anti-virus


### server-side filtering


### DKIM


### SPF records



## postgresql

## influxdb

## grafana

## letsencrypt


