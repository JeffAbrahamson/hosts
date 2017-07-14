# hosts

Personal host config.

This is the (non-secret) part of my personal host configs, to help me
reproduce on new hosts what I've already set up here and there.  This
is highly unlikely to be useful to anyone other than me.

## Printer

On each host for which I want to be able to print, I need to do the following:

* Make sure the printer drivers are installed.  This should have been
  handled by my dotfiles package management.  My current printer wants
  hpijs-ppds in particular.
* Make sure cups is running: `sudo service cups restart`.
* Visit `http://localhost:631/admin/` (or `http://localhost:631/` then
  "Add printer").  Choose "Discovered Network Printers: HP ENVY 5540
  series [ADEC6C] (HP ENVY 5540 series)".  Printer name is "プリンタ".
  Printer location is "ガレージ".
* In General, set double-sided to "long edge".
* Note that the environment variable PRINTER is important to some
  things trying to print, especially old-school commandline things
  (and emacs).
