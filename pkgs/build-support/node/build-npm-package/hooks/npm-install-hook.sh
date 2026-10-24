# shellcheck shell=bash

npmInstallHook() {
    echo "Executing npmInstallHook"

    runHook preInstall

    local -r packageOut="$out/lib/node_modules/$(@jq@ --raw-output '.name' package.json)"

    # `npm pack` writes to cache so temporarily override it
    while IFS= read -r file; do
        local dest="$packageOut/$(dirname "$file")"
        mkdir -p "$dest"
        cp "${npmWorkspace-.}/$file" "$dest"
    done < <(@jq@ --raw-output '.[0].files | map(.path | select(. | startswith("node_modules/") | not)) | join("\n")' <<< "$(npm_config_cache="$HOME/.npm" npm pack --json --dry-run --loglevel=warn --no-foreground-scripts ${npmWorkspace+--workspace=$npmWorkspace} $npmPackFlags "${npmPackFlagsArray[@]}" $npmFlags "${npmFlagsArray[@]}")")

    nodejsInstallExecutables "${npmWorkspace-.}/package.json"

    nodejsInstallManuals "${npmWorkspace-.}/package.json"

    local -r nodeModulesPath="$packageOut/node_modules"

    if [ ! -d "$nodeModulesPath" ]; then
        if [ -z "${dontNpmPrune-}" ]; then
            # Keep native helpers available while building, then select host
            # optional dependencies for the installed output. Their lifecycle
            # scripts cannot run on the build platform.
            local -a platformFlags=()
            if [ "@crossPlatform@" = true ]; then
                platformFlags=(--cpu="@npmArch@" --os="@npmPlatform@" --ignore-scripts)
            fi
            if ! npm prune --omit=dev --no-save "${platformFlags[@]}" ${npmWorkspace+--workspace=$npmWorkspace} $npmPruneFlags "${npmPruneFlagsArray[@]}" $npmFlags "${npmFlagsArray[@]}"; then
              echo
              echo
              echo "ERROR: npm prune step failed"
              echo
              echo 'If npm tried to download additional dependencies above, try setting `dontNpmPrune = true`.'
              echo

              exit 1
            fi
        fi

        find node_modules -maxdepth 1 -type d -empty -delete

        cp -r node_modules "$nodeModulesPath"
    fi

    runHook postInstall

    echo "Finished npmInstallHook"
}

if [ -z "${dontNpmInstall-}" ] && [ -z "${installPhase-}" ]; then
    installPhase=npmInstallHook
fi
