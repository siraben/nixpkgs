#!/usr/bin/env nix-shell
#!nix-shell -i bash -p common-updater-scripts curl jq nix nix-update
# shellcheck shell=bash

set -euo pipefail

cd "$(dirname "$0")/../../../.."

release_data="$(
  curl \
    ${GITHUB_TOKEN:+--user ":$GITHUB_TOKEN"} \
    --fail \
    --silent \
    --show-error \
    https://api.github.com/repos/desktop/desktop/releases/latest
)"

tag="$(jq --exit-status --raw-output '.tag_name' <<<"$release_data")"
if [[ ! "$tag" =~ ^release-([0-9]+\.[0-9]+\.[0-9]+)$ ]]; then
  echo "Unexpected release tag: $tag" >&2
  exit 1
fi
version="${BASH_REMATCH[1]}"

darwin_digest="$(
  jq \
    --exit-status \
    --raw-output \
    '.assets[] | select(.name == "GitHub.Desktop-arm64.zip") | .digest | select(startswith("sha256:"))' \
    <<<"$release_data"
)"
darwin_hash="$(nix hash convert --hash-algo sha256 --to sri "${darwin_digest#sha256:}")"

nix-update github-desktop \
  --version "$version" \
  --custom-dep cacheRoot \
  --custom-dep cacheApp

update-source-version github-desktop "$version" "$darwin_hash" \
  --system=aarch64-darwin \
  --source-key=passthru.sources.aarch64-darwin \
  --ignore-same-version
