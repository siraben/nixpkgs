{
  lib,
  stdenv,
  fetchFromGitHub,
  installShellFiles,
  buildGoModule,
  go,
  makeWrapper,
  testers,
  viceroy,
  wasm-tools,
  writeShellScriptBin,
}:

let
  fakeCargo = writeShellScriptBin "cargo" ''
    case "$*" in
      "locate-project --quiet")
        printf '{"root":"%s/Cargo.toml"}\n' "$PWD"
        ;;
      "version --quiet")
        echo "cargo 1.90.0 (fake)"
        ;;
      "build "*)
        case " $* " in
          *" --target wasm32-wasip1 "*) ;;
          *)
            echo "cargo build did not target wasm32-wasip1: $*" >&2
            exit 1
            ;;
        esac
        printf '%s\n' "$*" > cargo-build-args
        mkdir -p target/wasm32-wasip1/release
        printf '\x00\x61\x73\x6d\x01\x00\x00\x00' \
          > target/wasm32-wasip1/release/nixpkgs-fastly-rust-test.wasm
        ;;
      "metadata --quiet --format-version 1")
        printf '{"packages":[],"target_directory":"%s/target"}\n' "$PWD"
        ;;
      *)
        echo "unexpected cargo invocation: $*" >&2
        exit 1
        ;;
    esac
  '';
in
buildGoModule (finalAttrs: {
  pname = "fastly";
  version = "16.0.0";

  src = fetchFromGitHub {
    owner = "fastly";
    repo = "cli";
    tag = "v${finalAttrs.version}";
    hash = "sha256-gVKlAbiznaRKwDpiyap4Q3mIhn/ZbnUIFwG3l01ZXQ8=";
    # The git commit is part of the `fastly version` original output;
    # leave that output the same in nixpkgs. Use the `.git` directory
    # to retrieve the commit SHA, and remove the directory afterwards,
    # since it is not needed after that.
    leaveDotGit = true;
    postFetch = ''
      cd "$out"
      git rev-parse --short HEAD > $out/COMMIT
      find "$out" -name .git -print0 | xargs -0 rm -rf
    '';
  };

  subPackages = [
    "cmd/fastly"
  ];

  vendorHash = "sha256-U2Ix8ZKGCDrWUJFFXJaL+1EBTbqblWp8slhruHhouIc=";

  nativeBuildInputs = [
    installShellFiles
    makeWrapper
  ];

  # Flags as provided by the build automation of the project:
  #   https://github.com/fastly/cli/blob/7844f9f54d56f8326962112b5534e5c40e91bf09/.goreleaser.yml#L14-L18
  ldflags = [
    "-s"
    "-w"
    "-X github.com/fastly/cli/pkg/revision.AppVersion=v${finalAttrs.version}"
    "-X github.com/fastly/cli/pkg/revision.Environment=release"
    "-X github.com/fastly/cli/pkg/revision.GoHostOS=${go.GOHOSTOS}"
    "-X github.com/fastly/cli/pkg/revision.GoHostArch=${go.GOHOSTARCH}"
  ];
  preBuild = ''
    cp ./.fastly/config.toml ./pkg/config/config.toml
    ldflags+=" -X github.com/fastly/cli/pkg/revision.GitCommit=$(cat COMMIT)"
  '';

  preFixup = ''
    wrapProgram $out/bin/fastly --prefix PATH : ${lib.makeBinPath [ viceroy ]} \
      --set FASTLY_VICEROY_USE_PATH 1
  '';

  postInstall = lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
    export HOME="$(mktemp -d)"
    installShellCompletion --cmd fastly \
      --bash <($out/bin/fastly --completion-script-bash) \
      --zsh <($out/bin/fastly --completion-script-zsh)
  '';

  passthru.tests.rust-compute-build = testers.runCommand {
    name = "fastly-rust-compute-build-test";
    nativeBuildInputs = [
      finalAttrs.finalPackage
      wasm-tools
    ];
    script = ''
      export HOME="$TMPDIR/home"
      export PATH=${fakeCargo}/bin:$PATH
      mkdir -p "$HOME" project/src
      cd project

      cat > fastly.toml <<'EOF'
      manifest_version = "0.2.0"
      name = "nixpkgs-fastly-rust-test"
      description = "Regression test"
      authors = ["Nixpkgs"]
      language = "rust"
      EOF

      cat > Cargo.toml <<'EOF'
      [package]
      name = "nixpkgs-fastly-rust-test"
      version = "0.1.0"
      edition = "2021"
      EOF
      touch src/main.rs

      fastly --non-interactive compute build --metadata-disable

      grep -F -- "--target wasm32-wasip1" cargo-build-args
      test -f pkg/nixpkgs-fastly-rust-test.tar.gz
      tar -tzf pkg/nixpkgs-fastly-rust-test.tar.gz \
        | grep -Fx "nixpkgs-fastly-rust-test/bin/main.wasm"
      touch "$out"
    '';
  };

  meta = {
    description = "Command line tool for interacting with the Fastly API";
    homepage = "https://github.com/fastly/cli";
    changelog = "https://github.com/fastly/cli/blob/v${finalAttrs.version}/CHANGELOG.md";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [
      ereslibre
    ];
    mainProgram = "fastly";
  };
})
