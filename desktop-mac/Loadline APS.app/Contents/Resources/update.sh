#!/bin/bash
# Updates the local copy from GitHub when a newer version is published on the main branch.
# The update shows the next time Loadline is opened (or after a page reload). Your data is kept: it lives in the browser.
DATA="$1"; SITE="$DATA/site"; LOG="$DATA/update.log"
REPO="lokeshnegi07-bot/LoadlineAPS"; BRANCH="main"
ver() { sed -n 's/.*"version" *: *"\([^"]*\)".*/\1/p' | head -1; }
LOCAL="$(ver < "$SITE/version.json" 2>/dev/null)"
REMOTE="$(curl -fsSL -m 10 "https://raw.githubusercontent.com/$REPO/$BRANCH/version.json?t=$(date +%s)" 2>/dev/null | ver)"
if [ -z "$REMOTE" ] || [ "$REMOTE" = "$LOCAL" ]; then exit 0; fi
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
if ! curl -fsSL -m 600 -o "$TMP/src.zip" "https://github.com/$REPO/archive/refs/heads/$BRANCH.zip" || ! unzip -q "$TMP/src.zip" -d "$TMP/x"; then
  echo "$(date '+%Y-%m-%d %H:%M') Update check skipped: download failed" >> "$LOG"; exit 0; fi
SRC="$(ls -d "$TMP"/x/*/ | head -1)"
if [ ! -f "${SRC}app/index.html" ] || [ ! -f "${SRC}version.json" ]; then echo "$(date '+%Y-%m-%d %H:%M') Update skipped: download does not look like Loadline" >> "$LOG"; exit 0; fi
for item in index.html auth.js favicon.svg version.json app media; do [ -e "${SRC}$item" ] && cp -R "${SRC}$item" "$SITE/"; done
echo "$(date '+%Y-%m-%d %H:%M') Updated from $LOCAL to $REMOTE" >> "$LOG"
