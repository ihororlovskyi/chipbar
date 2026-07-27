#!/usr/bin/env bash
# Local release sanity-test: build the .app, uninstall any previous copy,
# clear the macOS icon cache, install the freshly built .app into
# /Applications, register it with LaunchServices, launch it.
#
# Does NOT touch git: no commits, no tags, no pushes. Run the git/tag
# steps manually once you are happy with what you see.
#
# Usage:  ./scripts/test-release.sh <version>      # e.g. 0.1.3

set -euo pipefail

VERSION="${1:?usage: $0 <version>   # e.g. 0.1.3}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="sysbar.app"
APP_PATH="/Applications/${APP_NAME}"
ZIP="${ROOT}/build/sysbar-${VERSION}.zip"
UNZIP_DIR="${ROOT}/build/unzip"
LSR=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister

echo "→ Building release ${VERSION}"
rm -rf "${ROOT}/build"
"${ROOT}/scripts/build-release.sh" "${VERSION}"

echo "→ Stopping running sysbar"
pkill -x sysbar || true
pkill -x Chipbar || true

echo "→ Uninstalling previous app installs (cask + /Applications)"
brew uninstall --cask sysbar 2>/dev/null || true
brew uninstall --cask chipbar 2>/dev/null || true
rm -rf /Applications/sysbar.app /Applications/Chipbar.app

echo "→ Clearing macOS icon cache (sudo)"
sudo rm -rf /Library/Caches/com.apple.iconservices.store
sudo find /private/var/folders -name com.apple.dock.iconcache -delete 2>/dev/null || true
sudo find /private/var/folders -name com.apple.iconservices -delete 2>/dev/null || true
killall Dock Finder || true

echo "→ Installing ${APP_NAME}"
rm -rf "${UNZIP_DIR}"
ditto -x -k "${ZIP}" "${UNZIP_DIR}"
cp -R "${UNZIP_DIR}/${APP_NAME}" /Applications/

echo "→ Registering with LaunchServices"
"${LSR}" -f -R "${APP_PATH}"

echo "→ Launching ${APP_NAME}"
open "${APP_PATH}"

echo
echo "✓ Done."
echo "  Verify visually:"
echo "    - Finder: open /Applications  (icon should be sysbar.app)"
echo "    - menu-bar item: click the icon, confirm 'About sysbar' opens the system panel"
echo "    - About panel: version, release date, clickable GitHub row, copyright"
echo "    - Quit row: 'Quit sysbar'"
