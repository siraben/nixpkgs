{
  lib,
  stdenv,
  fetchFromGitHub,
  pkg-config,
  protobuf,
  isStatic ? stdenv.hostPlatform.isStatic,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "protoc-gen-grpc-web";
  version = "2.1.1";

  src = fetchFromGitHub {
    owner = "grpc";
    repo = "grpc-web";
    rev = finalAttrs.version;
    hash = "sha256-5AM1oAFGIgARn7+CLNJox4g9VAI/z+5N5DDGVmawwK0=";
  };

  sourceRoot = "${finalAttrs.src.name}/javascript/net/grpc/web/generator";

  postPatch = ''
    substituteInPlace Makefile \
      --replace-fail "-std=c++11" "-std=c++17" \
      --replace-fail \
        "-lprotoc -lprotobuf" \
        '-lprotoc $(shell pkg-config ${lib.optionalString isStatic "--static"} --libs protobuf)'
  '';

  enableParallelBuilding = true;
  strictDeps = true;
  nativeBuildInputs = [
    pkg-config
    protobuf
  ];
  buildInputs = [ protobuf ];

  makeFlags = [
    "PREFIX=$(out)"
    "STATIC=${lib.boolToYesNo isStatic}"
  ];

  doCheck = true;
  nativeCheckInputs = [ protobuf ];
  checkPhase = ''
    runHook preCheck

    CHECK_TMPDIR="$TMPDIR/proto"
    mkdir -p "$CHECK_TMPDIR"

    protoc \
      --proto_path="$src/packages/grpc-web/test/protos" \
      --plugin="./protoc-gen-grpc-web" \
      --grpc-web_out="import_style=commonjs,mode=grpcwebtext:$CHECK_TMPDIR" \
      echo.proto

    # check for grpc-web generated file
    [ -f "$CHECK_TMPDIR/echo_grpc_web_pb.js" ]

    runHook postCheck
  '';

  meta = {
    homepage = "https://github.com/grpc/grpc-web";
    changelog = "https://github.com/grpc/grpc-web/blob/${finalAttrs.version}/CHANGELOG.md";
    description = "gRPC web support for Google's protocol buffers";
    mainProgram = "protoc-gen-grpc-web";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ jk ];
    platforms = lib.platforms.unix;
  };
})
