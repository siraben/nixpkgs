{
  lib,
  stdenv,
  fetchFromGitHub,
  kernel,
  kernelModuleMakeFlags,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "akvcam";
  version = "1.4.0";

  src = fetchFromGitHub {
    owner = "webcamoid";
    repo = "akvcam";
    rev = finalAttrs.version;
    sha256 = "sha256-hjWmjMOxq1wX9/7RB+pUSPq/CxBzNOwV7VsYfbdrww4=";
  };
  sourceRoot = "${finalAttrs.src.name}/src";

  nativeBuildInputs = kernel.moduleBuildDependencies;
  makeFlags = kernelModuleMakeFlags ++ [
    "KERNEL_DIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
  ];

  installPhase = ''
    install -m644 -b -D akvcam.ko $out/lib/modules/${kernel.modDirVersion}/akvcam.ko
  '';

  enableParallelBuilding = true;

  meta = {
    description = "Virtual camera driver for Linux";
    homepage = "https://github.com/webcamoid/akvcam";
    maintainers = [ ];
    platforms = lib.platforms.linux;
    license = lib.licenses.gpl2Only;
  };
})
