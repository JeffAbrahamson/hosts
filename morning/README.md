Machine up instructions

- At OS install time, use pwgen to create my login password and LVM passphrase.

- sudo apt-get install -y  git rxvt-unicode i3 emacs
  sudo apt-get install -y  xautolock sshfs redshift feh mplayer unison
  sudo apt-get install -y  auctex net-tools scrot w3m gnuplot gnuplot-doc
  sudo apt-get install -y  texlive-xetex texlive-lang-cjk texlive-latex-recommended
  sudo apt-get install -y  texlive-latex-extra texlive-lang-japanese pandoc
  sudo apt-get install -y  mutt sysvbanner python3-pip python3-virtualenv
  sudo apt-get install -y  imagemagick ncal ipython3 gimp libpq-dev gcc
  sudo apt-get install -y  sqlite3 python3-git python3-matplotlib
  sudo apt-get install -y  texlive-science texlive-science-doc
  sudo apt-get install -y  texlive-extra-utils make-doc vagrant
  sudo apt-get install -y  texlive-lang-french texlive-fonts-extra
  sudo apt-get install -y  gnucash gnucash-common gnucash-docs python3-gnucash libdbd-sqlite3
  sudo apt-get install -y  fbreader bookworm gnome-books mupdf mupdf-tools
  sudo apt-get install -y  okular okular-extra-backends
  sudo apt-get install -y  python3-sklearn python3-sklearn-lib python3-sklearn-pandas
  sudo apt-get install -y  python-sklearn-doc
  sudo apt-get install -y  jhead exiftran
- fetch initial git repos manually
    git clone https://github.com/JeffAbrahamson/dotfiles.git
    git clone https://github.com/JeffAbrahamson/hosts.git
    (I'm doing this via https, so this can as easily be in /tmp)
- install dotfiles
- logout, login in with i3
- create a new ssh key to talk to my other hosts

    ssh-keygen -t ed25519 -a 100
    (use rpass)

- Copy the public key manually via usb key to other hosts,
  append it to ~/.ssh/authorized_hosts

- fs-mount and copy unison configs
- I probably need to debug light.  Cf light -U 5 -v 1

- Create ssh key pairs for github, p27, and jellybooks.
- Add public keys to github profile, to salt config for p27 hosts, and to salt config for jbks hosts




ssh key:

UHnv0jfWDCi1iAX0qOGdL7hWOrpl3eh6rAU6q2TRx4UfzIlM7mfRhKyXR4IohnJGUAc3qyyi
Your identification has been saved in /home/jeff/.ssh/id_ed25519
Your public key has been saved in /home/jeff/.ssh/id_ed25519.pub
The key fingerprint is:
SHA256:Kp7y9yzhT+9WUxvDV8BA8tuBYad8H2SwkOVF9YQiY0M jeff@morning
The key's randomart image is:
+--[ED25519 256]--+
|         .EoB==B+|
|          =*+=B.o|
|         . +==o.o|
|             +=oo|
|        S   ...=.|
|      ..    o .  |
|    .....  . .   |
|  .. o+o ..      |
|   o+. ++oo      |
+----[SHA256]-----+


github key:

rFdvWjnHbiq5LAdk7lrxIr/LJ8QcCS96WchhHFnFfVWSPbsqXKP44kmscEnozVNgdafJeg==
SHA256:w7aNVoYJDEQWGofoAmITusKLmal4hdp/mzMQxZKoJLA jeff@morning
The key's randomart image is:
+--[ED25519 256]--+
|ooo=B+           |
|*=o=ooo          |
|E.o  oo          |
|+o  .  o o       |
|+. . .  S o      |
|o+o o  . B       |
|=+ . .  + .      |
|+ o   +o         |
|o. ...o+         |
+----[SHA256]-----+

p27 key:

MDUvGV618cb52+NoHlvxBPAk9sxUhtW7BBOJAD/aBj0hW/zYOla1yFomLTv2e3x1jLvRxA==
SHA256:4AQpueVFBaInXu0P7la8kNZ+mmpZRHhNa8U1YWEaqhU jeff@morning
The key's randomart image is:
+--[ED25519 256]--+
|   .ooo+.oE.o.Bo |
|  o.o+o o .=.= . |
|  o=o.+o  = .    |
| ..+.+ ..+       |
|  .   +=S        |
|     .+o=        |
|     ..*..       |
|     .+ o..      |
|     oo.oo       |
+----[SHA256]-----+


jbks key:
IvWpzj2xfDm1CHGalCmMFs9LcwqIUFap8KZ5KGr1GhHDzsk2pnq1ip2Q
SHA256:5pnT5Al/gLB2xkmDmmDrHP93DYZhgA9oBPQB/zwnqqM jeff@morning
The key's randomart image is:
+--[ED25519 256]--+
|o=oo .           |
|  = + ..         |
| .oo oo.o        |
| . ooo.=o+       |
|  o o=ooSoo      |
| o o..+=.Ooo     |
|  o..   =.=o.    |
| ..  .  .....    |
|E..   .. .       |
+----[SHA256]-----+


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

I probably want desktop images, but this ultimately depends on screen
size.  A quick fix is to grab from another host until I set up the
right images with the right size.

  rsync -a siegfried:/jma-4t/jeff/machines/starshine/.desktop-images  .

Fix ssh-agent startup if bug still exists.
  https://bugs.launchpad.net/ubuntu/+source/xorg/+bug/1922414

  The issue on ubuntu 21.10 seems to be gdm depending on
  gnome-specific facilities like gnome-keyright and, for reasons I
  don´t quite understand, skipping starting ssh-agent.

  The solution I found, in any case, was to uninstall gdm3 and
  gnome-screensaver and install instead lightdm.  This required
  (systemctl) stopping the gdm3 and starting lightdm.

Make sure sleep works.  Or make sleep work.

# Let me dim the screen.  Cf. error from  `light -v 1 -U 5`
sudo adduser jeff video

# For fs-mount
mkdir fs
ln -s fs/files files

# Checkredshift works / if GeoClue has location access
# Check that notify-send works

# Install apps from git (from ~/src/):
#   glow, speedtest, cedilla
sudo apt-get install clisp

# Compile srd  (cf. README.packages)
sudo apt-get install -y  make clang protobuf-compiler g++ g++-doc
sudo apt-get install -y  libpstreams-dev libbz2-dev libcrypto++-dev
sudo apt-get install -y  libprotobuf-dev libboost-all-dev
sudo apt-get install -y  libcrypto++-dev libcrypto++-doc libcrypto++-utils

# Create firefox profiles and setup sync.
#   As of today, that jeff, jellybooks, TN, velopolitain, dieu.
#   Setup sync (jeff, jellybooks, TN), enter primary password.
#   Sign-in to google account.
#   Pin tabs (jeff, jellybooks, TN): google contacts, calendar, mail.

# Setup thunderbird
  -> setup accounts: jeff@p27.eu, jeff@mobilitains.fr, jeff.abrahamson@univ-nantes.fr

# Setup slack  (may require logout/login after binary install)
# Setup signal-desktop
# Setup whatsapp web
# Setup vagrant
  -> sudo apt-get install -y  vagrant
  -> sudo apt-get install -y  virtualbox

# setup tsd
  "make install" and ln -s data/tsd tsd
  git mod: make install should copy bash fns, should ln if needed

Remaining:
  - virtualbox
  - i3bar, i3-power-monitor
  - understand keyboard input