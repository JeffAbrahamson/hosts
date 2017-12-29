# nantes-1: mail and web setup

## Start

I am using a host with 1 GB of RAM.  I maybe could have gotten by with
a cheaper host that has only 512 MB of RAM.  In that case, I probably
would have added additional swap.

The first thing to do is to follow the instructions in
[common](common.md) for basic user setup, ufw firewall setup, and ssh
hardening.

Note that for the rest of this document, I'll assume that
cwd=hosts/p27.


## firewall

I think this is the ufw firewall configuration I want to see:

	22/tcp                     ALLOW       Anywhere
	22                         LIMIT       Anywhere
	80/tcp                     ALLOW       Anywhere
	443/tcp                    ALLOW       Anywhere
	25/tcp                     ALLOW       Anywhere
	993/tcp                    ALLOW       Anywhere
	465/tcp                    ALLOW       Anywhere
	587/tcp                    ALLOW       Anywhere
	22/tcp (v6)                ALLOW       Anywhere (v6)
	22 (v6)                    LIMIT       Anywhere (v6)
	80/tcp (v6)                ALLOW       Anywhere (v6)
	443/tcp (v6)               ALLOW       Anywhere (v6)
	25/tcp (v6)                ALLOW       Anywhere (v6)
	993/tcp (v6)               ALLOW       Anywhere (v6)
	465/tcp (v6)               ALLOW       Anywhere (v6)
	587/tcp (v6)               ALLOW       Anywhere (v6)

Port notes:
* 22 = ssh
* 25 = smtp
* 80 = http
* 443 = https
* 465 = URL Rendesvous Directory for SSM
* 587 = submission (SMTP TLS start)
* 993 = imaps

The setup commands are thus these:

    sudo ufw default allow outgoing
    sudo ufw default deny incoming
    sudo ufw allow ssh/tcp
    sudo ufw limit ssh

	sudo ufw allow http/tcp
	sudo ufw limit http
	sudo ufw allow https/tcp
	sudo ufw limit https

	sudo ufw allow 25/tcp
	sudo ufw allow 465/tcp
	sudo ufw allow 587/tcp
	sudo ufw allow 993/tcp

    sudo ufw enable

    sudo ufw status verbose


## nginx

Set up nginx as described [here](nginx.md).

### Local set configuration

The local site configurations, noted in [nginx.md](nginx.md) are these

    (cd /etc/nginx/sites-enabled && sudo ln -s ../sites-available/01-www)
    (cd /etc/nginx/sites-enabled && sudo ln -s ../sites-available/05-isoldpurple)
    (cd /etc/nginx/sites-enabled && sudo ln -s ../sites-available/06-transport-nantes)

### Local certbot configuration

    # In the following, I might need to manually edit files on the
    # server to remove the reference to the certs that don't exist
    # yet.
    sudo certbot --agree-tos -m jeff@p27.eu --nginx -d p27.eu -d www.p27.eu
    # When asked, enter my email address.
    # Certbot config is saved in /etc/letsencrypt/
    sudo certbot --agree-tos -m jeff@p27.eu --nginx -d isoldpurple.com -d www.isoldpurple.com
    sudo certbot --agree-tos -m jeff@p27.eu --nginx -d transport-nantes.com -d www.transport-nantes.com

