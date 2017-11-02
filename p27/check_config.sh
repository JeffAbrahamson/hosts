#!/bin/bash

# Check what differences between git and the production.
# This should be run from the hosts/p27 git directory.
#
# The script uses sudo, because many of the production files we are
# comparing are not world-readable.

diff_dir() {
    prod_dir="$1"
    git_dir="$2"

    if [ ! -d "$prod_dir" ]; then
	echo "Nothing to check here:  $prod_dir"
	return
    fi
    files="$git_dir/*"
    for f in $files; do
	filename_base=$(basename $f)
	if [ ! -e "$prod_dir/$filename_base" ]; then
	    echo "Missing:  $prod_dir/$filename_base"
	elif ! sudo cmp --silent "$prod_dir/$filename_base" "$f"; then
	    echo "Different:  $prod_dir/$filename_base  !=  $f"
	fi
    done
}

diff_file() {
    prod_file="$1"
    git_file="$2"

    if [ ! -e "$prod_file" ]; then
	echo "Missing:  $prod_file"
    elif ! sudo cmp --silent "$prod_file" "$git_file"; then
	echo "Different:  $prod_file  !=  $git_file"
    fi
}

diff_file_golden() {
    prod_file="$1"
    git_file="$2"
    golden_diff="$3"

    tmp_file=$(mktemp /tmp/check_config_XXXXXXXX)
    chmod 600 $tmp_file
    sudo diff "$prod_file" "$git_file" > $tmp_file
    if ! sudo cmp --silent $tmp_file "$golden_diff"; then
	echo "Different:  $prod_file  !  $git_file"
    fi
    rm $tmp_file
}

diff_cron() {
    git_file="$1"
    user="$2"
    
    tmp_file=$(mktemp /tmp/check_config_XXXXXXXX)
    chmod 600 $tmp_file
    sudo -u "$user" crontab -l > $tmp_file
    if ! cmp --silent $tmp_file $git_file; then
	echo "Different:  $git_file"
    fi
}

# Make sure the golden directory exists and has the right permissions
# (0700), since it will contain password.  Populate it by hand on each
# production host, since we don't want those passwords in git.  The
# files in it should have mode 0600.
if [ -d golden ]; then
    chmod 700 golden
    chmod 600 golden/*
fi

diff_cron crontab/jeff jeff
diff_cron crontab/root root

if [ "$HOSTNAME" = nantes-1 ]; then
    diff_file /etc/dovecot/dovecot.conf dovecot/dovecot.conf
    diff_dir /etc/dovecot/conf.d/ dovecot/conf.d/
    diff_dir /etc/postfix/ postfix/
fi

if [ "$HOSTNAME" = nantes-2 ]; then
    diff_file_golden /etc/grafana/grafana.ini grafana/grafana.ini \
		     golden/grafana.ini.diff
    diff_file /etc/influxdb/influxdb.conf influxdb/influxdb.conf
fi

diff_file /etc/nginx/nginx.conf nginx/nginx.conf
diff_dir /etc/nginx/sites-available/ nginx/sites-available/

diff_file /etc/ssh/sshd_config ssh/sshd_config
if [ "$HOSTNAME" = nantes-1 ]; then
    diff_file_golden /etc/telegraf/telegraf.conf telegraf/telegraf.conf.nantes-1 \
		     golden/telegraf.conf.nantes-1.diff
elif [ "$HOSTNAME" = nantes-2 ]; then
    diff_file_golden /etc/telegraf/telegraf.conf telegraf/telegraf.conf.nantes-2 \
		     golden/telegraf.conf.nantes-2.diff
else
    echo "Telegraf:  Unknown host, no diff available."
fi
