#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="Risetta"
BUILD_DIR="build"
APP="$BUILD_DIR/$APP_NAME.app"

if ! command -v swiftc >/dev/null 2>&1; then
  echo "未找到 swiftc。请先安装 Xcode Command Line Tools：xcode-select --install"
  exit 1
fi

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp Resources/Info.plist "$APP/Contents/Info.plist"
cp Resources/icon.icns "$APP/Contents/Resources/icon.icns"
cp Resources/noise.png "$APP/Contents/Resources/noise.png"

ARCH="$(uname -m)"
TARGET="$ARCH-apple-macos13.0"

echo "正在编译 Risetta（$ARCH）..."
swiftc -O -swift-version 5 -target "$TARGET" \
  -framework AppKit \
  -framework SwiftUI \
  -framework CryptoKit \
  -framework Security \
  Sources/*.swift \
  -o "$APP/Contents/MacOS/$APP_NAME"

chmod +x "$APP/Contents/MacOS/$APP_NAME"
printf 'APPL????' > "$APP/Contents/PkgInfo"

# Ad-hoc signature. The app is not notarized.
codesign --force --deep --sign - "$APP" >/dev/null 2>&1 || true

# The quarantine flag is added by the browser/download, not by the build.
xattr -dr com.apple.quarantine "$APP" 2>/dev/null || true

echo "已生成：$APP"
echo "首次使用请双击 Start Risetta.command；它会清除隔离标记并打开 App。"

if [[ "${1:-}" != "--no-open" ]]; then
  open "$APP"
fi
