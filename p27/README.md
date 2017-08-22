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

	mkdir $HOME/.ssh
	chmod 700 $HOME/.ssh

    sudo apt-get -y update
	sudo apt-get -y upgrade
	sudo apt-get -y install git emacs-nox letsencrypt
	
	mkdir -p src/jma
	cd src/jma
	git clone https://github.com/JeffAbrahamson/hosts.git
	cd hosts/p27

	# On my workstation:
	rsync .ssh/id_rsa.pub www.p27.eu:.ssh/known_hosts
	# I'll also want to append the public key from any other hosts I use.

	# Probably I want my sshd_config, but double-check that the
	# distribution isn't offering anything new.
	#
	# Don't do this on vagrant where I needn't set up ssh certificates.
	diff sshd_config /etc/ssh/sshd_config
	cp sshd_config /etc/ssh/sshd_config
	sudo service sshd restart
	## And now from another window confirm that ssh access still works. ####


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


### SSL/TLS


### anti-spam


### anti-virus


### server-side filtering


### DKIM


### SPF records



## nginx

## postgresql

## influxdb

## grafana

## letsencrypt


