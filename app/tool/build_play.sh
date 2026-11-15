#!/usr/bin/env bash
# Builds the Android App Bundle for Google Play: release, signed with the
# upload key from android/key.properties, without the in-app updater (Play
# updates the app; REQUEST_INSTALL_PACKAGES is removed from the manifest).
# A brand (android/brand.properties) is used when present.
# Usage: tool/build_play.sh   → build/app/outputs/bundle/release/app-release.aab
# Checklist for the store listing: docs/PLAY_STORE.md
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ ! -f android/key.properties ]]; then
  echo "android/key.properties is missing: Play needs a real upload key (docs/RELEASE.md)." >&2
  exit 1
fi
flutter build appbundle --release \
  --dart-define=STORE_BUILD=true --android-project-arg=play=true "$@"
echo
echo "Check the merged manifest has no REQUEST_INSTALL_PACKAGES:"
echo "  build/app/intermediates/merged_manifests/release/processReleaseManifest/AndroidManifest.xml"
