#!/bin/zsh
# Builds the Mac app for a GitHub release: dist/akstats-macOS.zip, its SHA-256 checksum,
# and release notes to paste into the release page.
#
#   tools/release.sh
#
# With a "Developer ID Application" certificate (Apple Developer Program), the app is
# signed, notarized by Apple, and stapled, so it opens with no warning. One-time setup:
#   xcrun notarytool store-credentials akstats-notary \
#       --apple-id <your Apple ID> --team-id 2NQC9W6L8S --password <app-specific password>
# (make the app-specific password at account.apple.com → Sign-In and Security).
#
# Without one, the app gets an ad-hoc signature (no name or email in it) and people
# open it once with System Settings → Privacy & Security → Open Anyway.
set -euo pipefail

ROOT=${0:A:h:h}
cd "$ROOT"
TEAM=2NQC9W6L8S
NOTARY_PROFILE=${NOTARY_PROFILE:-akstats-notary}
WORK=$(mktemp -d /tmp/akstats-release.XXXXXX)
mkdir -p dist
ZIP=dist/akstats-macOS.zip
VERSION=$(sed -n 's/.*MARKETING_VERSION = \(.*\);/\1/p' akstats.xcodeproj/project.pbxproj | head -1)

if security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
    echo "→ Developer ID found: archiving, signing, and notarizing v$VERSION"
    xcodebuild -project akstats.xcodeproj -scheme akstats -configuration Release \
        -destination 'generic/platform=macOS' -archivePath "$WORK/akstats.xcarchive" \
        -allowProvisioningUpdates archive -quiet
    cat > "$WORK/ExportOptions.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key><string>developer-id</string>
    <key>teamID</key><string>$TEAM</string>
    <key>signingStyle</key><string>automatic</string>
</dict>
</plist>
EOF
    xcodebuild -exportArchive -archivePath "$WORK/akstats.xcarchive" \
        -exportOptionsPlist "$WORK/ExportOptions.plist" -exportPath "$WORK/export" \
        -allowProvisioningUpdates -quiet
    APP="$WORK/export/akstats.app"

    # Apple scans the upload and returns a ticket; stapling attaches it to the app
    ditto -c -k --keepParent "$APP" "$WORK/upload.zip"
    xcrun notarytool submit "$WORK/upload.zip" --keychain-profile "$NOTARY_PROFILE" --wait
    xcrun stapler staple "$APP"
    spctl -a -vv "$APP"
    SIGNING="signed with Developer ID and notarized by Apple"
else
    echo "→ No Developer ID certificate: building v$VERSION with an ad-hoc signature"
    xcodebuild -project akstats.xcodeproj -scheme akstats -configuration Release \
        -destination 'platform=macOS' -derivedDataPath "$WORK/build" \
        CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM= \
        CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO -quiet build
    APP="$WORK/build/Build/Products/Release/akstats.app"

    # Re-sign with the app's sandbox entitlements (the same ones Xcode grants), minus debugging
    cat > "$WORK/akstats.entitlements" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key><true/>
    <key>com.apple.security.files.user-selected.read-write</key><true/>
</dict>
</plist>
EOF
    codesign --force --sign - --entitlements "$WORK/akstats.entitlements" "$APP"
    codesign --verify --deep --strict "$APP"
    codesign -d --entitlements - "$APP" 2>/dev/null | grep -q app-sandbox
    SIGNING="ad-hoc signed (not notarized)"
fi

rm -f "$ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"
SHA=$(shasum -a 256 "$ZIP" | cut -d' ' -f1)
echo "$SHA  akstats-macOS.zip" > dist/akstats-macOS.zip.sha256

if [[ $SIGNING == ad-hoc* ]]; then
    OPENING="**First launch:** macOS can't confirm who made this app, because it isn't notarized by Apple. Open it once, close the warning, then go to **System Settings → Privacy & Security**, scroll down, and click **Open Anyway** next to akstats. You only need to do this once."
else
    OPENING="The app is signed and notarized by Apple, so it opens normally."
fi

cat > dist/release-notes.md <<EOF
## What's new in v$VERSION

- **Practice simulations**: two simulated studies whose data recur in "Practice simulation" exercises across the course, plus a new *Dictionaries & topic models* lesson
- **Search** across lessons, practice questions, code, the glossary, datasets, and references
- **Practice data view**: preview every dataset and download CSVs, a ZIP of all of them, or one Excel workbook; each practice-simulation exercise links to the files it uses
- **Explained code**: every code block says what it's for; code blocks start open and remember when you close them
- **Bookmarks** from the toolbar or by right-clicking a section
- An app icon

## Install

1. Download **akstats-macOS.zip** below, unzip it, and move **akstats.app** to Applications.
2. $OPENING

Requires macOS 27 or later.

## Check your download

The source code for this release is public in this repository. To confirm your download is the exact file published here, run this in Terminal and compare the result:

\`\`\`
shasum -a 256 ~/Downloads/akstats-macOS.zip
\`\`\`

SHA-256: \`$SHA\`
EOF

rm -rf "$WORK"
echo "✓ $ZIP ($SIGNING)"
echo "✓ dist/akstats-macOS.zip.sha256"
echo "✓ dist/release-notes.md — paste into the release description"
