#!/bin/bash
#
# publish-release.sh — publish a new Orbis release to this downloads repo.
#
# Usage:
#   ./publish-release.sh <version> <assets-dir> [notes-file]
#
# Example:
#   ./publish-release.sh 0.6.3 ~/Downloads/orbis-0.6.3 notes.md
#
# <assets-dir> must contain all three installers with these exact names:
#   Orbis-macOS-AppleSilicon-arm64.dmg
#   Orbis-macOS-Intel-x64.dmg
#   Orbis-Windows-Setup-x64.exe
# (The macOS dmgs must already be signed + notarized + stapled, and built with
#  tools-pack `--portable --signed`. This script only PUBLISHES; it does not build.)
#
# What it does:
#   1. Creates the GitHub release  vN.N.N  with all three assets.
#   2. Refreshes SHA256SUMS.txt in the repo.
#   3. Rewrites the download links in README.md + index.html to VERSION-PINNED
#      URLs (/releases/download/vN.N.N/...). This is the cache fix: the old
#      /releases/latest/download/ URL never changes between releases, so browsers
#      keep serving the previously-cached (old) installer. A version-pinned URL
#      is unique per release, so every download is fresh.
#
set -euo pipefail

VERSION="${1:?usage: publish-release.sh <version> <assets-dir> [notes-file]}"
ASSETS_DIR="${2:?usage: publish-release.sh <version> <assets-dir> [notes-file]}"
NOTES_FILE="${3:-}"
REPO="Josedesign006/Orbis-packages"
TAG="v$VERSION"

ARM="$ASSETS_DIR/Orbis-macOS-AppleSilicon-arm64.dmg"
INTEL="$ASSETS_DIR/Orbis-macOS-Intel-x64.dmg"
WIN="$ASSETS_DIR/Orbis-Windows-Setup-x64.exe"
for f in "$ARM" "$INTEL" "$WIN"; do
  [ -f "$f" ] || { echo "ERROR: missing asset: $f" >&2; exit 1; }
done

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

# 1) checksums (bare filenames, not full paths)
( cd "$ASSETS_DIR" && shasum -a 256 \
    Orbis-macOS-AppleSilicon-arm64.dmg \
    Orbis-macOS-Intel-x64.dmg \
    Orbis-Windows-Setup-x64.exe ) > "$work/SHA256SUMS.txt"

# 2) release notes (use provided file, or a generic template)
if [ -n "$NOTES_FILE" ]; then
  cp "$NOTES_FILE" "$work/notes.md"
else
  cat > "$work/notes.md" <<NOTES
Orbis $VERSION — desktop packages.

**Downloads**
- macOS Apple Silicon (arm64): \`Orbis-macOS-AppleSilicon-arm64.dmg\`
- macOS Intel (x64): \`Orbis-macOS-Intel-x64.dmg\`
- Windows (x64): \`Orbis-Windows-Setup-x64.exe\`

The macOS builds are code-signed and notarized by Apple — they install without security warnings. The Windows installer is not yet signed (SmartScreen may prompt). Verify downloads against \`SHA256SUMS.txt\`.
NOTES
fi

# 3) create the release with all three assets
echo "Creating release $TAG ..."
gh release create "$TAG" -R "$REPO" --title "Orbis $VERSION" --notes-file "$work/notes.md" \
  "$ARM" "$INTEL" "$WIN"

# helper: replace a repo file's contents via the contents API
put_file() {
  local path="$1" src="$2" msg="$3" sha
  sha=$(gh api "repos/$REPO/contents/$path" --jq '.sha')
  gh api -X PUT "repos/$REPO/contents/$path" \
    -f message="$msg" -f content="$(base64 -i "$src")" -f sha="$sha" --jq '.commit.sha' >/dev/null
}

# 4) checksums
echo "Updating SHA256SUMS.txt ..."
put_file SHA256SUMS.txt "$work/SHA256SUMS.txt" "SHA256SUMS for $TAG"

# 5) rewrite version-pinned links + visible version strings in README + site
rewrite_links() {
  local path="$1"
  gh api "repos/$REPO/contents/$path" --jq '.content' | base64 -d > "$work/in"
  sed -E \
    -e "s#releases/(latest/)?download/(v[0-9]+\.[0-9]+\.[0-9]+/)?#releases/download/$TAG/#g" \
    -e "s#latest: v[0-9]+\.[0-9]+\.[0-9]+#latest: $VERSION#g" \
    -e "s#latest version v[0-9]+\.[0-9]+\.[0-9]+#latest version $VERSION#g" \
    "$work/in" > "$work/out"
  put_file "$path" "$work/out" "Point download links to $TAG"
}
echo "Rewriting download links to $TAG ..."
rewrite_links README.md
rewrite_links index.html

echo "Done. Published $TAG with version-pinned links + checksums."
echo "https://github.com/$REPO/releases/tag/$TAG"
