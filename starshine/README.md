This document describes what I did to set up starshine, my Dell
Precision m3800 laptop.  Some of this is specific to me, but quite a
lot is likely relevant to anyone running ubuntu on a Dell m3800 and/or
on a HiDPI screen.


# Set up my environment

## ssh-keygen

Create keys for personal (`id_rsa`), github (`id_rsa.github`),
Jellybooks (`id_rsa.jellybooks`), and purple (`id_rsa.purple`).

Distribute them as needed.

* Personal key on all of my home machines
* Github key to github
* Jellybooks key on Jellybooks hosts (via puppet commit)
* Purple key to purple hosts (fog, blog)

## Set up my favourite git repositories

    cd
    mkdir -p src/jma
    cd src/jma
    git clone git@github.com:JeffAbrahamson/dotfiles.git
    cd dotfiles
    ./install

    cd $HOME/src/jma
    git clone git@github.com:JeffAbrahamson/srd.git
    cd srd/src
    make
    cp srd $HOME/bin

    (cd $HOME/src/jma; git clone talks)
    (cd $HOME/src/jma; git clone recipes)
    (cd $HOME/src/jma; git clone hosts)
    (cd $HOME/src/jma; git clone purple)
    (cd $HOME/src/jma; git clone pic-tools && cd pic-tools && ./install)
    (cd $HOME/src/jma; git clone pedagogy)
    (cd $HOME/src/jma; git clone gtd)
    (cd $HOME/src/jma; git clone tsd && cd tsd && cp tsd.py $HOME/bin/)
    (cd $HOME/src/jma; git clone jeffabrahamson.github.com)
    (cd $HOME/src/jma; git clone orange-butterfly)

    cd $HOME/src; mkdir jellybooks


# Run a modern i3 and keep it that way.

Cf. http://i3wm.org/docs/repositories.html

    echo "deb http://debian.sur5r.net/i3/ $(lsb_release -c -s) universe" >> /etc/apt/sources.list
    apt-get update
    apt-get --allow-unauthenticated install sur5r-keyring
    apt-get update
    apt-get install i3


# Tell X apps that this is a HiDPI display.

Check that `dotfiles/X11/install.sh` knows about this host.  It should
provide the following changes for me:

* Change Xft.dpi: from 96 to 192 in .Xresources.
* Change urxvt font size: from `9x15` to `urxvt.font: xft:DejaVuSansMono:size=10`

firefox needs to be told that this is a HiDPI display.  Go to
`about:config` and change:

* layout.css.devPixelsPerPx from 1 to 2

Some tips for gtk themes are here (I didn't follow them):
  http://vincent.jousse.org/tech/archlinux-retina-hidpi-macbookpro-xmonad/

If I should need to manually tell i3 that I have a HiDPI display, type
this:

    xrandr --dpi 192 && i3-msg restart

This should happen automatically at reboot.  The following can help
diagnose problems:

    xdpyinfo | grep resolution


# Wifi

Wifi doesn't work with the default ubuntu (15.10) install.

    sudo apt-get install bcmwl-kernel-source
    sudo modprobe wl

Thanks to
[this](http://askubuntu.com/questions/590442/how-can-i-install-broadcom-wireless-adapter-bcm4352-802-11ac-pcid-14e443b1-r)
for that tip.

I turn wifi back on after suspend in `i3-lock-suspend`
(`dotfiles/i3`).


# Function keys.

The function keys are inverted (need to hit "fn" prefix to use
function keys).  This isn't what I want as a programmer.

I can change this for my session by touching the function lock key
(ESC without Fn), but that's not durable across reboot.

There is a bios setting that fixes this permanently.


# Middle mouse button

I set `synclient TapButton3=2` in `dotfiles/X11/xsessionrc`.  It needs
to know to switch based on this hostname.


# Using page-up and page-down on the keyboard.

In consumer (non-programmer) apps, Fn and page-up/page-down works
fine.

* In bash, use `C-S-Fn up/down`
* To change tabs in my browser, use `C-Fn up/down`.  It is important
  to touch Ctrl before Fn.
* To reorder tabs in my browser, use `C-S-page up/down`.  It is important
  to touch Fn after Ctrl + Shift.


# Touchscreen

I use touchegg for the touchscreen.  The configuration lives in
`dotfiles/touchegg/`.  Manual pages live at
[AllGestures](https://code.google.com/p/touchegg/wiki/AllGestures) and
[AllActions](https://code.google.com/p/touchegg/wiki/AllActions).


# Font size in dmenu

Note that some older StackOverflow posts suggested patching dmenu.
This is no longer needed.

I set a pango font in the dmenu invocation in dotfiles/i3/i3/config.
Note that the space between the flag and the font name is mandatory
but its absence doesn't produce an error message.


# Notify

Remove notify-osd (installed by default by ubuntu) and run dunst instead.
At issue is that notify-osd doesn't provide multiple notifications, so
I potentially miss things.

I start dunst against my config to get decent font size.  I install my
dunst config from `dotfiles/i3`.  It installs to
`$HOME/.config/dunst/dunstrc`.


# Apps

* Log in to firefox (firefox sync).  Tell srd of new password.


# Things left to sort

* The mouse cursor is too small
* The battery status does not show in i3-bar
* The machine won't hibernate.  Worse, a (bios?) bug caused it to
  crash on suspend after a month or so of use.  Others report this,
  also (that suspend works for a few weeks only).  There's some report
  that this may be fixable with a newer bios version from Dell.
  Dell's bios are reported buggy.
* Maybe I can better automate LUKS mounting of `/home2`.
  [This](https://askubuntu.com/questions/711582/second-hard-drive-encrypted-luks-but-mounts-separately)
  StackOverflow question addresses the issue a bit.  The big question
  is whether I can auto-detect the drive letter, since I have a bash
  function `mluks-images` to mount `/home2` for me (since my `/home2`
  stores my photographic images.
* Make the SD card reader work.  There's some possibly useful
  information [here](https://askubuntu.com/questions/713408/realtek-5249-card-reader-not-working-dell-m3800-precision).
* The console is unreadably small.
* Make the automounter work (a general i3 issue, in which the i3
  developers are technically correct (that this is not an i3 issue)
  while making every i3 user spend time sorting this.  Cf. [here](https://askubuntu.com/questions/331968/recommended-auto-mounter-for-tiling-window-managers)
  for some remarks on the myriad choices available.
* Figure out how to attach to a second and non-HiDPI display (projector)
