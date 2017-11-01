# Telegraf install on all hosts

On my [monitor host](p27/nantes-2.md), this is already done 

On all of my other hosts, I'll want to do the below.  This assumes
I've checked out this git repository locally on the host to which I'm
installing telegraf.  There is some variation here by host because
different hosts have different monitoring needs.

	$ curl -sL https://repos.influxdata.com/influxdb.key | sudo apt-key add -
	$ source /etc/lsb-release
	$ echo "deb https://repos.influxdata.com/${DISTRIB_ID,,} ${DISTRIB_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/influxdb.list
	
	$ sudo apt-get update && sudo apt-get install -y telegraf

In the following, I should change `cat telegraf.conf` to instead cat
the appropriate telegraf file.

	$ cat telegraf.conf | \
	  sed -e 's/================username================/influx-user/;' | \
	  sed -e 's|================password================|influx-pass|;' | \
	  sudo tee /etc/telegraf/telegraf.conf >/dev/null
    $ sudo chown telegraf:telegraf /etc/telegraf/telegraf.conf
	$ sudo chmod 600 /etc/telegraf/telegraf.conf
	$ ls -l /etc/telegraf/telegraf.conf
	-rw------- 1 telegraf telegraf 74246 Nov  1 10:14 /etc/telegraf/telegraf.conf
	$
