{
  lib,
  mkHyprlandPlugin,
  fetchFromGitHub,
  cmake,
  doctest,
  meson,
  ninja,
  wf-touch,
  nix-update-script,
}:

mkHyprlandPlugin {
  pluginName = "hyprgrass";
  version = "0.8.2-unstable-2026-11-01";

  src = fetchFromGitHub {
    owner = "horriblename";
    repo = "hyprgrass";
    rev = "355ee6e6e95bdfdf051d8f23eba4973ae6a21bd7";
    hash = "sha256-sm9HmtGcqJJ44eiaik+OO6j0NA38Lahq0ad8yrLmAEE=";
  };

  nativeBuildInputs = [
    cmake
    doctest
    meson
    ninja
  ];

  buildInputs = [
    (wf-touch.overrideAttrs {
      version = "0-unstable-2021-03-19";
      src = fetchFromGitHub {
        owner = "WayfireWM";
        repo = "wf-touch";
        rev = "8974eb0f6a65464b63dd03b842795cb441fb6403";
        hash = "sha256-MjsYeKWL16vMKETtKM5xWXszlYUOEk3ghwYI85Lv4SE=";
      };
    })
  ];

  dontUseCmakeConfigure = true;

  doCheck = true;

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch" ]; };

  meta = {
    description = "Hyprland plugin for touch gestures";
    homepage = "https://github.com/horriblename/hyprgrass";
    license = lib.licenses.bsd3;
    maintainers = with lib.maintainers; [ donovanglover ];
    platforms = lib.platforms.linux;
  };
}
