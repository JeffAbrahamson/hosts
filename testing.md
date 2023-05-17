# Things to check out on new hosts

Test the following functionalities:
  * eth0
  * snd
  * video (e.g., mplayer)
  * compact flash access
  * USB access

rsync from siegfried:
  - work
  - data
  - Music
  - (Video)

# Pull useful files
  rsync -a siegfried:/jma-4t/jeff/files/work  .
  rsync -a siegfried:/jma-4t/jeff/files/data  .
  rsync -a siegfried:/jma-4t/jeff/files/Music/  Music/
# Get unison working.  The first run will establish state.
  mkdir ~/.unison
  cd ~/.unison
  cp ~/fs/machines/birdsong/.unison/common .
  cp ~/fs/machines/birdsong/.unison/*prf .
  sync-data
  sync-fast
  sync-full

# Desktop images

I probably want desktop images, but this ultimately depends on screen
size.  A quick fix is to grab from another host until I set up the
right images with the right size.

  rsync -a siegfried:/jma-4t/jeff/machines/starshine/.desktop-images  .

# ssh-agent

Fix ssh-agent startup if bug still exists.
  https://bugs.launchpad.net/ubuntu/+source/xorg/+bug/1922414

  The issue on ubuntu 21.10 seems to be gdm depending on
  gnome-specific facilities like gnome-keyright and, for reasons I
  don´t quite understand, skipping starting ssh-agent.

  The solution I found, in any case, was to uninstall gdm3 and
  gnome-screensaver and install instead lightdm.  This required
  (systemctl) stopping the gdm3 and starting lightdm.

# Power management

Make sure sleep works.  Or make sleep work.
