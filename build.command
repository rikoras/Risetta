#!/bin/bash
cd "$(dirname "$0")"
xattr -dr com.apple.quarantine "$0" 2>/dev/null || true
bash build.sh
