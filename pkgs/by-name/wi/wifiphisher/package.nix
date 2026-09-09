{
  lib,
  fetchFromGitHub,
  runtimeShell,
  testers,
  python3Packages,
  libnl,
  openssl,
  coreutils,
  cowpatty,
  dnsmasq,
  hostapd,
  iptables,
  net-tools,
  networkmanager,
  procps,
  wpa_supplicant,
}:

let
  roguehostapd = python3Packages.buildPythonPackage {
    pname = "roguehostapd";
    version = "1.1.2-unstable-2019-12-08";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "wifiphisher";
      repo = "roguehostapd";
      rev = "381b373b4b3394d916e8c7a19b10d6c3c491bd13";
      hash = "sha256-rPIiIi3leUyWOIYOt10PTY1HMpwcUcvYVVyGb/jZk4E=";
    };

    postPatch = ''
      substituteInPlace roguehostapd/buildutil/build_files.py \
        --replace-fail "'/usr/include/libnl3'" "'${lib.getDev libnl}/include/libnl3'" \
        --replace-fail "'/usr/include/openssl'" "'${lib.getDev openssl}/include'"
      substituteInPlace roguehostapd/config/hostapdconfig.py \
        --replace-fail 'from configparser import SafeConfigParser' 'from configparser import ConfigParser' \
        --replace-fail 'SafeConfigParser()' 'ConfigParser()'
      substituteInPlace setup.py \
        --replace-fail "shutil.rmtree('tmp')" "shutil.rmtree('tmp', ignore_errors=True)"
      substituteInPlace setup.cfg \
        --replace-fail 'description-file' 'description_file'
    '';

    build-system = [ python3Packages.setuptools ];

    buildInputs = [
      libnl
      openssl
    ];

    preInstallCheck = ''
      pushd "$TMPDIR"
      python - <<'PY'
      import ctypes
      from roguehostapd.apctrl import find_so

      ctypes.CDLL(find_so())
      PY
      popd
    '';

    pythonImportsCheck = [ "roguehostapd.apctrl" ];

    meta = {
      description = "Hostapd fork with Python bindings and Wi-Fi attack extensions";
      homepage = "https://github.com/wifiphisher/roguehostapd";
      license = lib.licenses.bsd3;
      platforms = lib.platforms.linux;
    };
  };

  runtimePrograms = [
    coreutils
    cowpatty
    dnsmasq
    hostapd
    iptables
    net-tools
    networkmanager
    procps
    wpa_supplicant
  ];
in
python3Packages.buildPythonApplication (finalAttrs: {
  pname = "wifiphisher";
  # The v1.4 tag is Python 2-only; upstream has kept the version at 1.4 while
  # maintaining Python 3 support on master.
  version = "1.4-unstable-2026-05-22";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "wifiphisher";
    repo = "wifiphisher";
    rev = "4ae336518bf29eed13d3b09f2ee6a16e7973c997";
    hash = "sha256-RIvyiVwcfJgOAQs9+IMnLxEcE6tMl/3RzJDkkqDvFXI=";
  };

  postPatch = ''
    # Nix supplies these dependencies, so setup.py must not inspect the host or
    # try to direct users to an imperative package manager.
    python3 - <<'PY'
    from pathlib import Path

    setup = Path("setup.py")
    text = setup.read_text()
    start = text.index("\ncheck_dnsmasq()\n")
    end = text.index("\n# run setup", start)
    text = text[:start] + text[end:]
    text = text.replace('LICENSE = "GPL"', 'LICENSE = "GPL-3.0-only"')
    text = text.replace(
        'License :: OSI Approved :: GNU Lesser General Public License v3 (LGPLv3)',
        'License :: OSI Approved :: GNU General Public License v3 (GPLv3)',
    )
    text = text.replace(
        '"Programming Language :: Python :: 2", "Programming Language :: Python :: 2.7",\n'
        '               "Programming Language :: Python :: 2 :: Only",',
        '"Programming Language :: Python :: 3",\n'
        '               "Programming Language :: Python :: 3 :: Only",',
    )
    setup.write_text(text)
    PY

    substituteInPlace wifiphisher/extensions/handshakeverify.py \
      --replace-fail '/bin/cowpatty' '${lib.getExe' cowpatty "cowpatty"}'
    substituteInPlace wifiphisher/common/interfaces.py \
      --replace-fail "'/bin/sh'" "'${runtimeShell}'"
  '';

  build-system = [ python3Packages.setuptools ];

  dependencies = with python3Packages; [
    pbkdf2
    pyric
    roguehostapd
    scapy
    six
    tornado
  ];

  nativeCheckInputs = with python3Packages; [
    mock
    pytestCheckHook
  ];

  enabledTestPaths = [ "tests" ];

  makeWrapperArgs = [
    "--prefix"
    "PATH"
    ":"
    (lib.makeBinPath runtimePrograms)
  ];

  pythonImportsCheck = [
    "wifiphisher.common.phishingpage"
    "wifiphisher.common.interfaces"
    "wifiphisher.extensions.deauth"
  ];

  preInstallCheck = ''
    export HOME="$TMPDIR"
    "$out/bin/wifiphisher" --help > help.txt
    grep -F -- "--phishingscenario" help.txt
    grep -F -- "--force-hostapd" help.txt

    python - <<'PY'
    from wifiphisher.extensions.handshakeverify import is_valid_handshake_capture

    assert not is_valid_handshake_capture("/nonexistent-wifiphisher-capture.pcap")
    PY
  '';

  passthru.tests.smoke = testers.runCommand {
    name = "wifiphisher-smoke";
    nativeBuildInputs = [ finalAttrs.finalPackage ];
    script = ''
      export HOME="$TMPDIR"
      wifiphisher --help > help.txt
      grep -F -- "--phishingscenario" help.txt
      grep -F -- "--force-hostapd" help.txt
      touch "$out"
    '';
  };

  meta = {
    description = "Rogue access point framework for Wi-Fi security testing";
    longDescription = ''
      Wifiphisher automates Wi-Fi association and web-phishing attacks for
      authorized red-team engagements and wireless security testing.
    '';
    homepage = "https://github.com/wifiphisher/wifiphisher";
    license = with lib.licenses; [
      gpl3Only
      asl20
      bsd3
      mit
      ofl
    ];
    mainProgram = "wifiphisher";
    platforms = lib.platforms.linux;
    maintainers = [ ];
  };
})
