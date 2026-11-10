#!/bin/bash
set -euo pipefail

# Set up a new 26.04 host: packages, snaps, npm tools, repositories and
# dotfiles.
#
# Hosts have one of two roles:
#
#   desktop  An interactive host: sway, office and graphics software,
#            Docker, AI coding tools, ssh keys, all my repositories.
#   server   A headless host (siegfried, the fileserver): command-line
#            tools, printing, dotfiles.  No X, no ssh keys or other
#            secrets (use ssh -A when needed), and repositories are
#            cloned over https.
#
# The role comes from the hostname (cf. role_for_host below); set
# HOST_ROLE=desktop or HOST_ROLE=server to override it.
#
# For a desktop, prepare ssh keys ahead of time and deploy them, then
# load them on the new host using a USB key.  This script should then
# run under an ssh agent.
#
# Safe to re-run: each step checks the current state and only changes
# what is missing.  Failures in per-item steps (one package, one repo)
# are collected and reported at the end; anything else stops the script.
#
# Cf. README.md.

cd "$(dirname "$(realpath "$0")")"

role_for_host() {
    case "$1" in
        siegfried) echo server ;;
        *) echo desktop ;;
    esac
}

HOST_ROLE="${HOST_ROLE:-$(role_for_host "$(hostname -s)")}"
case "$HOST_ROLE" in
    desktop|server) ;;
    *)
        echo "Unknown HOST_ROLE '$HOST_ROLE': expected desktop or server." >&2
        exit 1
        ;;
esac
echo "Setting up $(hostname -s) as a $HOST_ROLE host."

failures=()

