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
	sudo cp nginx/nginx.conf /etc/nginx/nginx.conf
	sudo cp nginx/sites-available/* /etc/nginx/sites-available/

	(cd /etc/nginx/sites-enabled && sudo rm default)
    (cd /etc/nginx/sites-enabled && sudo ln -s ../sites-available/01-www)
    (cd /etc/nginx/sites-enabled && sudo ln -s ../sites-available/05-isoldpurple)

	sudo ufw allow http/tcp
	sudo ufw allow https/tcp

We want to serve https only.  The nginx site configs will promote http
to https.

    sudo apt-get install -y letsencrypt
	sudo add-apt-repository ppa:certbot/certbot
	sudo apt-get -y update
	sudo apt-get -y install python-certbot-nginx

    # In the following, I might need to manually edit files on the
    # server to remove the reference to the certs that don't exist
    # yet.
	sudo certbot --agree-tos -m jeff@p27.eu --nginx -d p27.eu -d www.p27.eu
	# When asked, enter my email address.
	# Certbot config is saved in /etc/letsencrypt/
	sudo certbot --agree-tos -m jeff@p27.eu --nginx -d isoldpurple.com -d www.isoldpurple.com

	# And keep the certificates updated by putting this in root
    # crontab (the time is arbitrary).  Note, however, that the full
	# root crontab can just be pulled from crontab/root.
	17 5 * * *   /usr/bin/certbot renew --quiet

	# Don't allow weak Diffie-Hellman keys.
	openssl dhparam -out dhparams.pem 2048 && sudo mv dhparams /etc/ssl/certs/
	sudo service nginx reload

	# Populate my web sites.
	(cd ~/src/jma && git clone https://github.com/JeffAbrahamson/p27.git)
	sudo mkdir /var/www/p27
	sudo cp -r ~/src/jma/p27/site/ /var/www/p27/
	(cd ~/src/jma && git clone https://github.com/JeffAbrahamson/isoldpurple.git)
	sudo mkdir /var/www/isoldpurple
	sudo cp -r ~/src/jma/isoldpurple/site/ /var/www/isoldpurple/

	# Crontab files for root and for jeff are available at crontab/root
	# and crontab/jeff.  The below is just explanation.
	#
	# I want static websites to auto-update once a day.  So I edit my
    # crontab to add these lines.  In the case of p27, the site is
    # generated from p27-src, so I'll eventually want to make a deploy
    # key so that the auto-generation can happen on p27.
	47 * * * *  cd /home/jeff/src/jma/p27 && /usr/bin/git pull --ff-only
	48 * * * *  cd /home/jeff/src/jma/isoldpurple && /usr/bin/git pull --ff-only

	# and root's crontab to add these lines:
	57 * * * *  /usr/bin/rsync -va --delete /home/jeff/src/jma/p27/site/ /var/www/p27/
	58 * * * *  /usr/bin/rsync -va --delete /home/jeff/src/jma/isoldpurple/site/ /var/www/isoldpurple/
	

## mail

### postfix and dovecot

The ubuntu package mail-stack-delivery installs postfix and dovecot
and configures them to talk to each other.

    sudo apt-get install -y ntp mail-stack-delivery

Answers to questions:
* internet site
* the system name is p27.eu (no trailing period, no host name).

I already generated certificates for p27.eu, and the root crontab will
check daily to be sure it's up to date.  So I can just use that.

I'm pretty sure dovecot installs with a self-certified certificate,
which will cause problems.  Note that to let certbot bypass nginx
(i.e., run a stand-alone web server on port 443), I need to stop nginx
temporarily.  This only needs to happen during site setup, though (I
think).

    sudo certbot certonly --agree-tos -m jeff@p27.eu --nginx -d nantes-1.p27.eu
/*
    sudo service nginx stop && \
	  sudo certbot certonly --agree-tos -m jeff@p27.eu --standalone \
	    -d mail.p27.eu; \
	  sudo service nginx start
*/
    (cd /etc/dovecot && sudo rm dovecot.pem && \
	 sudo ln -s /etc/letsencrypt/live/nantes-1.p27.eu/fullchain.pem dovecot.pem)
    (cd /etc/dovecot && sudo rm private/dovecot.pem && \
	 sudo ln -s /etc/letsencrypt/live/nantes-1.p27.eu/privkey.pem private/dovecot.pem)

	sudo postconf -e 'smtpd_sasl_type = dovecot'
	sudo postconf -e 'smtpd_sasl_path = private/auth'
	sudo postconf -e 'smtpd_sasl_local_domain ='
	sudo postconf -e 'smtpd_sasl_security_options = noanonymous'
	sudo postconf -e 'broken_sasl_auth_clients = yes'
	sudo postconf -e 'smtpd_sasl_auth_enable = yes'
	sudo postconf -e 'smtpd_recipient_restrictions = permit_sasl_authenticated,permit_mynetworks,reject_unauth_destination'
	sudo postconf -e 'home_mailbox = Maildir/'
	sudo postconf -e 'mydomain = p27.eu'

    # Use TLS for both incoming and outgoing mail.
	sudo postconf -e 'smtp_tls_security_level = may'
	sudo postconf -e 'smtpd_tls_security_level = may'
	sudo postconf -e 'smtp_tls_note_starttls_offer = yes'
	sudo postconf -e 'smtpd_tls_loglevel = 1'
	sudo postconf -e 'smtpd_tls_received_header = yes'

	# Enable virtual alias mapping.
	sudo postconf -e 'virtual_alias_domains = p27.eu'
	sudo postconf -e 'virtual_alias_maps = hash:/etc/postfix/virtual'

Now I edit /etc/dovecot/conf.d/10-ssl.conf and change

    ssl = yes
	ssl_cert = /etc/dovecot/dovecot.pem
	ssl_key = /etc/dovecot/private/dovecot.pem

I might want to spot check this file:

    sudo cp postfix/main.cf /etc/postfix/main.cf

I'll need to open port 25 (smtp) and 993 (imap over SSL).  In
addition, incoming smtp connections, after knocking at port 25, will
need to use port 465 (SMTP over SSL) and/or 587 (SMTP AUTH, I think).

    sudo ufw allow smtp/tcp
	sudo ufw allow imaps/tcp
	sudo ufw allow 465/tcp
	sudo ufw allow 587/tcp

At some point I'd like to tell dovecot not to list on 110 (unsecured
pop3), 143 (unsecured imap), or 995 (pop3 over SSL, because I'm not
using pop).  For now, I'm simply denying access to those ports (via
ufw's default policy).

And, finally, set up email aliases to map to users.

    sudo emacs /etc/postfix/virtual

cf. srd p27-postfix-aliases

At this point, I should check my configuration from the outside at all
of these sites:

	http://www.emailsecuritygrader.com/ 
	https://ssl-tools.net/mailservers .
	http://www.checktls.com/perl/TestReceiver.pl

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

