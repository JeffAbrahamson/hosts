#!/bin/bash
set -euo pipefail

# Set up greetd with the wlgreet greeter under sway, and make greetd the
# display manager.  2604-LTS.sh calls this; it's also safe to re-run by
# hand after editing the config here.
#
# Our config lives in files no package owns: /etc/greetd/local/ and a
# systemd drop-in that points greetd at it.  The packaged conffiles in
# /etc/greetd stay as shipped (and unused), so package upgrades never
# stop to ask about them.
#
# Changes take effect the next time greetd starts, normally at reboot.
# Don't restart greetd from a graphical session: that ends the session.

cd "$(dirname "$(realpath "$0")")"

local_dir=/etc/greetd/local
dropin=/etc/systemd/system/greetd.service.d/local-config.conf

for bin in /usr/sbin/greetd /usr/sbin/wlgreet /usr/bin/sway; do
    if [[ ! -x "$bin" ]]; then
        echo "$bin not found: sudo apt-get install greetd wlgreet sway" >&2
        exit 1
    fi
done

# A broken greeter config means no graphical login, so check first.
if ! sway --validate --config sway-config >/dev/null; then
    echo "greetd/sway-config doesn't validate; not installing." >&2
    exit 1
fi

# Install SRC as DEST if it differs, showing what changed.
install_if_changed() {
    local src="$1" dest="$2"
    if [[ -e "$dest" ]] && cmp -s "$src" "$dest"; then
        echo "$dest is up to date."
        return 0
    fi
    if [[ -e "$dest" ]]; then
        diff -u "$dest" "$src" || true
    fi
    sudo install -D -m 0644 "$src" "$dest"
    echo "Installed $dest."
}

# Put a package conffile back to the shipped version if it was edited
# (as earlier versions of this script did), keeping the edited copy as
# FILE.bak.  Otherwise upgrades would keep asking about it.
restore_conffile() {
    local pkg="$1" file="$2" shipped current
    shipped="$(dpkg-query -W -f='${Conffiles}\n' "$pkg" | awk -v f="$file" '$1 == f {print $2}')"
    if [[ -z "$shipped" ]]; then
        return 0
    fi
    current="$(md5sum "$file" 2>/dev/null | cut -d' ' -f1 || true)"
    if [[ "$current" == "$shipped" ]]; then
        return 0
    fi
    echo "Restoring the packaged $file (edited copy kept as $file.bak)."
    if [[ -e "$file" ]]; then
        sudo mv -f "$file" "$file.bak"
    fi
    sudo apt-get install --reinstall -y -q \
        -o Dpkg::Options::=--force-confold \
        -o Dpkg::Options::=--force-confmiss "$pkg"
    # Left by an earlier "keep your version" answer; now identical.
    if [[ -e "$file.dpkg-dist" ]] && cmp -s "$file" "$file.dpkg-dist"; then
        sudo rm -f "$file.dpkg-dist"
    fi
}

install_if_changed sway-config "$local_dir/sway-config"
install_if_changed config.toml "$local_dir/config.toml"
if ! cmp -s greetd-override.conf "$dropin" 2>/dev/null; then
    install_if_changed greetd-override.conf "$dropin"
    sudo systemctl daemon-reload
fi

restore_conffile wlgreet /etc/greetd/sway-config
restore_conffile greetd /etc/greetd/config.toml

# Earlier hosts ran a wlgreet built from source.
if [[ -e /usr/local/bin/wlgreet ]]; then
    echo "Removing the locally built /usr/local/bin/wlgreet."
    sudo rm -f /usr/local/bin/wlgreet
fi

# The greeter background: if none is set yet (missing, or an empty
# placeholder) and a desktop image is at hand, use one.  Otherwise
# leave an empty placeholder for a real image to replace later.
background=/etc/greetd/background
if [[ ! -s "$background" ]]; then
    an_image="$(find "$HOME/.desktop-images" -maxdepth 1 -type f -size +0 \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) 2>/dev/null \
        | shuf -n 1 || true)"
    if [[ -n "$an_image" ]]; then
        echo "Using $an_image as the greeter background."
        sudo install -m 0644 "$an_image" "$background"
    elif [[ ! -e "$background" ]]; then
        sudo install -D -m 0644 /dev/null "$background"
    fi
fi

if [[ "$(readlink -f /etc/systemd/system/display-manager.service)" != */greetd.service ]]; then
    sudo systemctl enable greetd.service --force
fi
if [[ "$(dpkg-query -W -f='${db:Status-Status}' gdm3 2>/dev/null)" == installed ]]; then
    sudo apt-get remove -y gdm3
fi
