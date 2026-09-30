#!/bin/bash
# Builds an unsigned .ipa for AltStore distribution. AltServer re-signs the app
# on install with the user's own Apple ID, so no signing certificate is needed here.
set -euo pipefail
cd "$(dirname "$0")/.."

rm -rf build
xcodegen generate

xcodebuild archive \
  -project Massimali.xcodeproj \
  -scheme Massimali \
  -configuration Release \
  -archivePath build/Massimali.xcarchive \
  -destination "generic/platform=iOS" \
  -skipPackagePluginValidation \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  AD_HOC_CODE_SIGNING_ALLOWED=YES

mkdir -p build/Payload
cp -r build/Massimali.xcarchive/Products/Applications/Massimali.app build/Payload/

# Firma ad-hoc solo per incidere gli entitlement nel binario: AltStore rifirma
# con quelli che trova qui. Senza, HealthKit manca e Salute non si collega.
codesign -f -s - build/Payload/Massimali.app/PlugIns/MassimaliWidgets.appex
codesign -f -s - --entitlements Massimali/Massimali.entitlements build/Payload/Massimali.app
(cd build && zip -qry Massimali.ipa Payload)

echo "build/Massimali.ipa"
