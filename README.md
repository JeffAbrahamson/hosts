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

This copies SSH keys and srd to the new host, then runs 2404-LTS.sh
under a fresh ssh-agent.  2404-LTS.sh prompts for each key passphrase
(displaying it from the USB for easy copy-paste), installs packages, and
clones repositories.  When it finishes, install-from-usb.sh prints
AFTER-INSTALL.md.

## Post-automation

After `install-from-usb.sh` completes, follow `AFTER-INSTALL.md`.

## Printer

Printer setup notes have moved to `AFTER-INSTALL.md`.

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

Social media and session notes have moved to `AFTER-INSTALL.md`.

TODO:
  * How do I set up keyboard switching so I can get accents?
