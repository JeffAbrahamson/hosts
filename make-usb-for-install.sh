#!/bin/bash
set -euo pipefail

# Prepare a USB key for installing a new host.
# Run this on the reference machine (where ~/srd/ and ~/.unison/ live).
#
# Usage: ./make-usb-for-install.sh /path/to/usb-mount

USB="${1:?Usage: $0 /path/to/usb-mount}"

if [[ ! -d "$USB" ]]; then
    echo "Error: $USB is not a directory" >&2
    exit 1
fi

HOSTS_DIR="$(dirname "$(realpath "$0")")"

# Create USB directory structure
mkdir -p "${USB}/ssh-distrib"
mkdir -p "${USB}/ssh-distrib.priv"
chmod 700 "${USB}/ssh-distrib.priv"

# Generate SSH keys
#
# Key names match the shell functions ssh-add (no args), ssh-github, ssh-p27, ssh-jelly.
declare -A KEY_COMMENTS=(
    [id_ed25519]="jeff@home"
    [id_ed25519.github]="jeff@github"
    [id_ed25519.p27]="jeff@p27"
    [id_ed25519.jellybooks]="jeff@jellybooks"
)
KEYS=(id_ed25519 id_ed25519.github id_ed25519.p27 id_ed25519.jellybooks)

for key in "${KEYS[@]}"; do
    keyfile="${USB}/ssh-distrib/${key}"
    passfile="${USB}/ssh-distrib.priv/${key}.pass"
    if [[ -f "$keyfile" ]]; then
        echo "Key ${key} already exists on USB, skipping generation."
        continue
    fi
    pass="$(head -c $((40 + RANDOM / 2000)) < /dev/urandom | base64)"
    echo "Generating ${key}..."
    ssh-keygen -t ed25519 -a 100 -f "$keyfile" -C "${KEY_COMMENTS[$key]}" -N "$pass"
    printf '%s\n' "$pass" > "$passfile"
    chmod 600 "$passfile"
done

# Print public keys for manual distribution
cat <<'EOF'

=== Public Keys for Distribution ===

Distribute these keys BEFORE taking the USB to the new host.
EOF

echo ""
echo "--- id_ed25519.pub  (home machines: add to ~/.ssh/authorized_keys) ---"
cat "${USB}/ssh-distrib/id_ed25519.pub"

echo ""
echo "--- id_ed25519.github.pub  (GitHub: https://github.com/settings/keys) ---"
cat "${USB}/ssh-distrib/id_ed25519.github.pub"

echo ""
echo "--- id_ed25519.p27.pub  (p27: add to Salt pillar) ---"
cat "${USB}/ssh-distrib/id_ed25519.p27.pub"

echo ""
echo "--- id_ed25519.jellybooks.pub  (Jellybooks: add to Salt pillar) ---"
cat "${USB}/ssh-distrib/id_ed25519.jellybooks.pub"

echo ""
echo "After distributing public keys, run Salt apply from an existing host"
echo "to push the new keys before moving the USB to the new host."

# Copy srd
echo ""
if [[ -d "$HOME/srd" ]]; then
    echo "Copying ~/srd/ to USB..."
    rsync -a "$HOME/srd/" "${USB}/srd/"
else
    echo "Warning: ~/srd/ not found, skipping."
fi

# Copy unison configs
if [[ -d "$HOME/.unison" ]]; then
    echo "Copying selected ~/.unison/ configs to USB..."
    mkdir -p "${USB}/unison"
    rsync -a --delete --delete-excluded \
        --include='common' --include='*.prf' --exclude='*' \
        "$HOME/.unison/" "${USB}/unison/"
else
    echo "Warning: ~/.unison/ not found, skipping."
fi

# Copy this repo
echo "Copying hosts repo to USB..."
rsync -a "${HOSTS_DIR}/" "${USB}/hosts/"

cat <<'EOF'

=== USB key is ready ===

Passphrases are in: ssh-distrib.priv/ on the USB (and should also be stored in srd).
Next steps:
  1. Distribute the public keys listed above.
  2. Run Salt apply from an existing host.
  3. Take the USB to the new host and run:
       bash /path/to/usb/hosts/install-from-usb.sh
EOF
