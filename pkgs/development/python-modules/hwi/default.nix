{
  lib,
  bitbox02,
  buildPythonPackage,
  poetry-core,
  cbor2,
  ecdsa,
  fetchFromGitHub,
  hidapi,
  libusb1,
  mnemonic,
  pyaes,
  pyserial,
  typing-extensions,
}:

buildPythonPackage rec {
  pname = "hwi";
  version = "3.1.0";
  pyproject = true;

  build-system = [ poetry-core ];

  src = fetchFromGitHub {
    owner = "bitcoin-core";
    repo = "HWI";
    tag = version;
    hash = "sha256-sQqft+5M+X+91bFqpUrbDRrFzpe/l1+w+pnIHwqezR8=";
  };

  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace-fail 'requires = ["poetry>=0.12"]' 'requires = ["poetry-core"]' \
      --replace-fail 'poetry.masonry.api' 'poetry.core.masonry.api'
  '';

  pythonRelaxDeps = [
    "cbor2"
    "protobuf"
  ];

  propagatedBuildInputs = [
    bitbox02
    cbor2
    ecdsa
    hidapi
    libusb1
    mnemonic
    pyaes
    pyserial
    typing-extensions
  ];

  # Tests require to clone quite a few firmwares
  doCheck = false;

  pythonImportsCheck = [ "hwilib" ];

  meta = {
    description = "Bitcoin Hardware Wallet Interface";
    homepage = "https://github.com/bitcoin-core/hwi";
    changelog = "https://github.com/bitcoin-core/HWI/releases/tag/${version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ prusnak ];
  };
}
