#!/bin/bash
# Installa Massimali **con l'app Watch** su iPhone e Apple Watch, dal Mac, via rete o cavo.
#
# Perché non AltStore: WatchConnectivity lega le due app solo se l'app iPhone installata
# contiene l'app Watch in Watch/, e AltSign (ldid) quella cartella la rifirma male: la
# tratta come file sciolti e toglie gli entitlement all'eseguibile del Watch, quindi
# l'installazione fallisce. L'ipa di AltStore (build_ipa.sh) resta senza Watch.
#
# Cosa fa:
#   1. copia il working tree in una cartella temporanea (il repo non viene toccato);
#   2. usa gli stessi bundle id che dà AltStore (…massimali.<TEAM>), così l'app
#      sostituisce quella di AltStore senza perdere i dati;
#   3. incorpora l'app Watch nell'app iPhone e compila con il tuo Apple ID;
#   4. installa prima l'iPhone e poi il Watch, togliendo prima la copia vecchia
#      dall'orologio: solo così il sistema registra la coppia.
#
# Con l'Apple ID gratuito la firma dura 7 giorni: per rinnovarla si rilancia lo script.
# Servono iPhone e Watch sbloccati e Modalità sviluppatore attiva su entrambi.
#
# Uso: ./scripts/install_device.sh            (dispositivi trovati da soli)
#      IPHONE_ID=… WATCH_ID=… ./scripts/install_device.sh
set -euo pipefail
cd "$(dirname "$0")/.."

TEAM=$(awk '/DEVELOPMENT_TEAM:/ {print $2; exit}' project.yml)
BASE_ID=com.gabrieleforghieri.massimali
WORK=$(mktemp -d -t massimali-device)
trap 'rm -rf "$WORK"' EXIT

# Primo iPhone e primo Watch fisici collegati e disponibili.
pick() {
    xcrun devicectl list devices --json-output "$WORK/devices.json" >/dev/null
    python3 - "$WORK/devices.json" "$1" <<'EOF'
import json, sys
devices = json.load(open(sys.argv[1]))["result"]["devices"]
for d in devices:
    hw, conn = d.get("hardwareProperties", {}), d.get("connectionProperties", {})
    if hw.get("deviceType") == sys.argv[2] and hw.get("reality") == "physical" \
            and conn.get("pairingState") == "paired" and conn.get("tunnelState") != "unavailable":
        print(hw["udid"]); break
EOF
}
IPHONE_ID=${IPHONE_ID:-$(pick iPhone)}
WATCH_ID=${WATCH_ID:-$(pick appleWatch)}
[ -n "$IPHONE_ID" ] || { echo "Nessun iPhone collegato." >&2; exit 1; }
[ -n "$WATCH_ID" ] || { echo "Nessun Apple Watch collegato." >&2; exit 1; }
echo "iPhone $IPHONE_ID · Watch $WATCH_ID · team $TEAM"

rsync -a --exclude build --exclude '*.xcodeproj' --exclude graphify-out --exclude brag-output --exclude .git ./ "$WORK/src/"
cd "$WORK/src"
python3 - "$BASE_ID" "$TEAM" <<'EOF'
import sys
base, team = sys.argv[1], sys.argv[2]
s = open("project.yml").read()
s = s.replace(f"PRODUCT_BUNDLE_IDENTIFIER: {base}\n", f"PRODUCT_BUNDLE_IDENTIFIER: {base}.{team}\n")
s = s.replace(f"PRODUCT_BUNDLE_IDENTIFIER: {base}.widgets", f"PRODUCT_BUNDLE_IDENTIFIER: {base}.{team}.widgets")
s = s.replace("      - target: MassimaliWidgets\n", "      - target: MassimaliWidgets\n      - target: MassimaliWatch\n", 1)
open("project.yml", "w").write(s)
EOF
grep -q "$BASE_ID.$TEAM.watchkitapp" project.yml \
    || { echo "Il bundle id del Watch in project.yml non corrisponde al team $TEAM." >&2; exit 1; }

xcodegen generate --quiet
xcodebuild build \
    -project Massimali.xcodeproj \
    -scheme Massimali \
    -configuration Release \
    -destination "id=$IPHONE_ID" \
    -derivedDataPath "$WORK/dd" \
    -allowProvisioningUpdates \
    -quiet

APP="$WORK/dd/Build/Products/Release-iphoneos/Massimali.app"
[ -d "$APP/Watch/Massimali.app" ] || { echo "L'app Watch non è stata incorporata." >&2; exit 1; }

echo "Installo sull'iPhone…"
xcrun devicectl device install app --device "$IPHONE_ID" "$APP" >/dev/null
# Installata sopra una copia vecchia, l'app Watch non viene ricollegata all'iPhone:
# va tolta e rimessa. I dati veri stanno sull'iPhone, sull'orologio non si perde nulla.
echo "Installo sul Watch…"
xcrun devicectl device uninstall app --device "$WATCH_ID" "$BASE_ID.$TEAM.watchkitapp" >/dev/null 2>&1 || true
xcrun devicectl device install app --device "$WATCH_ID" "$APP/Watch/Massimali.app" >/dev/null
echo "Fatto. Apri Massimali su iPhone: in Impostazioni → Apple Watch deve comparire «collegato»."
