
#!/usr/bin/env bash
set -Eeuo pipefail

REPO="$HOME/my-dotfiles"
CONFIG="$HOME/.config"
BACKUP="$HOME/proxima-backup-$(date +%Y%m%d-%H%M%S)"
FONT_DIR="$HOME/.local/share/fonts/JetBrainsMono"
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
WALLPAPER="$WALLPAPER_DIR/proxima-centauri-b.jpg"

echo "=== Proxima Linux Mint installer ==="

# 1. Install required applications
echo "=== Installing applications ==="
sudo apt update
sudo apt install -y \
    git curl tar xz-utils fontconfig \
    polybar rofi alacritty \
    network-manager-gnome blueman \
    pavucontrol pulseaudio-utils \
    libnotify-bin

# 2. Clone or update the repository
echo "=== Downloading dotfiles ==="
if [[ -d "$REPO/.git" ]]; then
    git -C "$REPO" pull --ff-only
elif [[ -e "$REPO" ]]; then
    echo "ERROR: $REPO exists but is not a Git repository."
    echo "Move it aside before installing."
    exit 1
else
    git clone https://github.com/jacvtilburg/proxima.git "$REPO"
fi

# 3. Back up existing configuration
echo "=== Backing up existing configuration ==="
mkdir -p "$BACKUP" "$CONFIG"

if command -v dconf >/dev/null 2>&1; then
    dconf dump /org/cinnamon/ > "$BACKUP/cinnamon-settings.ini"
fi

for file in .bashrc .profile; do
    if [[ -e "$HOME/$file" ]]; then
        cp -a "$HOME/$file" "$BACKUP/"
    fi
done

for source in "$REPO/.config/"*; do
    [[ -e "$source" || -L "$source" ]] || continue
    name="$(basename "$source")"
    target="$CONFIG/$name"

    if [[ -e "$target" || -L "$target" ]]; then
        mkdir -p "$BACKUP/.config"
        cp -a "$target" "$BACKUP/.config/"
    fi
done

# 4. Restore repository configurations
echo "=== Restoring Proxima configuration ==="
cp -a "$REPO/.config/." "$CONFIG/"

for file in .bashrc .profile; do
    if [[ -f "$REPO/$file" ]]; then
        cp -f "$REPO/$file" "$HOME/$file"
    fi
done

# 5. Install JetBrainsMono Nerd Font
echo "=== Installing JetBrainsMono Nerd Font ==="
mkdir -p "$FONT_DIR"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

curl -fL \
    https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz \
    -o "$TMP_DIR/JetBrainsMono.tar.xz"

tar -xf "$TMP_DIR/JetBrainsMono.tar.xz" -C "$FONT_DIR"
fc-cache -f

# 6. Install Proxima Centauri wallpaper
echo "=== Installing wallpaper ==="
mkdir -p "$WALLPAPER_DIR"

curl -fL \
    "https://upload.wikimedia.org/wikipedia/commons/a/ae/Artist%27s_impression_of_the_planet_orbiting_Proxima_Centauri.jpg" \
    -o "$WALLPAPER"

# 7. Make Polybar scripts executable
echo "=== Preparing Polybar scripts ==="
if [[ -d "$CONFIG/polybar/scripts" ]]; then
    find "$CONFIG/polybar/scripts" -type f -name '*.sh' \
        -exec chmod +x {} +
fi

# 8. Create persistent Polybar launcher
echo "=== Configuring Polybar ==="
mkdir -p "$CONFIG/autostart" "$HOME/.cache"

cat > "$CONFIG/polybar/launch.sh" <<'LAUNCH'
#!/usr/bin/env bash
set -u

pkill -x polybar 2>/dev/null || true
sleep 1

exec polybar -c "$HOME/.config/polybar/config.ini" proxima \
    >> "$HOME/.cache/proxima-polybar.log" 2>&1
LAUNCH

chmod +x "$CONFIG/polybar/launch.sh"

cat > "$CONFIG/autostart/polybar.desktop" <<AUTOSTART
[Desktop Entry]
Type=Application
Name=Proxima Polybar
Comment=Start the Proxima status bar
Exec=$HOME/.config/polybar/launch.sh
Terminal=false
X-GNOME-Autostart-enabled=true
AUTOSTART

# 9. Apply saved Cinnamon settings
echo "=== Applying Cinnamon settings ==="
if [[ -f "$REPO/cinnamon-settings.ini" ]] && command -v dconf >/dev/null 2>&1; then
    dconf load /org/cinnamon/ < "$REPO/cinnamon-settings.ini"
fi

# Set wallpaper AFTER importing Cinnamon settings
if command -v gsettings >/dev/null 2>&1; then
    if gsettings list-keys org.cinnamon.desktop.background | grep -qx picture-uri; then
        gsettings set org.cinnamon.desktop.background picture-uri "file://$WALLPAPER"
    fi

    if gsettings list-keys org.cinnamon.desktop.background | grep -qx picture-options; then
        gsettings set org.cinnamon.desktop.background picture-options 'zoom'
    fi
fi

echo
echo "=== Proxima installation complete ==="
echo "Configuration backup: $BACKUP"
echo "Wallpaper: $WALLPAPER"
echo "Polybar log: $HOME/.cache/proxima-polybar.log"
echo "Log out and back in to test the complete desktop."