### Actually serve some content

    # Populate my web sites.
    (cd ~/src/jma && git clone https://github.com/JeffAbrahamson/p27.git)
    sudo mkdir /var/www/p27
    sudo cp -r ~/src/jma/p27/site/ /var/www/p27/
    (cd ~/src/jma && git clone https://github.com/JeffAbrahamson/isoldpurple.git)
    sudo mkdir /var/www/isoldpurple
    sudo cp -r ~/src/jma/isoldpurple/site/ /var/www/isoldpurple/
    (cd ~/src/jma && git clone https://github.com/transport-nantes/tn.git)
    sudo mkdir /var/www/tn
    sudo cp -r ~/src/jma/tn/site/ /var/www/tn/

    # Crontab files for root and for jeff are available at crontab/root
    # and crontab/jeff.  The below is just explanation.
    #
    # I want static websites to auto-update once a day.  So I edit my
    # crontab to add these lines.  In the case of p27, the site is
    # generated from p27-src, so I'll eventually want to make a deploy
    # key so that the auto-generation can happen on p27.
    Cf. [crontab/jeff](crontab/jeff)

    # and root's crontab to add these lines:
    Cf. [crontab/root](crontab/root)


## mail

### SPF record

Make sure I have a valid spf record for my mail-sending host.
Cf. [this DO write-up](https://www.digitalocean.com/community/tutorials/how-to-use-an-spf-record-to-prevent-spoofing-improve-e-mail-reliability).
I think the following DNS TXT record is correct for me:

    "v=spf1 mx ~all"

### postfix and dovecot

The ubuntu package mail-stack-delivery installs postfix and dovecot
and configures them to talk to each other.

    sudo apt-get install -y ntp mail-stack-delivery

Answers to questions:
* internet site
* the system name is p27.eu (no trailing period, no host name).

I already generated certificates for p27.eu, and the root crontab will
check daily to be sure it's up to date.  So I can just use that.

Dovecot installs with a self-certified certificate, which will cause
problems.  I have nginx configs for these names so that it's easy to
generate and auto-update certificates.

    sudo certbot certonly --agree-tos -m jeff@p27.eu --nginx -d nantes-1.p27.eu
    sudo certbot certonly --agree-tos -m jeff@p27.eu --nginx -d mail.p27.eu

    # I thought I didn't need to care about the SSL keys in
    # /etc/dovecot/ because I'll have specified the letsencrypt
    # versions in /etc/dovecot/conf.d/10-ssl.conf and in
    # /etc/postfix/main.cf.  But it turns out that it matters, and I'm
    # not sure why.  So let's fix the links not to point to
    # self-signed certificates.
    (cd /etc/dovecot && sudo rm dovecot.pem && \
     sudo ln -s /etc/letsencrypt/live/mail.p27.eu/fullchain.pem dovecot.pem)
    (cd /etc/dovecot && sudo rm private/dovecot.pem && \
     sudo ln -s /etc/letsencrypt/live/mail.p27.eu/privkey.pem private/dovecot.pem)

I might want to spot check this file:

    sudo cp postfix/main.cf /etc/postfix/main.cf

Now I configure dovecot.  If there's doubt, diff first (or copy
existing files to .bak).

    sudo cp dovecot/dovecot.conf /etc/dovecot/dovecot.conf
    sudo cp dovecot/conf.d/*.conf /etc/dovecot/conf.d/

I upped the imap mail_max_userip_connections from 10 to 20 because,
with a desktop, a laptop, two tablets, and a phone all trying to check
mail, I was getting connections refused from dovecot (which aren't
reported intelligently to the client, the tcp connection just drops,
but it's clear in `/var/log/mail.log`).  At least I now know that
dovecot's anti DOS protection works.

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

A couple debugging things about sockets.  I can check who's listening
on what socket (and then grep to restrict):

    sudo lsof -iTCP -sTCP:LISTEN | grep dovecot

I can also get socket information for a given pid thus:

    sudo ss -l -p -n | grep 19715

And, finally, set up email aliases to map to users.  Note that I'm
assuming that local delivery means to an existing user with a unix
account.
Cf. srd p27-postfix-aliases
Cf. http://www.postfix.org/VIRTUAL_README.html
  Note that creating entries for abuse and for postmaster are
  important for standards compliance.

    sudo emacs /etc/postfix/virtual

Now tell postfix to update its database:

    sudo postmap /etc/postfix/virtual
    sudo service postfix reload

I can test imaps connection thus:

    openssl s_client -connect mail.p27.eu:imaps

I can test smtp connections thus:

    nc mail.example.com 25
    EHLO $hostname
    MAIL FROM:<root@example.com>
    RCPT TO:<jeff@p27.eu>
    DATA
    Subject: Test email

    Body of the email
    .
    QUIT

To verify certificates, something like this is handy:

    openssl s_client -connect mail.p27.eu:465 -verify_hostname mail.p27.eu \
      < /dev/null 2>&1
    openssl s_client -connect mail.p27.eu:993 -verify_hostname mail.p27.eu \
      < /dev/null 2>&1

At this point, I should check my configuration from the outside at all
of these sites:

    http://www.emailsecuritygrader.com/ 
    https://ssl-tools.net/mailservers .
    http://www.checktls.com/perl/TestReceiver.pl


### Mail clients

When I set up thunderbird, I specified

  imap:
    server name: mail.p27.eu
    user: jeff
    connection: SSL/TLS
    auth: normal

  smtp:
    server name: mail.p27.eu
    port: 465
    connection: SSL/TLS
    auth: normal
    user: jeff
    
In both cases, I provided my unix password.

I'm not sure why encrypted auth fails on smtp, but since it goes over
TLS, I think all is ok.

Encrypted auth worked for a while with imap, then stopped, and I'm not
sure why.  Same reasoning: it's going over TLS, so I think this is
superfluous.


### anti-spam

#### OpenDKIM

#### SpamAssassin

#### ClamAV ?

### anti-virus


### server-side filtering


### DKIM

