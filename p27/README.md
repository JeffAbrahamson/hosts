# Setup for p27.eu

This assumes the domain exists and that I've set up DNS and reverse
correctly to point to it.  Note that srd is my password manager, where
I put the secrets I use on the site.  If something refers to srd, just
understand that you need to generate a password or enter PII for your
site.

Automating host setup isn't worthwhile because I don't anticipate
doing this more than twice (once to set up, once again to make sure I
can).  In addition, there's bitrot, and in the absence of frequent
testing, automation wouldn't be reliable.  This guide is either help
to someone else or a guide to me ages hence, when I'll have to verify
each step because something might have changed.

Pull requests and bug reports are welcome (use github).


There's a slightly dated but very nice (and long) tutorial at
ArsTechnica that may be worth the read for those interested.

    [part 1](https://arstechnica.com/information-technology/2014/02/how-to-run-your-own-e-mail-server-with-your-own-domain-part-1/)
	[part 2](https://arstechnica.com/information-technology/2014/03/taking-e-mail-back-part-2-arming-your-server-with-postfix-dovecot/)
	[part 3](https://arstechnica.com/information-technology/2014/03/taking-e-mail-back-part-3-fortifying-your-box-against-spammers/)
	[part 4](https://arstechnica.com/information-technology/2014/04/taking-e-mail-back-part-4-the-finale-with-webmail-everything-after/)


## DNS

My DNS zone file:

	@ 10800 IN A 138.197.178.0
	nantes-1 10800 IN A 138.197.178.0
	data 10800 IN CNAME nantes-1.p27.eu.
	influxdb 10800 IN CNAME nantes-1.p27.eu.
	mail 10800 IN CNAME nantes-1.p27.eu.
	monitor 10800 IN CNAME nantes-1.p27.eu.
	www 10800 IN CNAME nantes-1.p27.eu.
	@ 10800 IN MX 50 nantes-1.p27.eu.
	@ 10800 IN TXT "v=spf1 include:_mailcust.gandi.net ?all"


## I am using two hosts

One host, which I call nantes-1, handles the services I care about
most: mail and web services, mostly.  I monitor those services from
another host, nantes-2, on the theory that if something goes awry on
nantes-1, I'd like to find out about it from a host that is not having
problems.  In addition, I've put those two hosts in different data
centres so that monitoring won't say all is great if a DC falls off
the net (a highly unlikely event, but routers sometimes become flaky).

* [nantes-1: mail and web setup](nantes-1.md)
* [nantes-2: monitoring and analytics](nantes-2.md)


## Periodic testing

Periodically, I should test that all is well, that I'm not on black
hole lists, etc.  Here are some resources:

* http://www.emailsecuritygrader.com/ 
* https://ssl-tools.net/mailservers .
* http://www.checktls.com/perl/TestReceiver.pl

This would be nice to automate.


## To Do

* spam protection
* fail2ban configuration (and telegraf support) for postfix, nginx, sshd
* [unattended-upgrades](https://gist.github.com/dominikwilkowski/435054905c3c7abc2badc92a0acff4ba)
* logwatch?
* [rootkit detection](https://gist.github.com/dominikwilkowski/435054905c3c7abc2badc92a0acff4ba)
* tripwire?
