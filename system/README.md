Install etc-rsyslog.d-20-apparmor.conf:

    sudo  cp  etc-rsyslog.d-20-apparmor.conf  /etc/rsyslog.d/20-apparmor.conf
	sudo chown root:root /etc/rsyslog.d/20-apparmor.conf
	sudo chmod 644 /etc/rsyslog.d/20-apparmor.conf

Install var-log-apparmor:

    sudo  cp  var-log-apparmor  /var/log/apparmor
	sudo chown root:root /var/log/apparmor
	sudo chmod 644 /var/log/apparmor

Restart rsyslogd and logrotate daemons:

    sudo systemctl restart rsyslog.service
    sudo systemctl restart logrotate.service
