#!/bin/zsh

set -euo pipefail

REPOSITORY_ROOT="/Users/brettmcm/Apps/Nearterm"
DERIVED_DATA="$REPOSITORY_ROOT/.build/DerivedData"
BUILT_APP="$DERIVED_DATA/Build/Products/Debug/Nearterm.app"
INSTALL_DIRECTORY="/Users/brettmcm/Applications"
INSTALLED_APP="$INSTALL_DIRECTORY/Nearterm.app"

xcodebuild \
    -project "$REPOSITORY_ROOT/Nearterm.xcodeproj" \
    -scheme Nearterm \
    -configuration Debug \
    -destination "platform=macOS" \
    -derivedDataPath "$DERIVED_DATA" \
    CODE_SIGNING_ALLOWED=NO \
    clean build

if [[ ! -d "$BUILT_APP" ]]; then
    print -u2 "Build succeeded but Nearterm.app was not found at $BUILT_APP"
    exit 1
fi

codesign \
    --force \
    --deep \
    --sign - \
    --entitlements "$REPOSITORY_ROOT/macOS/Nearterm.entitlements" \
    "$BUILT_APP"

mkdir -p "$INSTALL_DIRECTORY"

STAGED_APP="$(mktemp -d)/Nearterm.app"
ditto "$BUILT_APP" "$STAGED_APP"

pkill -x Nearterm 2>/dev/null || true

if [[ -e "$INSTALLED_APP" ]]; then
    rm -rf "/Users/brettmcm/Applications/Nearterm.app"
fi
mv "$STAGED_APP" "$INSTALLED_APP"

open "$INSTALLED_APP"
print "Installed and launched $INSTALLED_APP"
