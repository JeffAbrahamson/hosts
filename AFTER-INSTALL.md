# After Install

Manual steps to run after `install-from-usb.sh` completes.

## Files and Sync

Once I can connect to siegfried, copy pertinent files.  The precise host
I want to use as model might change.

```sh
HOST=morning
rsync -a siegfried:/jma-4t/jeff/machines/${HOST}/.desktop-images .
rsync -a siegfried:/jma-4t/jeff/machines/${HOST}/.unison/*prf .unison/
rsync -a siegfried:/jma-4t/jeff/machines/${HOST}/.unison/common .unison/
rsync -a siegfried:/jma-4t/jeff/files/work  .
rsync -a siegfried:/jma-4t/jeff/files/data  .
rsync -a siegfried:/jma-4t/jeff/files/Music/  Music/
```

Maybe also, depending on available disk space:

```sh
rsync -a siegfried:/jma-4t/jeff/files/Videos/  Videos/
```

Run unison syncs before anything important changes, since the first run
will establish state and unison will ask about anything at all that's
changed between the two sides.

```sh
sync-data
sync-fast
sync-full
```

## Accounts and Apps

* Set up Firefox profiles and sync.  Cf. srd and bin/ff.
* Log in to Google accounts.
* Copy firefox alias files, which are not in git due to sensitive URLs.  (Question: could this change, since the repo is private?)
* Run signal-desktop once to authenticate.
* Connect to Claude Code and Codex CLI.
* Connect WhatsApp Web.

## Caches and Connectivity

* Run Docker builds in the favourite directories of the moment so images
  are pre-cached.
* Test ssh to p27 and jellybooks.
* Run `/usr/local/bin/speedtest` once to accept the terms and conditions.

## Background Images

Copy images to `/etc/greetd/background` and `$HOME/.desktop-images/`.
Use `swaymsg -t get_outputs` to check screen resolution before choosing
or cropping images.

## Printer

On each host for which I want to be able to print:

* Make sure the printer drivers are installed.  This should have been
  handled by my dotfiles package management.
* Make sure cups is running: `sudo service cups restart`.
* Visit `http://localhost:631/admin/` (or `http://localhost:631/` then
  "Add printer").  Choose "Discovered Network Printers: epson-wf-2965".
  Printer name is "プリンタ" or perhaps "hp-garage".
  Printer location is "ガレージ" or perhaps "hp-garage".
* In General, set double-sided to "long edge" if available.
* Note that the environment variable PRINTER is important to some things
  trying to print, especially old-school commandline things and emacs.

## Session

Log out and log back in in i3 or sway.
