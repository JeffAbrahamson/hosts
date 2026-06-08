#!/bin/bash
set -euo pipefail

# Install a new host from a prepared USB key.
# Run this on the new host.
#
# Usage: bash /path/to/usb/hosts/install-from-usb.sh [/path/to/usb-mount]
#
# If no argument is given, the USB path is inferred as the parent of the
# directory containing this script (i.e., one level above hosts/).

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
USB="${1:-$(dirname "$SCRIPT_DIR")}"

if [[ ! -d "${USB}/ssh-distrib" ]]; then
    echo "Error: ${USB}/ssh-distrib not found. Is $USB the correct USB mount point?" >&2
    exit 1
fi

# Set up .ssh
echo "Setting up ~/.ssh..."
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
rsync -a "${USB}/ssh-distrib/" "$HOME/.ssh/"

# Fix key file permissions
find "$HOME/.ssh" -name 'id_ed25519*' ! -name '*.pub' -exec chmod 600 {} \;
find "$HOME/.ssh" -name 'id_ed25519*.pub' -exec chmod 644 {} \;

# Copy srd (contains passphrases and other personal data)
if [[ -d "${USB}/srd" ]]; then
    echo "Copying srd..."
    rsync -a "${USB}/srd/" "$HOME/srd/"
else
    echo "Warning: ${USB}/srd not found, skipping."
fi

# Copy passphrase files so they're accessible on this host
if [[ -d "${USB}/ssh-distrib.priv" ]]; then
    mkdir -p "$HOME/.ssh-distrib.priv"
    chmod 700 "$HOME/.ssh-distrib.priv"
    rsync -a "${USB}/ssh-distrib.priv/" "$HOME/.ssh-distrib.priv/"
fi

# Copy unison configs
if [[ -d "${USB}/unison" ]]; then
    echo "Copying unison configs..."
    mkdir -p "$HOME/.unison"
    rsync -a "${USB}/unison/" "$HOME/.unison/"
else
    echo "Warning: ${USB}/unison not found, skipping."
fi

# Run main installation script
echo ""
echo "=== Starting main installation ==="
cd "${USB}/hosts/"
chmod 755 2404-LTS.sh

# Drop inherited agent/keyring state before ssh-agent creates a fresh one.
while IFS='=' read -r name _; do
    case "$name" in
        SSH*) unset "$name" ;;
    esac
done < <(env)

echo "Starting fresh ssh-agent..."
exec ssh-agent ./2404-LTS.sh
