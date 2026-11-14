#!/usr/bin/env bash
# Fail if a built app or the pod lock still carries Firebase or Google code.
#
#   scripts/check-no-google.sh <upstream-checkout> <path/to/Runner.app>
set -euo pipefail
up="${1:?}"; app="${2:?}"
fail=0
if grep -iE '^\s*- (Firebase|Google|nanopb|PromisesObjC)' "$up/ios/Podfile.lock"; then
  echo "Podfile.lock still lists Firebase or Google pods" >&2; fail=1
fi
if find "$app" -iname '*firebase*' -o -iname '*google*' | grep .; then
  echo "the app bundle contains Firebase or Google files" >&2; fail=1
fi
if grep -rl -e 'firebaseinstallations.googleapis.com' -e 'fcmtoken.googleapis.com' "$app" 2>/dev/null | grep .; then
  echo "the app bundle names Firebase endpoints" >&2; fail=1
fi
[[ $fail == 0 ]] && echo "no Firebase or Google code in $(basename "$app")"
exit $fail
