#!/bin/zsh
set -euo pipefail

if [[ -z "${DEVELOPER_DIR:-}" && -d "/Applications/Xcode.app/Contents/Developer" ]]; then
    export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
fi

ROOT="${0:A:h:h}"
APP_NAME="Classic Launchpad"
APP_VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$ROOT/Resources/Info.plist")"
if (( $# > 0 )); then
    print -u2 "Usage: ./scripts/package-app.sh"
    exit 64
fi

APP_DIR="$ROOT/dist/$APP_NAME.app"
ARCHIVE="$ROOT/dist/Classic-Launchpad-$APP_VERSION-arm64.zip"
CONTENTS="$APP_DIR/Contents"
ICONSET="$ROOT/.build/AppIcon.iconset"

cd "$ROOT"
swift build -c release --arch arm64
BUILD_DIR="$(swift build -c release --arch arm64 --show-bin-path)"

rm -rf "$APP_DIR" "$ICONSET"
mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources" "$CONTENTS/Frameworks" "$ICONSET" "$ROOT/dist"

cp "$BUILD_DIR/ClassicLaunchpad" "$CONTENTS/MacOS/ClassicLaunchpad"
cp "$ROOT/Resources/Info.plist" "$CONTENTS/Info.plist"
cp -R "$BUILD_DIR/OpenMultitouchSupportXCF.framework" "$CONTENTS/Frameworks/"
install_name_tool -add_rpath "@executable_path/../Frameworks" "$CONTENTS/MacOS/ClassicLaunchpad"

swift "$ROOT/Tools/GenerateIcon.swift" "$ROOT/.build/AppIcon-1024.png"
for size in 16 32 128 256 512; do
    sips -z "$size" "$size" "$ROOT/.build/AppIcon-1024.png" --out "$ICONSET/icon_${size}x${size}.png" >/dev/null
    double=$((size * 2))
    sips -z "$double" "$double" "$ROOT/.build/AppIcon-1024.png" --out "$ICONSET/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$CONTENTS/Resources/AppIcon.icns"

codesign --force --deep --sign - "$APP_DIR"

ditto -c -k --sequesterRsrc --keepParent "$APP_DIR" "$ARCHIVE"
echo "$ARCHIVE"
echo "$APP_DIR"
