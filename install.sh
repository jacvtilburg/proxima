#!/usr/bin/env bash
set -e

REPO="$HOME/my-dotfiles"

echo "=== Installing applications ==="
sudo apt update
sudo apt install -y git gh polybar rofi alacritty

echo "=== Downloading dotfiles ==="
if [ ! -d "$REPO/.git" ]; then
    gh repo clone jacvtilburg/proxima "$REPO"
else
    git -C "$REPO" pull --ff-only
fi

echo "=== Restoring configurations ==="
mkdir -p "$HOME/.config"

# Restore saved configurations without overwriting existing files.
cp -an "$REPO/.config/." "$HOME/.config/"
cp -an "$REPO/.bashrc" "$HOME/" 2>/dev/null || true
cp -an "$REPO/.profile" "$HOME/" 2>/dev/null || true

if [ -f "$REPO/cinnamon-settings.ini" ]; then
    dconf load /org/cinnamon/ < "$REPO/cinnamon-settings.ini"
fi

echo "=== Finished ==="
echo "Review your settings and log out and back in if needed."
