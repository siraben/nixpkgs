#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl gnused jq

set -x -eu -o pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

curlArgs=(-fsSL -H "Accept: application/vnd.github+json")
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    curlArgs+=(-H "Authorization: Bearer $GITHUB_TOKEN")
fi

SPEC_VERSION=$(curl "${curlArgs[@]}" \
    https://api.github.com/repos/linode/linode-api-openapi/releases/latest \
    | jq -r .tag_name)

SPEC_SHA256=$(nix-prefetch-url --quiet \
    "https://raw.githubusercontent.com/linode/linode-api-openapi/${SPEC_VERSION}/openapi.json")
SPEC_SHA256=$(nix hash convert --hash-algo sha256 --to sri "$SPEC_SHA256")

VERSION=$(curl "${curlArgs[@]}" \
    https://api.github.com/repos/linode/linode-cli/releases/latest \
    | jq -r '.tag_name | sub("^v"; "")')

SHA256=$(nix-prefetch-url --quiet \
    "https://files.pythonhosted.org/packages/source/l/linode_cli/linode_cli-${VERSION}.tar.gz")
SHA256=$(nix hash convert --hash-algo sha256 --to sri "$SHA256")

setKV () {
    sed -i "s|$1 = \".*\"|$1 = \"${2:-}\"|" ./package.nix
}

setKV specVersion "$SPEC_VERSION"
setKV specHash "$SPEC_SHA256"
setKV version "$VERSION"
setKV hash "$SHA256"