# Print the entries of a list file: trimmed, skipping blank lines and
# # comments.
read_list() {
    local line
    while read -r line || [[ -n "$line" ]]; do
        if [[ -n "$line" && "$line" != \#* ]]; then
            printf '%s\n' "$line"
        fi
    done < "$1"
}

is_installed() {
    [[ "$(dpkg-query -W -f='${db:Status-Status}' "$1" 2>/dev/null)" == installed ]]
}

# Install each named package that isn't already installed, one at a
# time so that a single bad name doesn't block the rest.  If a package
# brings a new version of a conffile edited locally, keep the local
# version (as dpkg would by default) instead of stopping to ask.
apt_install_missing() {
    local pkg
    for pkg in "$@"; do
        if is_installed "$pkg"; then
            continue
        fi
        echo " -> Installing $pkg..."
        sudo apt-get install -y -q \
            -o Dpkg::Options::=--force-confdef \
            -o Dpkg::Options::=--force-confold \
            "$pkg" || failures+=("apt install $pkg")
    done
}

apt_remove_installed() {
    local pkg
    for pkg in "$@"; do
        if ! is_installed "$pkg"; then
            continue
        fi
        echo " -> Removing $pkg..."
        sudo apt-get remove -y -q "$pkg" || failures+=("apt remove $pkg")
    done
}

# Clone each repository listed in LIST_FILE into DIR, skipping any that
# are already cloned.
clone_missing() {
    local list_file="$1" dir="$2" url name
    local -a urls
    mapfile -t urls < <(read_list "$list_file")
    mkdir -p "$dir"
    for url in "${urls[@]}"; do
        name="$(basename "$url" .git)"
        if [[ -d "$dir/$name/.git" ]]; then
            echo " -> $name already cloned, skipping."
            continue
        fi
        echo " -> Cloning $url..."
        git clone "$url" "$dir/$name" || failures+=("git clone $url")
    done
}

# Make NAME a symlink to TARGET, replacing an existing symlink.  Refuse
# to replace a real file or directory: plain "ln -s" would instead
# create the link inside it.
symlink() {
    local target="$1" name="$2"
    if [[ -e "$name" && ! -L "$name" ]]; then
        echo "$name exists and is not a symlink; not replacing it." >&2
        return 1
    fi
    ln -sfn "$target" "$name"
}

load_ssh_keys() {
    local keys=(id_ed25519 id_ed25519.github id_ed25519.p27 id_ed25519.jellybooks)
    local loaded_keys key keyfile passfile fingerprint
    loaded_keys="$(ssh-add -l 2>/dev/null || true)"
    for key in "${keys[@]}"; do
        keyfile="$HOME/.ssh/${key}"
        passfile="$HOME/.ssh-distrib.priv/${key}.pass"
        if [[ ! -f "$keyfile" ]]; then
            echo "Key ${key} not found, skipping."
            continue
        fi
        fingerprint="$(ssh-keygen -lf "$keyfile" | awk '{print $2}')"
        if [[ -n "$fingerprint" && "$loaded_keys" == *"$fingerprint"* ]]; then
            echo "Key ${key} already in the agent, skipping."
            continue
        fi
        echo ""
        if [[ -f "$passfile" ]]; then
            echo "Passphrase for ${key}: $(cat "$passfile")"
        else
            echo "No passphrase file found for ${key} - enter it manually."
        fi
        ssh-add "$keyfile"
    done
}

# Docker: use Docker's own repository, as recommended at
# https://docs.docker.com/engine/install/ubuntu/ .  Ubuntu's docker.io
# lags well behind (on 26.04, Compose 2.40 vs 5.x) and conflicts with
# Docker's packages, so remove any distribution packages first.
add_docker_repository() {
    echo "Adding docker package repository."
    apt_remove_installed docker.io docker-compose docker-compose-v2 \
        docker-doc docker-buildx podman-docker containerd runc
    # An older one-line source (as left by an in-place upgrade) would
    # clash with this one's Signed-By and break apt update.
    sudo rm -f /etc/apt/sources.list.d/docker.list /etc/apt/keyrings/docker.gpg
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    sudo tee /etc/apt/sources.list.d/docker.sources >/dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
}

# Ookla speedtest: no resolute (or noble) package, but jammy works on
# resolute.
add_speedtest_repository() {
    echo "Adding Ookla speedtest package repository."
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://packagecloud.io/ookla/speedtest-cli/gpgkey \
        | sudo gpg --batch --yes --dearmor -o /etc/apt/keyrings/ookla_speedtest-cli-archive-keyring.gpg
    echo "deb [signed-by=/etc/apt/keyrings/ookla_speedtest-cli-archive-keyring.gpg] \
https://packagecloud.io/ookla/speedtest-cli/ubuntu/ jammy main" \
        | sudo tee /etc/apt/sources.list.d/ookla_speedtest-cli.list >/dev/null
    # Left by the release upgrade, which disabled the source above.
    sudo rm -f /etc/apt/sources.list.d/ookla_speedtest-cli.list.disabled
}

install_snaps() {
    echo "Installing snaps."
    if ! snap list node >/dev/null 2>&1; then
        sudo snap install node --classic
    fi
    local pkg
    for pkg in chromium firefox glow gron signal-desktop; do
        if snap list "$pkg" >/dev/null 2>&1; then
            continue
        fi
        echo " -> Installing $pkg..."
        sudo snap install "$pkg" || failures+=("snap install $pkg")
    done

    # On a refresh, snapd-desktop-integration launches the snap-store (App
    # Center) window, which is useful under GNOME but just noise under sway.
    # Without it, snapd's own session agent sends plain notifications.
    echo "Removing the GNOME snap update UI."
    for pkg in snap-store snapd-desktop-integration; do
        if snap list "$pkg" >/dev/null 2>&1; then
            sudo snap remove --purge "$pkg" || failures+=("snap remove $pkg")
        fi
    done
}

# npm install -g also upgrades what's already there, which is fine.
install_npm_tools() {
    echo "Installing npm tools."
    local npm_bin pkg cmd
    local -a packages
    npm_bin="$(command -v npm || true)"
    if [[ -z "$npm_bin" ]]; then
        echo "npm not found after installing the node snap." >&2
        exit 1
    fi
    mkdir -p "$HOME/.npm-global"
    "$npm_bin" config set prefix "$HOME/.npm-global"
    export PATH="$HOME/.npm-global/bin:$PATH"
    mapfile -t packages < <(read_list 2604-LTS-npm.pkg)
    for pkg in "${packages[@]}"; do
        echo " -> Installing $pkg..."
        "$npm_bin" install -g "$pkg" || failures+=("npm install $pkg")
    done
    for cmd in claude codex gemini mmdc; do
        command -v "$cmd" >/dev/null || failures+=("$cmd not on PATH after npm install")
    done
}

install_desktop_home() {
    install -D -m 0644 dotfiles/bash/rc_post/firefox-functions "$HOME/.dotfiles/bash/rc_post/firefox-functions"
    # srd and tsd: install only when missing.  Once installed, they're
    # updated from their own repos, where I may be mid-change.  Building
    # only the srd binary, since srd's default target also runs its full
    # test suite.  (tsd is a pipx editable install, so it follows its
    # checkout anyway.)
    if [[ ! -x "$HOME/bin/srd" ]]; then
        (cd "$HOME/src/jma/srd/src" && make srd && install -m 0755 srd "$HOME/bin/srd")
    fi
    if [[ ! -x "$HOME/.local/bin/tsd" ]]; then
        (cd "$HOME/src/jma/tsd" && make install)
    fi
    symlink data/tsd "$HOME/tsd"
    # Re-running earlier versions of this script created these inside the
    # link targets.
    local stray
    for stray in "$HOME/data/tsd/tsd:data/tsd" "$HOME/fs/files/files:fs/files"; do
        if [[ -L "${stray%%:*}" && "$(readlink "${stray%%:*}")" == "${stray#*:}" ]]; then
            rm "${stray%%:*}"
        fi
    done

    clone_missing extra-git "$HOME/src"
    clone_missing jellybooks-git "$HOME/src/jellybooks"

    mkdir -p "$HOME/fs"
    symlink fs/files "$HOME/files"

    echo "Creating placeholder desktop image."
    mkdir -p "$HOME/.desktop-images"
    if [[ ! -e "$HOME/.desktop-images/empty.png" ]]; then
        touch "$HOME/.desktop-images/empty.png"
    fi

    # Let me dim the screen.  light's udev rule makes the backlight
    # writable by group video; brightnessctl (built without logind on
    # 26.04) relies on that too.
    local me my_groups group
    me="$(id -un)"
    my_groups=" $(id -nG "$me") "
    for group in video docker; do
        if [[ "$my_groups" != *" $group "* ]]; then
            sudo adduser "$me" "$group" || failures+=("adduser $me $group")
        fi
    done
}

if [[ "$HOST_ROLE" == desktop ]]; then
    load_ssh_keys
fi

sudo apt-get update
apt_install_missing ca-certificates curl gnupg
if [[ "$HOST_ROLE" == desktop ]]; then
    add_docker_repository
fi
add_speedtest_repository
sudo apt-get update

echo "Installing packages."
mapfile -t packages < <(read_list 2604-LTS-common.pkg; read_list "2604-LTS-$HOST_ROLE.pkg")
apt_install_missing "${packages[@]}"
echo "Removing packages."
mapfile -t packages < <(read_list "2604-LTS-$HOST_ROLE-remove.pkg")
apt_remove_installed "${packages[@]}"

if [[ "$HOST_ROLE" == desktop ]]; then
    echo "Setting up the greetd login greeter."
    ./greetd/install.sh || failures+=("greetd/install.sh")
fi

echo "Installing Ookla speedtest."
apt_install_missing speedtest
# The wrapper script expects the binary at /usr/local/bin/speedtest.
sudo ln -sf /usr/bin/speedtest /usr/local/bin/speedtest

if [[ "$HOST_ROLE" == desktop ]]; then
    install_snaps
    install_npm_tools
fi
echo "Finished installing packages."

echo "Now installing dotfiles and source code."
mkdir -p "$HOME/bin"
mkdir -p "$HOME/data"
clone_missing "$HOST_ROLE-git" "$HOME/src/jma"
(cd "$HOME/src/jma/dotfiles" && make install)
if [[ "$HOST_ROLE" == desktop ]]; then
    install_desktop_home
fi

if (( ${#failures[@]} )); then
    echo "" >&2
    echo "Finished with ${#failures[@]} failure(s); fix and re-run:" >&2
    printf '  %s\n' "${failures[@]}" >&2
    exit 1
fi
echo "Finished."
