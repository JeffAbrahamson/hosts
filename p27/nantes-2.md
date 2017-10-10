# nantes-2: influxdb, grafana, piwik setup

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
	[...]    #### Complete this <<====

Port notes:
* 22 = ssh
* 80 = http
* 443 = https

The setup commands are thus these:

    sudo ufw default allow outgoing
    sudo ufw default deny incoming
    sudo ufw allow ssh/tcp
    sudo ufw limit ssh

	sudo ufw allow http/tcp
	sudo ufw limit http
	sudo ufw allow https/tcp
	sudo ufw limit https

    sudo ufw enable

    sudo ufw status verbose


## nginx

Set up nginx as described [here](nginx.md).

### Local set configuration

The local site configurations, noted in [nginx.md](nginx.md) are these

    (cd /etc/nginx/sites-enabled && sudo ln -s ../sites-available/02-grafana)
    (cd /etc/nginx/sites-enabled && sudo ln -s ../sites-available/03-influxdb)
    (cd /etc/nginx/sites-enabled && sudo ln -s ../sites-available/04-piwik)

### Local certbot configuration

    # In the following, I might need to manually edit files on the
    # server to remove the reference to the certs that don't exist
    # yet.
    sudo certbot --agree-tos -m jeff@p27.eu --nginx -d influxdb.p27.eu
    # When asked, enter my email address.
    # Certbot config is saved in /etc/letsencrypt/
    sudo certbot --agree-tos -m jeff@p27.eu --nginx -d data.p27.eu
    sudo certbot --agree-tos -m jeff@p27.eu --nginx -d monitor.p27.eu


## postgresql

## influxdb

### influxdb server

### telegraf client

I want to run a telegraf client on each of my hosts, including p27.
The telegraf client needs to know a password to connect to the
influxdb server (cf. srd p27-influxdb):  search for
================username================ and
================password================ and replace with user and
pass.

Telegraf is configured to listen on localhost to udp port 8095
(inputs.socket_listener).  This is unsecured and only for local
processes: the port should remain blocked by ufw.

Hosts that run additional services may (should) uncomment additional
inputs.


## grafana

## letsencrypt
