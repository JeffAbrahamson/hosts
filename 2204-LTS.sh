#!/bin/bash

# This script is used to generate the list of files to be installed on
# the new 22.04 host.
#
# Ahead of time, I should prepare ssh keys and deploy them.  Then load
# them on the new host using a USB key.  This script should run under
# an ssh agent.
#
# Cf. README.md.

echo "Installing packages."
for pkg in $(cat 2204-LTS.pkg); do
    sudo apt-get install -y -q "$pkg"
done
echo "Installing snaps."
sudo snap install node --classic
for pkg in chromium firefox glow signal-desktop; do
	sudo snap install $pkg
done
echo "Finished installing packages and snaps."

echo "Now installing dotfiles and source code."
mkdir "$HOME/bin"
mkdir "$HOME/data"
mkdir -p "$HOME/src/jma"
cd "$HOME/src/jma"
for repo in $(cat 2204-LTS.jma-git); do
	git clone "$repo"
done
(cd dotfiles; ./install.sh)
(cd srd/src; make && cp srd "$HOME/bin")
(cd tsd; make install; cd; ln -s data/tsd tsd)

cd ..
for repo in $(cat 2204-LTS.git); do
	cd "$HOME/src/"
	git clone "$repo"
done

cd jellybooks
for repo in $(cat 2204-LTS.jellybooks-git); do
	git clone "$repo"
done

cd "$HOME"
mkdir fs
ln -s fs/files files

# Let me dim the screen.  Cf. error from  `light -v 1 -U 5`
sudo adduser jeff video
