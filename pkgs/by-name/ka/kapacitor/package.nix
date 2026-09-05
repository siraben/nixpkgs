{
  stdenv,
  lib,
  rustPlatform,
  fetchFromGitHub,
  libiconv,
  buildGoModule,
  pkg-config,
}:

let
  libflux_version = "0.191.0";
  flux = rustPlatform.buildRustPackage rec {
    pname = "libflux";
    version = "${libflux_version}";
    src = fetchFromGitHub {
      owner = "influxdata";
      repo = "flux";
      tag = "v${libflux_version}";
      hash = "sha256-l70Vs1aSes8FYs20J95diy8HxoLc+pG6CCGTce+3q3w=";
    };

    # Don't fail on warnings introduced by newer Rust compilers.
    postPatch = ''
      substituteInPlace flux-core/src/lib.rs flux/src/lib.rs \
        --replace-fail "deny(warnings, missing_docs))]" \
          "deny(warnings), allow(dead_code, hidden_glob_reexports, mismatched_lifetime_syntaxes))]"
    '';
    sourceRoot = "${src.name}/libflux";

    cargoHash = "sha256-HotrRXwjdU4f++z5/77oBJztGVjEeAi2N/Q1vZx7Rzc=";
    nativeBuildInputs = [ rustPlatform.bindgenHook ];
    buildInputs = lib.optional stdenv.hostPlatform.isDarwin libiconv;
    pkgcfg = ''
      Name: flux
      Version: ${libflux_version}
      Description: Library for the InfluxData Flux engine
      Cflags: -I/out/include
      Libs: -L/out/lib -lflux -lpthread
    '';
    postInstall = ''
      mkdir -p $out/include $out/pkgconfig
      cp -r $NIX_BUILD_TOP/source/libflux/include/influxdata $out/include
      printf "%s" "$pkgcfg" > $out/pkgconfig/flux.pc
      substituteInPlace $out/pkgconfig/flux.pc \
        --replace-fail /out $out
    ''
    + lib.optionalString stdenv.hostPlatform.isDarwin ''
      install_name_tool -id $out/lib/libflux.dylib $out/lib/libflux.dylib
    '';

    __structuredAttrs = true;
  };
in
buildGoModule rec {
  pname = "kapacitor";
  version = "1.8.6";

  src = fetchFromGitHub {
    owner = "influxdata";
    repo = "kapacitor";
    tag = "v${version}";
    hash = "sha256-X6wVlAgQhy3+/26TVDMdMDEHQM8tnJt4JB/cR4fExZk=";
  };

  vendorHash = "sha256-+D9Uhw3SKDfApWK3jCtjnb9Q/I6YW0PECsszKY9gXb8=";

  nativeBuildInputs = [ pkg-config ];

  env.PKG_CONFIG_PATH = "${flux}/pkgconfig";

  ldflags = [
    "-X main.version=${version}"
    "-X main.branch=NixOS"
    "-X main.commit=v${version}"
    "-X main.platform=OSS"
  ];

  # Check that libflux is at the right version
  preBuild = ''
    flux_ver=$(grep github.com/influxdata/flux go.mod | awk '{print $2}')
    if [ "$flux_ver" != "v${libflux_version}" ]; then
      echo "go.mod wants libflux $flux_ver, but nix derivation provides ${libflux_version}"
      exit 1
    fi
  '';

  # Remove failing server tests
  preCheck = ''
    rm server/server_test.go
  '';

  checkFlags =
    let
      skippedTests = [
        "TestBatch_KapacitorLoopback"
      ];
    in
    [
      "-skip=^${builtins.concatStringsSep "$|^" skippedTests}$"
    ];

  # Tests start http servers which need to bind to local addresses,
  # but that fails in the Darwin sandbox by default unless this option is turned on
  # Error is: panic: httptest: failed to listen on a port: listen tcp6 [::1]:0: bind: operation not permitted
  # See also https://github.com/NixOS/nix/pull/1646
  __darwinAllowLocalNetworking = true;

  meta = {
    description = "Open source framework for processing, monitoring, and alerting on time series data";
    homepage = "https://influxdata.com/time-series-platform/kapacitor/";
    downloadPage = "https://github.com/influxdata/kapacitor/releases";
    license = lib.licenses.mit;
    changelog = "https://github.com/influxdata/kapacitor/blob/v${version}/CHANGELOG.md";
    maintainers = with lib.maintainers; [
      totoroot
    ];
  };
}
