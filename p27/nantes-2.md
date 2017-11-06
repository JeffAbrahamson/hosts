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


## Monitoring (TICK stack with s/chronograf/grafana/)

### influxdb server

[This tutorial](http://www.andremiller.net/content/grafana-and-influxdb-quickstart-on-ubuntu)
is quite useful.  The following is largely based on it.

	$ curl -sL https://repos.influxdata.com/influxdb.key | sudo apt-key add -
	$ source /etc/lsb-release
	$ echo "deb https://repos.influxdata.com/${DISTRIB_ID,,} ${DISTRIB_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/influxdb.list
	
	$ sudo apt-get update && sudo apt-get install -y influxdb
	$ sudo service influxdb start

I can check that it's running with `systemctl status`:

	$ systemctl status influxdb

Now I create a user for myself (srd: p27-influxdb).  Note that
telegraf would cause the telegraf database to be created anyway.  I
also create a test database for occasional testing.

    $ influx
	CREATE DATABASE telegraf
	CREATE DATABASE test
	USE telegraf
    CREATE USER "name" WITH PASSWORD 'secret' WITH ALL PRIVILEGES
	CREATE USER "telegraf-name" WITH PASSWORD 'secret' WITH ALL PRIVILEGES
	SHOW USERS
	exit

I don't think it's right that the telegraf user should have full
privileges, but it seems to need quite a lot if not all for the
moment, even if the database telegraf already exists.

Now copy my config into place:

    $ sudo cp influxdb/influxdb.conf /etc/influxdb/influxdb.conf
	$ sudo service influxdb restart

This enables user auth.  Note also:
* My hostname is in that file: search for p27 if you're not me.
* It does not enable https, because nginx handles SSL termination and proxies to influxdb, which only listens to http on localhost.

I can now do a simple test:

    $ influx
	auth
	username: jeff
	password: ...
	Using database test
	> INSERT foo,host=serverA value=0.64
	> select * from foo
	name: foo
	time                host    value
	----                ----    -----
	1509526499624590841 serverA 0.64
	> show measurements
	name: measurements
	name
	----
	foo
	> drop series from "foo"
	> show measurements
	>


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

The copy line, below, avoids copying and manually editing the password
(for me).  If you're not me, you'll have edit the host name as well.

    $ sudo apt-get install telegraf
	$ cat telegraf/telegraf.conf | \
	  sed -e 's/================username================/influx-user/;' | \
	  sed -e 's|================password================|influx-pass|;' | \
	  sudo tee /etc/telegraf/telegraf.conf >/dev/null
    $ sudo chown telegraf:telegraf /etc/telegraf/telegraf.conf
	$ sudo chmod 600 /etc/telegraf/telegraf.conf
	$ ls -l /etc/telegraf/telegraf.conf
	-rw------- 1 telegraf telegraf 74246 Nov  1 10:14 /etc/telegraf/telegraf.conf
	$

Since telegraf.conf has my influx password in it, I'd rather it not be
world readable.  On my system, telegraf runs as user telegraf.

Now I can do a quick test:

	$ influx
	Connected to http://localhost:8086 version 1.3.7
	InfluxDB shell version: 1.3.7
	> auth
	username: jeff
	password:
	> use telegraf
	Using database telegraf
	> show measurements
	name: measurements
	name
	----
	cpu
	disk
	diskio
	internal_agent
	internal_gather
	internal_memstats
	internal_write
	kernel
	mem
	processes
	swap
	system
	> select * from cpu limit 3
	...
	> show tag keys from cpu
	name: cpu
	tagKey
	------
	cpu
	host
	>
	show tag values from cpu with key = "host"
	name: cpu
	key  value
	---  -----
	host nantes-2
	>

Note that I will want to install telegraf on all of my other hosts:
nantes-1, but also my home desktop, my laptop, my file server.
Cf. [telegraf.md](../telegraf.md).


### grafana

The "C" in TICK is chronograf.  For historical reasons I've used
grafana.  I can't justify that decision beyond history.  Maybe
chronograf is better now.

    $ echo "deb https://packagecloud.io/grafana/stable/debian/ jessie main" | \
	  sudo tee /etc/apt/sources.list.d/grafana.list
    $ curl https://packagecloud.io/gpg.key | sudo apt-key add -
	$ sudo apt-get update
	$ sudo apt-get install -y grafana sqlite3
	$ sudo service grafana-server stop

I don't want grafana to run until I set up my config file, since it
authenticates at admin/admin out of the box.

Note that wheezy is debian 7, jessie is debian 8, and stretch is
debian 9.  On the day I'm writing this, the
[grafana docs](http://docs.grafana.org/installation/debian/) say to
use jessie.
Cf. [this issue](https://github.com/grafana/grafana/issues/8737) and
[this one](https://github.com/grafana/grafana/issues/8648).

Grafana listens on port 3000.  I've configured nginx (cf. 02-grafana)
to proxy to 3000.  So (for me), monitor.p27.eu should point to
grafana.

Set up passwords (srd p27-grafana):

    $ cat grafana/grafana.ini | \
	  sed -e 's|================ admin_passwd ================|grafana-admin-passwd|;' | \
	  sed -e 's|================ secret_key ================|grafana-secret-key|;' | \
	  sudo tee /etc/grafana/grafana.ini >/dev/null
    $ sudo chown root:grafana /etc/grafana/grafana.ini
	$ sudo chmod 640 /etc/grafana/grafana.ini
	$ ls -l /etc/grafana/grafana.ini
    -rw-r----- 1 root grafana 13099 Nov  1 10:48 grafana.ini
	$ sudo service grafana-server start

I can (if I so desire) check the mysql table thus:

    $ sudo sqlite3 /var/lib/grafana/grafana.db
	SQLite version 3.11.0 2016-02-15 17:29:24
	Enter ".help" for usage hints.
	sqlite> select * from user;
	Error: no such table: user
	sqlite>
	$

To configure grafana, go to the swirl menu (upper left) and choose
"Data Sources", then click "Add Data Source".

    name: influxdb-telegraf  (check: default)
	type: influxdb

	url: http://localhost:8086
	access: proxy

	http auth: nothing checked

	InfluxDB Details:
      database: telegraf
	  user: (my influx telegraf user)
	  pass: (my influx telegraf password)

Then save and test.

Grafana automatically doesn't start at system start.  This fixes that:

    $ sudo update-rc.d grafana-server defaults


### postfix

In order to receive alerts, I have to send mail.  So I set up an
outgoing-only postfix server.  It just uses my own mail host for mail.

### kapacitor or siren

For alerts

