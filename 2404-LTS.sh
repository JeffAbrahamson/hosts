#!/bin/bash

# This script is used to generate the list of files to be installed on
# the new 24.04 host.
#
# Ahead of time, I should prepare ssh keys and deploy them.  Then load
# them on the new host using a USB key.  This script should run under
# an ssh agent.
#
# Cf. README.md.

echo "Installing packages."
for pkg in $(cat 2404-LTS.pkg); do
    sudo apt-get install -y -q "$pkg"
done
echo "Installing snaps."
sudo snap install node --classic
for pkg in chromium firefox glow gron signal-desktop; do
	sudo snap install $pkg
done
echo "Finished installing packages and snaps."



echo "Now installing dotfiles and source code."
mkdir "$HOME/bin"
mkdir "$HOME/data"
mkdir -p "$HOME/src/jma"
for repo in $(cat 2204-LTS.jma-git); do
    (cd "$HOME/src/jma"; git clone "$repo")
done
(cd "$HOME/src/jma/dotfiles"; ./install.sh)
(cd "$HOME/src/jma/srd/src"; make && cp srd "$HOME/bin")
(cd "$HOME/src/jma/tsd"; make install; cd; ln -s data/tsd tsd)

for repo in $(cat 2204-LTS.git); do
    (cd "$HOME/src/"; git clone "$repo")
done

for repo in $(cat 2204-LTS.jellybooks-git); do
    (cd "$HOME/src/jellybooks"; git clone "$repo")
done

cd "$HOME"
mkdir fs
ln -s fs/files files

# Let me dim the screen.  Cf. error from  `light -v 1 -U 5`
sudo adduser jeff video
sudo adduser jeff docker
