{
  evalSystem,
  lib,
  pkgs,
}:
let
  evalNvidia =
    {
      open,
      kernelModules ? [ ],
    }:
    (evalSystem {
      services.xserver = {
        enable = false;
        videoDrivers = [ "nvidia" ];
      };
      hardware.nvidia.open = open;
      boot.kernelModules = kernelModules;
    }).config;

  openConfig = evalNvidia { open = true; };
  openConfigWithExplicitUvm = evalNvidia {
    open = true;
    kernelModules = [ "nvidia_uvm" ];
  };
  proprietaryConfig = evalNvidia { open = false; };

  uvmBindRule = builtins.unsafeDiscardStringContext ''
    ACTION=="add|bind", SUBSYSTEM=="pci", DRIVER=="nvidia", RUN+="${lib.getExe' pkgs.kmod "modprobe"} nvidia_uvm"
  '';
  uvmSoftdep = "softdep nvidia post: nvidia-uvm";
in
assert !lib.elem "nvidia_uvm" openConfig.boot.kernelModules;
assert lib.elem "nvidia_uvm" openConfigWithExplicitUvm.boot.kernelModules;
assert lib.hasInfix uvmBindRule openConfig.services.udev.extraRules;
assert !lib.hasInfix uvmSoftdep openConfig.boot.extraModprobeConfig;
assert !lib.hasInfix uvmBindRule proprietaryConfig.services.udev.extraRules;
assert lib.hasInfix uvmSoftdep proprietaryConfig.boot.extraModprobeConfig;
pkgs.emptyFile
