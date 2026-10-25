#!/bin/bash
# Installs Loadline APS for this Mac user: the app goes to Applications in your home folder (no admin password needed).
cd "$(dirname "$0")"
APP="Loadline APS.app"; DEST="$HOME/Applications"; SRV="$DEST/$APP/Contents/Resources/server.pl"
DATA="$HOME/Library/Application Support/Loadline"; AGENT="$HOME/Library/LaunchAgents/com.loadline.aps.server.plist"
echo; echo "  Installing Loadline APS into $DEST"
curl -s -m 2 http://localhost:8765/__stop >/dev/null 2>&1; sleep 0.5
mkdir -p "$DEST" && rm -rf "$DEST/$APP" && cp -R "$APP" "$DEST/" || { echo "  Could not copy the app."; exit 1; }
xattr -dr com.apple.quarantine "$DEST/$APP" 2>/dev/null
ln -sfn "$DEST/$APP" "$HOME/Desktop/Loadline APS"
echo
read -r -p "  Add Loadline APS to the Dock? (y/n) " a
if [[ "$a" =~ ^[Yy] ]]; then
  defaults write com.apple.dock persistent-apps -array-add "<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>file://$DEST/Loadline%20APS.app/</string><key>_CFURLStringType</key><integer>15</integer></dict></dict></dict>"
  killall Dock 2>/dev/null
fi
read -r -p "  Start the Loadline server when you log in? (y/n) " a
if [[ "$a" =~ ^[Yy] ]]; then
  mkdir -p "$HOME/Library/LaunchAgents"
  cat > "$AGENT" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>com.loadline.aps.server</string>
  <key>ProgramArguments</key><array><string>/usr/bin/perl</string><string>$SRV</string><string>$DATA/site</string><string>8765</string></array>
  <key>RunAtLoad</key><true/>
</dict></plist>
PLIST
fi
echo; echo "  Done. Loadline APS is in Applications (in your home folder), on the Desktop and in Launchpad."
echo "  It runs at http://localhost:8765 on this Mac and updates itself from GitHub when a new version is published."
echo "  To remove it later, double-click 'Uninstall Loadline.command'."; echo
open "$DEST/$APP"
