#!/bin/bash
set -e
INPUT="$1"
if [ -z "$INPUT" ] || [ ! -f "$INPUT" ]; then
    echo "Usage: $0 <1024x1024.png>"
    exit 1
fi
ICONSET="AppIcon.iconset"
ICNS="AppIcon.icns"
APP_RESOURCES="LangLens.app/Contents/Resources"
rm -rf "$ICONSET"
mkdir "$ICONSET"
sips -z 16 16     "$INPUT" --out "$ICONSET/icon_16x16.png"      > /dev/null
sips -z 32 32     "$INPUT" --out "$ICONSET/icon_16x16@2x.png"   > /dev/null
sips -z 32 32     "$INPUT" --out "$ICONSET/icon_32x32.png"      > /dev/null
sips -z 64 64     "$INPUT" --out "$ICONSET/icon_32x32@2x.png"   > /dev/null
sips -z 128 128   "$INPUT" --out "$ICONSET/icon_128x128.png"    > /dev/null
sips -z 256 256   "$INPUT" --out "$ICONSET/icon_128x128@2x.png" > /dev/null
sips -z 256 256   "$INPUT" --out "$ICONSET/icon_256x256.png"    > /dev/null
sips -z 512 512   "$INPUT" --out "$ICONSET/icon_256x256@2x.png" > /dev/null
sips -z 512 512   "$INPUT" --out "$ICONSET/icon_512x512.png"    > /dev/null
sips -z 1024 1024 "$INPUT" --out "$ICONSET/icon_512x512@2x.png" > /dev/null
iconutil -c icns "$ICONSET" -o "$ICNS"
rm -rf "$ICONSET"
mkdir -p "$APP_RESOURCES"
cp "$ICNS" "$APP_RESOURCES/$ICNS"
echo "✅ $ICNS generated and copied to $APP_RESOURCES"
