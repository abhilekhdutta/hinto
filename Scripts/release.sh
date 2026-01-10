#!/bin/bash
set -e

# Usage: ./Scripts/release.sh 0.2.0

VERSION=$1

if [ -z "$VERSION" ]; then
    echo "Usage: ./Scripts/release.sh <version>"
    echo "Example: ./Scripts/release.sh 0.2.0"
    exit 1
fi

# Load environment variables
if [ -f .env.local ]; then
    export $(grep -v '^#' .env.local | xargs)
fi

if [ -z "$APPLE_ID" ] || [ -z "$APPLE_PASSWORD" ]; then
    echo "Error: APPLE_ID and APPLE_PASSWORD must be set in .env.local"
    exit 1
fi

echo "==> Releasing v$VERSION"

# 1. Update version in xcconfig
echo "==> Updating base.xcconfig..."
BUILD_NUMBER=$(./Scripts/ci/version-to-build-number.sh "$VERSION")
sed -i '' "s/^MARKETING_VERSION = .*/MARKETING_VERSION = $VERSION/" Config/base.xcconfig
sed -i '' "s/^CURRENT_PROJECT_VERSION = .*/CURRENT_PROJECT_VERSION = $BUILD_NUMBER/" Config/base.xcconfig
echo "    Version: $VERSION (build $BUILD_NUMBER)"

# 2. Commit version bump
echo "==> Committing version bump..."
git add Config/base.xcconfig
git commit -m "Bump version to $VERSION"
git push

# 3. Build, notarize, create DMG
echo "==> Building and notarizing..."
make release

# 4. Create GitHub release
echo "==> Creating GitHub release..."
gh release create "v$VERSION" Hinto.dmg --title "Hinto v$VERSION" --generate-notes

# 5. Update website
echo "==> Updating website..."
SITE_DIR="../hinto-site"
if [ -d "$SITE_DIR" ]; then
    sed -i '' "s/const version = \"v[^\"]*\"/const version = \"v$VERSION\"/" "$SITE_DIR/src/pages/index.astro"
    cd "$SITE_DIR"
    git add -A
    git commit -m "Update to v$VERSION"
    git push
    cd -
fi

echo "==> Done! Released v$VERSION"
