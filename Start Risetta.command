#!/bin/bash
cd "$(dirname "$0")"

APP="build/Risetta.app"

if [ ! -d "$APP" ]; then
  echo "还没有构建 Risetta.app。"
  echo "请先双击 build.command，或在终端运行 bash build.sh。"
  read -n 1 -s -r -p "按任意键关闭..."
  echo
  exit 1
fi

xattr -dr com.apple.quarantine "$0" 2>/dev/null || true
xattr -dr com.apple.quarantine "$APP" 2>/dev/null || true

open "$APP"
