#!/usr/bin/env bash
# Install Flutter at $FLUTTER_SHA into ~/flutter (CI), unless the cache has it.
set -euo pipefail
: "${FLUTTER_SHA:?}"
if [[ ! -x ~/flutter/bin/flutter ]]; then
  git init -q ~/flutter
  git -C ~/flutter fetch -q --depth 1 https://github.com/flutter/flutter.git "$FLUTTER_SHA"
  git -C ~/flutter -c advice.detachedHead=false checkout -q FETCH_HEAD
  # flutter --version reads the channel from a branch name.
  git -C ~/flutter checkout -q -b main
fi
[[ "$(git -C ~/flutter rev-parse HEAD)" == "$FLUTTER_SHA" ]] || { echo "Flutter is not at $FLUTTER_SHA" >&2; exit 1; }
echo "$HOME/flutter/bin" >> "${GITHUB_PATH:-/dev/null}"
export PATH="$HOME/flutter/bin:$PATH"
flutter config --no-analytics --no-cli-animations >/dev/null
flutter --version
xcodebuild -version
flutter precache --ios
