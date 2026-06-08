#!/bin/bash

# This script is used to generate the list of files to be installed on
# the new 24.04 host.
#
# Ahead of time, I should prepare ssh keys and deploy them.  Then load
# them on the new host using a USB key.  This script should run under
# an ssh agent.
#
# Cf. README.md.

KEYS=(id_ed25519 id_ed25519.github id_ed25519.p27 id_ed25519.jellybooks)

for key in "${KEYS[@]}"; do
    keyfile="$HOME/.ssh/${key}"
    passfile="$HOME/.ssh-distrib.priv/${key}.pass"
    if [[ ! -f "$keyfile" ]]; then
        echo "Key ${key} not found, skipping."
        continue
    fi
    echo ""
    if [[ -f "$passfile" ]]; then
        echo "Passphrase for ${key}: $(cat "$passfile")"
    else
        echo "No passphrase file found for ${key} - enter it manually."
    fi
    ssh-add "$keyfile" || exit 1
done

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
echo "Removing packages."
for pkg in $(cat 2404-LTS-remove.pkg); do
    echo " -> Removing $pkg..."
    sudo apt-get remove -y -q "$pkg"
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

echo "Installing AI coding CLIs."
npm_bin="$(command -v npm)"
if [[ -z "$npm_bin" ]]; then
    echo "npm not found after installing the node snap." >&2
    exit 1
fi
mkdir -p "$HOME/.npm-global"
"$npm_bin" config set prefix "$HOME/.npm-global" || exit 1
export PATH="$HOME/.npm-global/bin:$PATH"
"$npm_bin" install -g @anthropic-ai/claude-code @openai/codex || exit 1
command -v claude >/dev/null || { echo "claude CLI was not installed on PATH." >&2; exit 1; }
command -v codex >/dev/null || { echo "codex CLI was not installed on PATH." >&2; exit 1; }


echo "Now installing dotfiles and source code."
mkdir -p "$HOME/bin"
mkdir -p "$HOME/data"
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

mkdir -p "$HOME/src/jellybooks"
for repo in $(cat jellybooks-git); do
    echo " -> Cloning $repo..."
    (cd "$HOME/src/jellybooks"; git clone "$repo")
done

echo "Installing wlgreet."
mkdir -p "$HOME/src"
if [[ ! -d "$HOME/src/wlgreet/.git" ]]; then
    git clone https://git.sr.ht/~kennylevinsen/wlgreet "$HOME/src/wlgreet"
fi
(
    cd "$HOME/src/wlgreet"
    cargo build --release
    sudo install -m 0755 target/release/wlgreet /usr/local/bin/wlgreet
) || exit 1

cd "$HOME"
mkdir -p fs
ln -s fs/files files

echo "Creating placeholder background images."
sudo install -D -m 0644 /dev/null /etc/greetd/background
mkdir -p "$HOME/.desktop-images"
touch "$HOME/.desktop-images/empty.png"

# Let me dim the screen.  Cf. error from  `light -v 1 -U 5`
sudo adduser jeff video
sudo adduser jeff docker
