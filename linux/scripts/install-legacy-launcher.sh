#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Legacy Launcher"
JAR_SOURCE="$HOME/Downloads/LegacyLauncher.jar"
ICON_SOURCE="$HOME/Downloads/mc.png"

INSTALL_DIR="/opt/legacy-launcher"
JAR_DEST="$INSTALL_DIR/LegacyLauncher.jar"
ICON_DEST="$INSTALL_DIR/mc.png"
DESKTOP_FILE="/usr/share/applications/legacy-launcher.desktop"

# Check files exist
[[ -f "$JAR_SOURCE" ]] || { echo "Error: $JAR_SOURCE not found."; exit 1; }
[[ -f "$ICON_SOURCE" ]] || { echo "Error: $ICON_SOURCE not found."; exit 1; }

# Check Java
if ! command -v java >/dev/null 2>&1; then
    echo "Java is not installed."
    echo "Install it with:"
    echo "sudo pacman -S jre21-openjdk"
    exit 1
fi

echo "Installing $APP_NAME..."

sudo mkdir -p "$INSTALL_DIR"

sudo mv "$JAR_SOURCE" "$JAR_DEST"
sudo mv "$ICON_SOURCE" "$ICON_DEST"

sudo chmod 644 "$JAR_DEST"
sudo chmod 644 "$ICON_DEST"

sudo tee "$DESKTOP_FILE" >/dev/null <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Legacy Launcher
Comment=Minecraft Legacy Launcher
Exec=java -jar $JAR_DEST
Icon=$ICON_DEST
Terminal=false
Categories=Game;
StartupNotify=true
EOF

sudo chmod 644 "$DESKTOP_FILE"

if command -v update-desktop-database >/dev/null 2>&1; then
    sudo update-desktop-database /usr/share/applications >/dev/null 2>&1 || true
fi

echo
echo "Installation complete!"
echo "You can now launch 'Legacy Launcher' from your application menu."
