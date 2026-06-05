#!/bin/bash

# This script is used to generate the list of files to be installed on
# the new 24.04 host.
#
# Ahead of time, I should prepare ssh keys and deploy them.  Then load
# them on the new host using a USB key.  This script should run under
# an ssh agent.
#
# Cf. README.md.

echo "Adding docker package repository."
sudo apt update
sudo apt install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo cp -f docker.list /etc/apt/sources.list.d/docker.list

# Ookla speedtest: no noble package, but jammy works on noble.
echo "Adding Ookla speedtest package repository."
curl -fsSL https://packagecloud.io/ookla/speedtest-cli/gpgkey \
    | sudo gpg --dearmor -o /etc/apt/keyrings/ookla_speedtest-cli-archive-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/ookla_speedtest-cli-archive-keyring.gpg] \
https://packagecloud.io/ookla/speedtest-cli/ubuntu/ jammy main" \
    | sudo tee /etc/apt/sources.list.d/ookla_speedtest-cli.list

sudo apt update

echo "Installing packages."
for pkg in $(cat 2404-LTS.pkg); do
    echo " -> Installing $pkg..."
    sudo apt-get install -y -q "$pkg"
done

echo "Installing Ookla speedtest."
sudo apt-get install -y -q speedtest
# The wrapper script expects the binary at /usr/local/bin/speedtest.
sudo ln -sf /usr/bin/speedtest /usr/local/bin/speedtest

echo "Installing snaps."
sudo snap install node --classic
for pkg in chromium firefox glow gron signal-desktop; do
    echo " -> Installing $pkg..."
    sudo snap install $pkg
done
echo "Finished installing packages and snaps."



echo "Now installing dotfiles and source code."
mkdir "$HOME/bin"
mkdir "$HOME/data"
mkdir -p "$HOME/src/jma"
for repo in $(cat jma-git); do
    echo " -> Cloning $repo..."
    (cd "$HOME/src/jma"; git clone "$repo")
done
(cd "$HOME/src/jma/dotfiles"; ./install.sh)
(cd "$HOME/src/jma/srd/src"; make && cp srd "$HOME/bin")
(cd "$HOME/src/jma/tsd"; make install; cd; ln -s data/tsd tsd)

for repo in $(cat extra-git); do
    echo " -> Cloning $repo..."
    (cd "$HOME/src/"; git clone "$repo")
done

for repo in $(cat jellybooks-git); do
    echo " -> Cloning $repo..."
    (cd "$HOME/src/jellybooks"; git clone "$repo")
done

cd "$HOME"
mkdir fs
ln -s fs/files files

# Let me dim the screen.  Cf. error from  `light -v 1 -U 5`
sudo adduser jeff video
sudo adduser jeff docker
