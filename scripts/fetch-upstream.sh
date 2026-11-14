#!/usr/bin/env bash
# Check out zulip-flutter and the Flutter commit it was tested with.
#
#   scripts/fetch-upstream.sh <dir> [tag]
#
# Without a tag: UPSTREAM_REF from config/app.env, or the newest GitHub release.
# Prints shell assignments (UPSTREAM_TAG, FLUTTER_SHA) for the caller to eval
# or append to $GITHUB_ENV.
set -euo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
source "$here/config/app.env"
dir="${1:?usage: fetch-upstream.sh <dir> [tag]}"
tag="${2:-${UPSTREAM_REF:-}}"
if [[ -z "$tag" ]]; then
  # Authenticated through gh (GH_TOKEN in CI): GitHub refuses anonymous API calls from
  # shared runner addresses.
  tag=$(gh api repos/zulip/zulip-flutter/releases/latest --jq .tag_name)
fi
[[ "$tag" =~ ^v[0-9.]+$ ]] || { echo "fetch-upstream.sh: unexpected tag '$tag'" >&2; exit 1; }
git clone -q --depth 1 --branch "$tag" https://github.com/zulip/zulip-flutter.git "$dir" >&2
# pubspec.yaml names the Flutter commit upstream tested with, as a comment:
#   flutter: '>=3.50.0-1.0.pre-219'  # a29b620b741a1f1a5a0e371c87a59d06f4984865
sha=$(sed -nE "s/^  flutter: '[^']*' *# *([0-9a-f]{40}).*/\1/p" "$dir/pubspec.yaml")
[[ -n "$sha" ]] || { echo "fetch-upstream.sh: no Flutter commit in pubspec.yaml" >&2; exit 1; }
echo "UPSTREAM_TAG=$tag"
echo "FLUTTER_SHA=$sha"
