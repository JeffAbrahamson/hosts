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


## piwik

I'm following the (currently overly manual) piwik installation
instructions [here](https://piwik.org/docs/installation/).

### MariaDB

Piwik really wants to use MySQL/MariaDB, even if its developer team
[really wants](https://piwik.org/faq/how-to-install/faq_55/) to use
more than that.

    $ sudo apt-get install -y mariadb-common mariadb-server mariadb-client

Now set up mariadb and harden it.  The db and user/password names here
are arbitrary (srd):

    $ sudo mysql_secure_installation

    $ sudo mysql
    MariaDB [(none)]> CREATE DATABASE my-piwik-db-name;
    MariaDB [(none)]> CREATE USER 'my-piwik-username'@'localhost' IDENTIFIED BY 'my-strong-password-here';
    MariaDB [(none)]> GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, CREATE TEMPORARY TABLES, LOCK TABLES ON my-piwik-db-name.* TO 'my-piwik-username'@'localhost';

I can now log in as piwi thus:

    $ mysql -u my-piwik-username -p

and as root thus:

    $ sudo mysql


### PHP

Piwik is PHP-based.

    $ sudo apt-get install -y php7.0 php7.0-gd php7.0-cli \
                              php7.0-mbstring php7.0-mysql php-xml

### Piwik

That page tells me to download a zip (!) file containing piwik from
[here](https://builds.piwik.org/piwik.zip).

    $ sudo apt-get install -y unzip w3m
    $ wget https://builds.piwik.org/piwik.zip
    $ (cd /var/www && sudo su unzip /home/jeff/piwik.zip)

This file redirects to the installation page.  Aside from verifying
that we can find that page, we don't really need the file sitting in
/var/www/.

    $ sudo rm /var/www/How\ to\ install\ Piwik.html

Now I visit https://data.p27.eu/p/ to begin setup.

These two fields are pre-filled correctly:

    database server: 127.0.0.1
    table prefix:    piwik_
    adapter:         PDO\MYSQL

These I should fill in (based on srd values):

    login
    pass
    db name
    table_prefix

Then I create a piwik superuser (srd).

Then I tell it my website(s).  Piwik will tell me the code to put on
my site.

### Install GeoLite2-City database

It's in github:

    # (cd ~/src/ && git clone https://github.com/maxmind/geoipupdate.git)

but there's also an ubuntu PPA:

    $ sudo add-apt-repository ppa:maxmind/ppa
	$ sudo apt-get update
	$ sudo apt-get install -y geoipupdate

	$ cd /var/www/piwik/p/misc
	$ for f in /usr/share/GeoIP/*; do sudo ln -s $f; done

Then in a browser go to piwik -> (left menu) system -> geolocation and
choose "GeoIP (Php)" and click save.

Strangely, this causes piwik's system check to report foreign files.
I'm going to ignore that.


## postgresql

On hold...


## influxdb

### influxdb server

[This tutorial](http://www.andremiller.net/content/grafana-and-influxdb-quickstart-on-ubuntu)
is quite useful.  The following is largely based on it.

	$ curl -sL https://repos.influxdata.com/influxdb.key | sudo apt-key add -
	$ source /etc/lsb-release
	$ echo "deb https://repos.influxdata.com/${DISTRIB_ID,,} ${DISTRIB_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/influxdb.list
	
	$ sudo apt-get update && sudo apt-get install -y influxdb
	$ sudo service influxdb start


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
