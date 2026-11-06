#!/bin/bash
# Pinky's Ventures Invoices: publish an update
# 1. Download the new index.html (and sw.js if sent) into your Downloads folder
# 2. Run this script:  ./update.sh   (from this folder)
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR"

# Your Google sync link, asked once and remembered in sync-url.txt (not uploaded)
URL_FILE="$DIR/sync-url.txt"
if [ ! -s "$URL_FILE" ]; then
  read -r -p "Paste your Apps Script /exec sync link: " U
  case "$U" in https://script.google.com/macros/s/*/exec) ;; *) echo "That doesn't look like a /exec link. Nothing changed."; exit 1;; esac
  echo "$U" > "$URL_FILE"
fi
URL="$(cat "$URL_FILE")"

# Bring in new files from Downloads (moved, so old copies don't pile up as "index (1).html")
GOT=0
for f in index.html sw.js manifest.webmanifest; do
  if [ -f "$HOME/Downloads/$f" ]; then mv -f "$HOME/Downloads/$f" "$DIR/$f"; echo "✓ Updated $f"; GOT=1; fi
done
[ "$GOT" = 1 ] || echo "No new files in Downloads, republishing what's here."

# Build in the sync link
sed -i '' "s#const DEFAULT_SYNC_URL = '[^']*';#const DEFAULT_SYNC_URL = '$URL';#" index.html
grep -q "const DEFAULT_SYNC_URL = '$URL';" index.html || { echo "✗ Couldn't put the sync link into index.html. Nothing published."; exit 1; }
echo "✓ Sync link built in"

# New cache name so phones pick up the new version (only when the app actually changed)
if ! git diff --quiet HEAD -- index.html manifest.webmanifest 2>/dev/null; then
  sed -i '' "s/pinkys-invoices-v[0-9]*/pinkys-invoices-v$(date +%Y%m%d%H%M)/" sw.js
  echo "✓ Phones will update on next open"
fi

git add -A
if git diff --cached --quiet; then echo "Nothing changed since last publish."; exit 0; fi
git commit -q -m "Update $(date '+%d/%m/%Y %H:%M')"
git push -q
USER_NAME="$(gh api user -q .login 2>/dev/null || echo YOUR-USERNAME)"
echo "✓ Published. Live in 1-2 minutes: https://$USER_NAME.github.io/pinkys-invoices/"
