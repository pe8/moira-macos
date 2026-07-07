#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

APP_VERSION="1.0.0"
SWT_JAR="swt-cocoa-macosx-x86_64-3.126.0.jar"
LEGACY_JAR="eclipse-legacy-support.jar"
JRE_HOME="${MOIRA_INTEL_JRE_HOME:-$ROOT/runtime/jdk-17-x64/Contents/Home}"
RELEASE_DIR="$ROOT/release"
APP="$RELEASE_DIR/Moira-intel.app"
CONTENTS="$APP/Contents"
APP_DIR="$CONTENTS/Resources/app"
BUILD_DIR="$ROOT/build/package-intel"

for required in "$ROOT/lib/$SWT_JAR" "$ROOT/lib/$LEGACY_JAR" "$JRE_HOME/bin/java"; do
  if [[ ! -e "$required" ]]; then
    echo "Missing packaging dependency: $required" >&2
    exit 1
  fi
done

"$ROOT/scripts/build.sh"

rm -rf "$APP" "$BUILD_DIR"
mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources" "$APP_DIR/lib" "$BUILD_DIR"

cp -R "$ROOT/dist"/. "$APP_DIR"/
rm -rf "$APP_DIR/lib"
mkdir -p "$APP_DIR/lib"
cp "$ROOT/lib/$SWT_JAR" "$APP_DIR/lib/"
cp "$ROOT/lib/$LEGACY_JAR" "$APP_DIR/lib/"

make_icon() {
  local source="$ROOT/resources/moira@2x.png"
  local iconset="$BUILD_DIR/Moira.iconset"
  local icns="$BUILD_DIR/moira.icns"

  if [[ ! -f "$source" ]] || ! command -v sips >/dev/null 2>&1 || ! command -v iconutil >/dev/null 2>&1; then
    return 0
  fi

  rm -rf "$iconset"
  mkdir -p "$iconset"
  sips -z 16 16 "$source" --out "$iconset/icon_16x16.png" >/dev/null
  sips -z 32 32 "$source" --out "$iconset/icon_16x16@2x.png" >/dev/null
  sips -z 32 32 "$source" --out "$iconset/icon_32x32.png" >/dev/null
  sips -z 64 64 "$source" --out "$iconset/icon_32x32@2x.png" >/dev/null
  sips -z 128 128 "$source" --out "$iconset/icon_128x128.png" >/dev/null
  sips -z 256 256 "$source" --out "$iconset/icon_128x128@2x.png" >/dev/null
  sips -z 256 256 "$source" --out "$iconset/icon_256x256.png" >/dev/null
  sips -z 512 512 "$source" --out "$iconset/icon_256x256@2x.png" >/dev/null
  sips -z 512 512 "$source" --out "$iconset/icon_512x512.png" >/dev/null
  sips -z 1024 1024 "$source" --out "$iconset/icon_512x512@2x.png" >/dev/null
  iconutil -c icns "$iconset" -o "$icns" >/dev/null
  cp "$icns" "$CONTENTS/Resources/moira.icns"
}

cat > "$CONTENTS/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>zh_CN</string>
  <key>CFBundleDisplayName</key>
  <string>Moira Intel</string>
  <key>CFBundleExecutable</key>
  <string>Moira</string>
  <key>CFBundleIconFile</key>
  <string>moira</string>
  <key>CFBundleIdentifier</key>
  <string>org.athomeprojects.moira.intel</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>Moira Intel</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$APP_VERSION</string>
  <key>CFBundleVersion</key>
  <string>$APP_VERSION</string>
  <key>LSMinimumSystemVersion</key>
  <string>10.13</string>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
EOF

cat > "$CONTENTS/MacOS/Moira" <<EOF
#!/usr/bin/env bash
set -euo pipefail

APP_ROOT="\$(cd "\$(dirname "\$0")/.." && pwd)"
APP_DIR="\$APP_ROOT/Resources/app"
JAVA_BIN="\$APP_ROOT/Resources/jre/Contents/Home/bin/java"
SWT_JAR="\$APP_DIR/lib/$SWT_JAR"
LEGACY_JAR="\$APP_DIR/lib/$LEGACY_JAR"

if [[ "\${1:-}" == "--print-command" ]]; then
  printf '%q ' "\$JAVA_BIN" "-XstartOnFirstThread" "-Xmixed" "-Xdock:name=Moira" "-cp" "\$APP_DIR/moira.jar:\$SWT_JAR:\$LEGACY_JAR" "org.athomeprojects.moira.Moira" "\$APP_DIR"
  printf '\n'
  exit 0
fi

exec "\$JAVA_BIN" -XstartOnFirstThread -Xmixed -Xdock:name=Moira -cp "\$APP_DIR/moira.jar:\$SWT_JAR:\$LEGACY_JAR" org.athomeprojects.moira.Moira "\$APP_DIR" "\$@"
EOF
chmod +x "$CONTENTS/MacOS/Moira"

make_icon

mkdir -p "$CONTENTS/Resources/jre/Contents"
ditto "$JRE_HOME" "$CONTENTS/Resources/jre/Contents/Home"
rm -rf "$CONTENTS/Resources/jre/Contents/Home/man" "$CONTENTS/Resources/jre/Contents/Home/legal"
rm -rf "$CONTENTS/Resources/jre/Contents/Home/lib/src.zip"

if command -v xattr >/dev/null 2>&1; then
  xattr -cr "$APP"
fi
if command -v codesign >/dev/null 2>&1; then
  codesign --force --deep --sign - "$APP" >/dev/null
fi

if command -v ditto >/dev/null 2>&1; then
  ditto -c -k --sequesterRsrc --keepParent "$APP" "$RELEASE_DIR/Moira-intel-java17-swt3126.zip"
fi

echo "Packaged:"
echo "  $APP"
echo "  $RELEASE_DIR/Moira-intel-java17-swt3126.zip"
