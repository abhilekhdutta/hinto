#!/bin/bash
set -euo pipefail

# Validate release version
#
# Usage:
#   ./validate-release-version.sh 0.2.0
#
# Checks:
#   1. Version format is X.Y.Z
#   2. Info.plist CFBundleShortVersionString matches
#   3. Info.plist CFBundleVersion matches build number
#   4. CHANGELOG.md has entry for this version

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ $# -ne 1 ]; then
    echo "Usage: $0 <version>" >&2
    echo "Example: $0 0.2.0" >&2
    exit 1
fi

VERSION="$1"

echo "=== Validating release version: $VERSION ==="

# 1. Validate format (X.Y.Z)
if ! echo "$VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
    echo "::error::Invalid version format. Expected X.Y.Z (e.g., 0.2.0)" >&2
    exit 1
fi
echo "Format: OK"

# 2. Validate Info.plist CFBundleShortVersionString matches
PLIST_VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" Resources/Info.plist)
if [ "$PLIST_VERSION" != "$VERSION" ]; then
    echo "::error::Info.plist CFBundleShortVersionString ($PLIST_VERSION) doesn't match tag ($VERSION)" >&2
    exit 1
fi
echo "CFBundleShortVersionString: OK ($PLIST_VERSION)"

# 3. Validate Info.plist CFBundleVersion matches build number
EXPECTED_BUILD_NUMBER=$("$SCRIPT_DIR/version-to-build-number.sh" "$VERSION")
PLIST_BUILD=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" Resources/Info.plist)
if [ "$PLIST_BUILD" != "$EXPECTED_BUILD_NUMBER" ]; then
    echo "::error::Info.plist CFBundleVersion ($PLIST_BUILD) doesn't match expected build number ($EXPECTED_BUILD_NUMBER). Update Info.plist: <key>CFBundleVersion</key><string>$EXPECTED_BUILD_NUMBER</string>" >&2
    exit 1
fi
echo "CFBundleVersion: OK ($PLIST_BUILD)"

# 4. Validate CHANGELOG.md has entry for this version
if ! grep -q "^## \[$VERSION\]" Resources/CHANGELOG.md; then
    echo "::error::CHANGELOG.md missing entry for version $VERSION" >&2
    exit 1
fi
echo "CHANGELOG.md: OK (found [$VERSION])"

echo "=== Validation passed ==="
