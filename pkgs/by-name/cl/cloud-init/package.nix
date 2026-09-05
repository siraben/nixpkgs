{
  lib,
  nixosTests,
  busybox,
  cloud-utils,
  coreutils,
  dmidecode,
  fetchFromGitHub,
  gitUpdater,
  iproute2,
  meson,
  ninja,
  openssh,
  pkg-config,
  procps,
  python3,
  shadow,
  systemd,
}:

python3.pkgs.buildPythonApplication (finalAttrs: {
  pname = "cloud-init";
  version = "26.2";
  pyproject = false;

  namePrefix = "";

  src = fetchFromGitHub {
    owner = "canonical";
    repo = "cloud-init";
    tag = finalAttrs.version;
    hash = "sha256-OFgn1zOoWivNB5JPszFjhSzmILDRJ9aR9A9y81oBwMk=";
  };

  patches = [
    ./0001-add-nixos-support.patch
    ./0002-fix-test-logs-on-nixos.patch
  ];

  prePatch = ''
    substituteInPlace meson.build \
      --replace-fail "systemd_unit_dir = systemd.get_variable(pkgconfig: 'systemdsystemunitdir')" "systemd_unit_dir = get_option('prefix') / 'lib/systemd/system'" \
      --replace-fail "systemd_generator_dir = systemd.get_variable(pkgconfig: 'systemdsystemgeneratordir')" "systemd_generator_dir = get_option('prefix') / 'lib/systemd/system-generators'" \
      --replace-fail "udev_dir = udev.get_variable(pkgconfig: 'udevdir')" "udev_dir = get_option('prefix') / 'lib/udev'"

    substituteInPlace cloudinit/net/networkd.py \
      --replace-fail '["/usr/sbin", "/bin"]' '["/usr/sbin", "/bin", "${iproute2}/bin", "${systemd}/bin"]'

    substituteInPlace tests/unittests/test_net_activators.py \
      --replace-fail '["/usr/sbin", "/bin"]' \
        '["/usr/sbin", "/bin", "${iproute2}/bin", "${systemd}/bin"]'
  '';

  postPatch = ''
    patchShebangs scripts tools
  '';

  postInstall = ''
    install -D -m644 ../bash_completion/cloud-init \
      $out/share/bash-completion/completions/cloud-init
    install -D -m755 ../tools/write-ssh-key-fingerprints $out/libexec/write-ssh-key-fingerprints
    wrapProgram $out/libexec/write-ssh-key-fingerprints \
      --prefix PATH : "${lib.makeBinPath [ openssh ]}"
  '';

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
  ];

  buildInputs = [ systemd ];

  mesonFlags = [
    "--sysconfdir=${placeholder "out"}/etc"
    "-Dbash_completion=false"
    "-Dpython.install_env=prefix"
  ];

  propagatedBuildInputs = with python3.pkgs; [
    configobj
    jinja2
    jsonpatch
    jsonschema
    netifaces
    oauthlib
    pyserial
    pyyaml
    requests
  ];

  nativeCheckInputs = with python3.pkgs; [
    pytest7CheckHook
    httpretty
    dmidecode
    # needed for tests; at runtime we rather want the setuid wrapper
    passlib
    shadow
    responses
    pytest-mock
    pyfakefs
    coreutils
    procps
  ];

  makeWrapperArgs = [
    "--prefix"
    "PATH"
    ":"
    "${
      lib.makeBinPath [
        dmidecode
        cloud-utils.guest
        busybox
      ]
    }/bin"
  ];

  pytestFlags = [ "../tests/unittests" ];

  disabledTests = [
    # Nix build sandbox does not permit setting the setuid bit
    "test_special_permission_bits"
    # tries to create /var
    "test_dhclient_run_with_tmpdir"
    "test_dhcp_client_failover"
    # clears path and fails because mkdir is not found
    "test_path_env_gets_set_from_main"
    # tries to read from /etc/ca-certificates.conf while inside the sandbox
    "test_handler_ca_certs"
    "TestRemoveDefaultCaCerts"
    # Doesn't work in the sandbox
    "TestEphemeralDhcpNoNetworkSetup"
    "TestHasURLConnectivity"
    "TestReadFileOrUrl"
    "TestConsumeUserDataHttp"
    # Chef Omnibus
    "TestInstallChefOmnibus"
    # Disable failing VMware and PuppetAio tests
    "test_get_data_iso9660_with_network_config"
    "test_get_data_vmware_guestinfo_with_network_config"
    "test_get_host_info"
    "test_no_data_access_method"
    "test_install_with_collection"
    "test_install_with_custom_url"
    "test_install_with_default_arguments"
    "test_install_with_no_cleanup"
    "test_install_with_version"
    # https://github.com/canonical/cloud-init/issues/5002
    "test_found_via_userdata"
  ];

  preCheck = ''
    # TestTempUtils.test_mkdtemp_default_non_root does not like TMPDIR=/build
    export TMPDIR=/tmp
  '';

  pythonImportsCheck = [
    "cloudinit"
  ];

  passthru = {
    tests = { inherit (nixosTests) cloud-init cloud-init-hostname; };
    updateScript = gitUpdater { ignoredVersions = ".ubuntu.*"; };
  };

  meta = {
    homepage = "https://github.com/canonical/cloud-init";
    description = "Provides configuration and customization of cloud instance";
    changelog = "https://github.com/canonical/cloud-init/raw/${finalAttrs.version}/ChangeLog";
    license = with lib.licenses; [
      asl20
      gpl3Plus
    ];
    maintainers = with lib.maintainers; [
      illustris
      jfroche
    ];
    platforms = lib.platforms.all;
  };
})
