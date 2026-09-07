{
  stdenv,
  lib,
  fetchurl,
  pkg-config,
  makeWrapper,
  libusb1,
  tcl,
  util-linux,
  coreutils,
  bash,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "usb-modeswitch";
  version = "2.6.2";

  src = fetchurl {
    url = "https://www.draisberghof.de/usb_modeswitch/usb-modeswitch-${finalAttrs.version}.tar.bz2";
    hash = "sha256-96vTN3hKnRvTnLilh1GK/28qQ9kWFF6v2Asbi3FG22Y=";
  };

  patches = [
    ./configurable-usb-modeswitch.patch
    ./pkg-config.patch
  ];

  # Remove attempts to write to /etc and /var/lib.
  postPatch = ''
    sed -i \
      -e '/^\tinstall .* usb_modeswitch.conf/s,$(ETCDIR),$(out)/etc,' \
      -e '\,^\tinstall -d .*/var/lib/usb_modeswitch,d' \
      Makefile
  '';

  makeFlags = [
    "PREFIX=$(out)"
    "ETCDIR=/etc"
    "USE_UPSTART=false"
    "USE_SYSTEMD=true"
    "SYSDIR=$(out)/lib/systemd/system"
    "UDEVDIR=$(out)/lib/udev"
  ];

  postFixup = ''
    wrapProgram $out/bin/usb_modeswitch_dispatcher \
      --set PATH ${
        lib.makeBinPath [
          util-linux
          coreutils
          bash
        ]
      }
  '';

  doInstallCheck = true;

  installCheckPhase = ''
    runHook preInstallCheck

    unit="$out/lib/systemd/system/usb_modeswitch@.service"
    helper="$out/lib/udev/usb_modeswitch"

    test -f "$unit"
    test -x "$helper"
    test -x "$out/sbin/usb_modeswitch_dispatcher"
    grep -Fqx "ExecStart=$out/sbin/usb_modeswitch_dispatcher --switch-mode %i" "$unit"
    grep -Fqx "SBINDIR=$out/sbin" "$helper"
    ! grep -Eq '(^|[^[:alnum:]_])(readlink|basename)([^[:alnum:]_]|$)' "$helper"

    runHook postInstallCheck
  '';

  buildInputs = [
    libusb1
    tcl
  ];

  nativeBuildInputs = [
    pkg-config
    makeWrapper
  ];

  meta = {
    description = "Mode switching tool for controlling 'multi-mode' USB devices";
    license = lib.licenses.gpl2;
    maintainers = with lib.maintainers; [
      peterhoeg
    ];
    platforms = lib.platforms.linux;
    mainProgram = "usb_modeswitch";
  };
})
