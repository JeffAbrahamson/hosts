# hosts

Personal host config.

This is the (non-secret) part of my personal host configs, to help me
reproduce on new hosts what I've already set up here and there.  This
is highly unlikely to be useful to anyone other than me.

Just to be particularly safe, however, the repo is private.

## Preparation

Given a usb key at path $usb, run on the reference machine:

  ./make-usb-for-install.sh $usb

This generates four ed25519 SSH keys, copies srd, unison configs, and
this repo to the USB, and prints each public key with distribution
instructions.  Keys generated:

  ~/.ssh/id_ed25519           — home machines (loaded by: ssh-add)
  ~/.ssh/id_ed25519.github    — GitHub        (loaded by: ssh-github)
  ~/.ssh/id_ed25519.p27       — p27 server    (loaded by: ssh-p27)
  ~/.ssh/id_ed25519.jellybooks — Jellybooks   (loaded by: ssh-jelly)

After the script runs, distribute the public keys manually:

  home:       add id_ed25519.pub to ~/.ssh/authorized_keys on home machines
  github:     add id_ed25519.github.pub to https://github.com/settings/keys
  p27:        add id_ed25519.p27.pub to p27 Salt pillar
  jellybooks: add id_ed25519.jellybooks.pub to Jellybooks Salt pillar

Then run Salt apply from an existing host to push the new keys.
Do this before moving the USB to the new host.

## Automation

On the new host, with the USB mounted at $usb:

  bash ${usb}/hosts/install-from-usb.sh

This copies SSH keys and srd to the new host, starts ssh-agent, prompts
for each key passphrase (displaying it from the USB for easy copy-paste),
and then runs 2404-LTS.sh to install packages and clone repositories.

## Post-automation

Once I can connect to siegfried, copy pertinent files.  The precise
host I want to use as model might change.

  HOST=morning
  rsync -a siegfried:/jma-4t/jeff/machines/${HOST}/.desktop-images .
  rsync -a siegfried:/jma-4t/jeff/machines/${HOST}/.unison/*prf .unison/
  rsync -a siegfried:/jma-4t/jeff/machines/${HOST}/.unison/common .unison/
  rsync -a siegfried:/jma-4t/jeff/files/work  .
  rsync -a siegfried:/jma-4t/jeff/files/data  .
  rsync -a siegfried:/jma-4t/jeff/files/Music/  Music/

Maybe also, depending on available disk space,

  rsync -a siegfried:/jma-4t/jeff/files/Videos/  Videos/

I'll want to run unison syncs before anything important changes, since
the first run will establish state and unison will ask me about
anything at all that's changed between the two sides.

  sync-data
  sync-fast
  sync-full


## Firefox

Create firefox profiles and setup sync.  Cf. srd.  Cf. bin/ff.
  * Set firefox to default browser, restore tabs
  * Set search to DDG
  * Set primary password
  * Setup sync, enter password and 2FA
  * Sign-in to google accounts.

Setup signal-desktop
Connect whatsapp web

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


Test that virtualbox works by building any vm

Logout and log back in in i3 or sway.

TODO:
  * How do I set up keyboard switching so I can get accents?
