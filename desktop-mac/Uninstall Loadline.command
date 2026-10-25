#!/bin/bash
# Removes Loadline APS from this Mac. Your data in the browser is not deleted.
curl -s -m 2 http://localhost:8765/__stop >/dev/null 2>&1
AGENT="$HOME/Library/LaunchAgents/com.loadline.aps.server.plist"
[ -f "$AGENT" ] && { launchctl unload "$AGENT" 2>/dev/null; rm -f "$AGENT"; }
rm -rf "$HOME/Applications/Loadline APS.app" "$HOME/Library/Application Support/Loadline"
rm -f "$HOME/Desktop/Loadline APS"
echo; echo "  Loadline APS has been removed. If it is still in the Dock, drag it out."; echo
