#!/bin/bash
set -euo pipefail

# Validate release version
#
# Usage:
#   ./validate-release-version.sh 0.2.0
#
# Checks:
#   1. Version format is X.Y.Z
#   2. base.xcconfig MARKETING_VERSION matches
#   3. base.xcconfig CURRENT_PROJECT_VERSION matches build number
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

# 2. Validate base.xcconfig MARKETING_VERSION matches
XCCONFIG_VERSION=$(grep "^MARKETING_VERSION" Config/base.xcconfig | sed 's/.*= *//')
if [ "$XCCONFIG_VERSION" != "$VERSION" ]; then
    echo "::error::base.xcconfig MARKETING_VERSION ($XCCONFIG_VERSION) doesn't match tag ($VERSION)" >&2
    exit 1
fi
echo "MARKETING_VERSION: OK ($XCCONFIG_VERSION)"

# 3. Validate base.xcconfig CURRENT_PROJECT_VERSION matches build number
EXPECTED_BUILD_NUMBER=$("$SCRIPT_DIR/version-to-build-number.sh" "$VERSION")
XCCONFIG_BUILD=$(grep "^CURRENT_PROJECT_VERSION" Config/base.xcconfig | sed 's/.*= *//')
if [ "$XCCONFIG_BUILD" != "$EXPECTED_BUILD_NUMBER" ]; then
    echo "::error::base.xcconfig CURRENT_PROJECT_VERSION ($XCCONFIG_BUILD) doesn't match expected ($EXPECTED_BUILD_NUMBER). Update: CURRENT_PROJECT_VERSION = $EXPECTED_BUILD_NUMBER" >&2
    exit 1
fi
echo "CURRENT_PROJECT_VERSION: OK ($XCCONFIG_BUILD)"

# 4. Validate CHANGELOG.md has entry for this version
if ! grep -q "^## \[$VERSION\]" Resources/CHANGELOG.md; then
    echo "::error::CHANGELOG.md missing entry for version $VERSION" >&2
    exit 1
fi
echo "CHANGELOG.md: OK (found [$VERSION])"

echo "=== Validation passed ==="
