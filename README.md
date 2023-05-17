# hosts

Personal host config.

This is the (non-secret) part of my personal host configs, to help me
reproduce on new hosts what I've already set up here and there.  This
is highly unlikely to be useful to anyone other than me.

Just to be particularly safe, however, the repo is private.

## Preparation

Given a usb key at path $usb:

Create ssh keys for home machines, git, p27, and jellybooks.  Store
them on a USB key in directory "ssh-distrib".

  To generate the pass phrases:
    head -c $((40 + $RANDOM / 2000)) < /dev/urandom | base64

  To generate the keys:
    ssh-keygen -t ed25519 -a 100

  Store the pass phrases in ssh-distrib.priv and in srd
  (cf. ssh-setup)

  To deploy them, distribute public keys:
    home: add to local machines (in authorized_hosts)
    github: add to github keys
    p27: add to pillar
    jellybooks: add to pillar

Copy $HOME/srd/ to the USB key:

  rsync -a $HOME/srd/ ${usb}/srd

Copy unison configs:

  mkdir ${usb}/unison
  rsync -a "$HOME/.unison/" ${usb}/unison

Copy the hosts repo to the USB key:

  rsync -a $HOME/src/jma/hosts/ ${usb}/hosts/

On the new host,

  cd "$HOME"
  mkdir .ssh && chmod 700 .ssh
  rsync -a ${usb}/ssh-distrib/* .ssh/
  rsync -a ${usb}/srd "$HOME/srd"
  exec ssh-agent bash

Finally,

  cd ${usb}/hosts/
  . 2204-LTS.sh


## Printer

On each host for which I want to be able to print, I need to do the following:

* Make sure the printer drivers are installed.  This should have been
  handled by my dotfiles package management.
* Make sure cups is running: `sudo service cups restart`.
* Visit `http://localhost:631/admin/` (or `http://localhost:631/` then
  "Add printer").  Choose "Discovered Network Printers: epson-wf-2965".
  Printer name is "プリンタ".
  Printer location is "ガレージ".
* In General, set double-sided to "long edge".
* Note that the environment variable PRINTER is important to some
  things trying to print, especially old-school commandline things
  (and emacs).

## Misc notes

The program `hardinfo` provides a GUI with hardware info.  There are
commandline versions for most or all of what it reports.

On birdsong, I ran `sudo sensors-detect` to find the module that
provides fan info.  (Does it make the fan work?)

Running `sensors` provides CPU temperature and fan speed.

Running `sudo fwts fan` provides a report in `results.log` describing
what is discoverable about the fans.  In my case here (ubuntu 17.10 on
birdsong), it doesn't provide much information beyond fan existence.

## Social media etc.

Create firefox profiles and setup sync.  Cf. srd.
  * At least jeff, jellybooks, TN, velopolitain, dieu, p27-jeff.
  * Setup sync (jeff, jellybooks, TN), enter primary password.
  * Sign-in to google accounts.

Setup signal-desktop
Connect whatsapp web

# setup tsd
  "make install" and ln -s data/tsd tsd
  git mod: make install should copy bash fns, should ln if needed
