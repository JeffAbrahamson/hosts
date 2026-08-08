Install the rsyslog filters before Ubuntu's `50-default.conf`, so matching
messages are written to their dedicated logs and then discarded before the
general syslog and kern.log rules:

    sudo cp etc-rsyslog.d-20-apparmor.conf /etc/rsyslog.d/20-apparmor.conf
    sudo cp etc-rsyslog.d-20-dbus.conf /etc/rsyslog.d/20-dbus.conf
    sudo chown root:root /etc/rsyslog.d/20-apparmor.conf /etc/rsyslog.d/20-dbus.conf
    sudo chmod 644 /etc/rsyslog.d/20-apparmor.conf /etc/rsyslog.d/20-dbus.conf

Install log rotation for the two dedicated logs:

    sudo cp etc-logrotate.d-apparmor-dbus /etc/logrotate.d/apparmor-dbus
    sudo chown root:root /etc/logrotate.d/apparmor-dbus
    sudo chmod 644 /etc/logrotate.d/apparmor-dbus

The rotation policy uses `su syslog adm`, matching rsyslog's log-file owner
and group and allowing rotation when `/var/log` is group-writable.

Validate the configuration, then restart rsyslog.  Logrotate is timer-driven
and does not need restarting:

    sudo rsyslogd -N1
    sudo logrotate --debug /etc/logrotate.d/apparmor-dbus
    sudo systemctl restart rsyslog.service

AppArmor denials and status records are intentionally absent from kern.log and
syslog after this change.  Check `/var/log/apparmor.log` when debugging policy.
Only messages emitted by `dbus-daemon` or `dbus-broker` go to
`/var/log/dbus.log`; application failures which merely mention D-Bus stay in
syslog.
