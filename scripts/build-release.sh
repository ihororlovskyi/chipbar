#!/usr/bin/env sh
set -e

VERSION="${1:?usage: build-release.sh <version>}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT/build"
ARCHIVE="$BUILD_DIR/sysbar.xcarchive"
EXPORT_DIR="$BUILD_DIR/export"
ZIP="$BUILD_DIR/sysbar-$VERSION.zip"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

xcodebuild \
  -project "$ROOT/sysbar.xcodeproj" \
  -scheme sysbar \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -archivePath "$ARCHIVE" \
  MARKETING_VERSION="$VERSION" \
  CURRENT_PROJECT_VERSION="$VERSION" \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  archive

xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportPath "$EXPORT_DIR" \
  -exportOptionsPlist "$ROOT/scripts/ExportOptions.plist"

APP="$EXPORT_DIR/sysbar.app"

# Stamp the release date before signing — editing Info.plist afterwards breaks
# the signature.
RELEASE_DATE=$(date -u +%Y-%m-%d)
/usr/libexec/PlistBuddy -c "Set :SysbarReleaseDate $RELEASE_DATE" "$APP/Contents/Info.plist"

codesign --force --deep --sign - "$APP"

ditto -c -k --keepParent "$APP" "$ZIP"
SHA=$(shasum -a 256 "$ZIP" | awk '{print $1}')

echo "VERSION=$VERSION"
echo "ZIP=$ZIP"
echo "SHA256=$SHA"
