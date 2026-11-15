# siegfried, the fileserver

siegfried is a small headless box (2-core AMD G-T56N, 3.4 GB RAM,
60 GB system disk) on the home network.  It holds the big data disks,
runs pi-hole, shares the printer, and records network and disk
statistics.  There is no X and no display manager: log in over ssh.

## Setting up

    mkdir -p ~/src/jma
    git clone https://github.com/JeffAbrahamson/hosts.git ~/src/jma/hosts
    ~/src/jma/hosts/2604-LTS.sh

`2604-LTS.sh` knows siegfried is a server (cf. `role_for_host`; set
`HOST_ROLE=server` to treat another host the same way).  As a server it
installs `2604-LTS-common.pkg` and `2604-LTS-server.pkg`, removes
`2604-LTS-server-remove.pkg`, sets up Ookla speedtest, clones the
repositories in `server-git` over https, and runs the dotfiles
`make install`.  It installs no ssh keys or other secrets: use `ssh -A`
on the rare occasions siegfried needs to reach elsewhere as me.

Networking is dhcpcd/ifupdown.  Don't install NetworkManager here: it
could take over the interface and cut off ssh.

The dotfiles firewall step sets the ufw rules for siegfried: ssh
(rate-limited), 53/udp and 80/tcp for pi-hole, 631/tcp for CUPS.

## Data disks

Four LUKS-encrypted disks, mounted at `/jma-4t`, `/jma-3t`, `/sb-4t`
and `/sb-r4t`.  They are deliberately not in `/etc/crypttab` or
`/etc/fstab`: after a reboot, unlock and mount them by hand with

    luks-mount-all

(from dotfiles), which reads `~/.luksmountrc` (`LUKS_UUID MOUNT_POINT`
per line).  `luks-mount-all -u MOUNT_POINT` adds a new volume.

The `lsblk` and `ls /dev/disk/by-uuid/` commands help to identify
disks.

## Services

* **pi-hole**, installed with its own installer, not by `2604-LTS.sh`.
  It answers DNS on port 53.  Since v6, pihole-FTL serves the admin UI
  itself on ports 80 and 443 and the upgrade removes lighttpd.  The
  v6 upgrade set `webserver.port` to 8080, presumably because lighttpd
  still held port 80; restore it with
  `sudo pihole-FTL --config webserver.port '80o,443os,[::]:80o,[::]:443os'`
  and restart `pihole-FTL`.
* **CUPS** shares the HP DeskJet 2800 to the network.
* **sshd**.

Netatalk (AFP/Time Machine and the legacy AppleTalk daemons) is no
longer used; `2604-LTS.sh` removes it.

## Crontab

My crontab is backed up daily to
`/jma-4t/jeff/files/data/hosts/siegfried/crontab`.  It runs:

* `disk-usage.sh` hourly, recording usage of the data disks;
* `speedtest` hourly (Ookla rate-limits more frequent runs);
* `up-monitor` every five minutes;
* a daily `rsync --delete` mirror of `/jma-4t/jeff/` to `/jma-3t/jeff/`
  and `/sb-r4t/jeff/`.

Statistics land in `~/data/hosts/siegfried/`.

## Unison

Copy the `~/.unison/` cache files from the old fileserver if
available.
