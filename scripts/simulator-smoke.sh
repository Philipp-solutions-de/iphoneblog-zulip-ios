#!/usr/bin/env bash
# Install the simulator build, launch it, check it stays up, take a screenshot.
#
#   [SIM_UDID=…] [APPEARANCE=dark] scripts/simulator-smoke.sh <Runner.app> <screenshot.png>
set -euo pipefail
app="${1:?}"; shot="${2:?}"
source "$(dirname "$0")/../config/app.env"

# SIM_UDID picks a device; otherwise the first iPhone of the newest iOS runtime.
udid=${SIM_UDID:-}
[[ -n "$udid" ]] || udid=$(xcrun simctl list devices available -j | python3 -c '
import json, sys
devs = json.load(sys.stdin)["devices"]
for runtime in sorted((r for r in devs if "iOS" in r), reverse=True):
    for d in devs[runtime]:
        if d["name"].startswith("iPhone"):
            print(d["udid"]); sys.exit()
sys.exit("no iPhone simulator found")')
echo "simulator $udid"
# A fresh device: no alert or state left from an earlier run.
xcrun simctl shutdown "$udid" 2>/dev/null || true
for _ in $(seq 1 30); do
  xcrun simctl list devices | grep -q "$udid) (Shutdown)" && break
  sleep 2
done
xcrun simctl erase "$udid"
xcrun simctl boot "$udid"
xcrun simctl bootstatus "$udid" -b
xcrun simctl ui "$udid" appearance "${APPEARANCE:-light}"
xcrun simctl install "$udid" "$app"
xcrun simctl launch "$udid" "$BUNDLE_ID"
sleep 20
running=$(xcrun simctl spawn "$udid" launchctl list)
if [[ "$running" != *"UIKitApplication:$BUNDLE_ID"* ]]; then
  echo "the app is not running 20 seconds after launch" >&2
  exit 1
fi
xcrun simctl io "$udid" screenshot "$shot"
echo "screenshot: $shot"
