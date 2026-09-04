{
  lib,
  stdenv,
  go,
  buildGoModule,
  # A package that relies on CGO
  skopeo,
  testers,
  runCommand,
  bintools,
  # A package with CGO_ENABLED=0
  uplosi,
}:
let
  skopeo' = skopeo.override { buildGoModule = buildGoModule; };
  uplosi' = uplosi.override { buildGoModule = buildGoModule; };
  staticLinking = buildGoModule {
    pname = "go-static-linking-test";
    version = "0";
    src = ./testdata/linking;
    vendorHash = null;
    env.CGO_ENABLED = 0;
    ldflags = [ "-extldflags=-static" ];
    subPackages = [ "static" ];
  };
  cgoPieLinking = buildGoModule {
    pname = "go-cgo-pie-linking-test";
    version = "0";
    src = ./testdata/linking;
    vendorHash = null;
    env.CGO_ENABLED = 1;
    preBuild = ''
      export GOFLAGS="$GOFLAGS -buildmode=pie"
    '';
    subPackages = [ "cgo" ];
  };
  expectedCgoEnabledType = "DYN";
  expectedCgoDisabledType = "EXE";
in
{
  skopeo = testers.testVersion { package = skopeo'; };
  version = testers.testVersion {
    package = go;
    command = "go version";
    version = "go${go.version}";
  };
  uplosi = testers.testVersion { package = uplosi'; };
}
# bin type tests assume ELF file + linux-specific exe types
// lib.optionalAttrs stdenv.hostPlatform.isLinux {
  skopeo-bin-type = runCommand "skopeo-bin-type" { meta.broken = stdenv.hostPlatform.isStatic; } ''
    bin="${lib.getExe' skopeo' ".skopeo-wrapped"}"
    if ! ${lib.getExe' bintools "readelf"} -p .comment $bin | grep -Fq "GCC: (GNU)"; then
      echo "${lib.getExe skopeo} should have been externally linked, but no GNU .comment section found"
      exit 1
    fi
    if ${lib.getExe' bintools "readelf"} -h $bin | grep -q "Type:.*${expectedCgoEnabledType}"; then
      touch $out
    else
      echo "ERROR: $bin is NOT ${expectedCgoEnabledType}"
      exit 1
    fi
  '';
  uplosi-bin-type = runCommand "uplosi-bin-type" { meta.broken = stdenv.hostPlatform.isStatic; } ''
    bin="${lib.getExe uplosi'}"
    if ${lib.getExe' bintools "readelf"} -p .comment "$bin" 2>/dev/null | grep -Fq "GCC: (GNU)"; then
      echo "$bin has a GCC .comment, but it should have used the internal go linker"
      exit 1
    fi
    if ${lib.getExe' bintools "readelf"} -h "$bin" | grep -q "Type:.*${expectedCgoDisabledType}"; then
      touch $out
    else
      echo "ERROR: $bin is NOT ${expectedCgoDisabledType}"
      exit 1
    fi
  '';
  static-linking = runCommand "go-static-linking" { } ''
    bin="${staticLinking}/bin/static"
    readelf=${lib.getExe' bintools "readelf"}

    if ! "$readelf" -h "$bin" | grep -q "Type:.*${expectedCgoDisabledType}"; then
      echo "ERROR: $bin is not an ELF ${expectedCgoDisabledType} executable"
      exit 1
    fi
    if "$readelf" -l "$bin" | grep -q INTERP; then
      echo "ERROR: $bin has an ELF interpreter"
      exit 1
    fi
    if "$readelf" -d "$bin" 2>&1 | grep -q NEEDED; then
      echo "ERROR: $bin has a dynamic dependency"
      exit 1
    fi
    if "$readelf" -p .comment "$bin" 2>/dev/null | grep -Fq "GCC: (GNU)"; then
      echo "ERROR: $bin was externally linked"
      exit 1
    fi
    touch $out
  '';
  cgo-pie-linking = runCommand "go-cgo-pie-linking" { meta.broken = stdenv.hostPlatform.isStatic; } ''
    bin="${cgoPieLinking}/bin/cgo"
    readelf=${lib.getExe' bintools "readelf"}

    if ! "$readelf" -h "$bin" | grep -q "Type:.*${expectedCgoEnabledType}"; then
      echo "ERROR: $bin is not an ELF ${expectedCgoEnabledType} executable"
      exit 1
    fi
    if ! "$readelf" -l "$bin" | grep -q INTERP; then
      echo "ERROR: $bin does not have an ELF interpreter"
      exit 1
    fi
    if ! "$readelf" -d "$bin" 2>&1 | grep -q NEEDED; then
      echo "ERROR: $bin does not have a dynamic dependency"
      exit 1
    fi
    if ! "$readelf" -p .comment "$bin" 2>/dev/null | grep -Fq "GCC: (GNU)"; then
      echo "ERROR: $bin was not externally linked"
      exit 1
    fi
    touch $out
  '';
}
