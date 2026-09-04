{
  stdenv,
  lib,
  perl,
  pandoc,
  fetchFromGitHub,
  makeWrapper,
  xdotool,
  wmctrl,
  xprop,
  net-tools,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "jumpapp";
  version = "1.2";

  strictDeps = true;
  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "mkropat";
    repo = "jumpapp";
    tag = "v${finalAttrs.version}";
    hash = "sha256-9sh0+zpDxwqRGC1jUgGTDdSDRdAFsL12mQ/Opwh/UBc=";
  };

  makeFlags = [ "PREFIX=${placeholder "out"}" ];
  nativeBuildInputs = [
    makeWrapper
    pandoc
    perl
  ];
  buildInputs = [
    xdotool
    wmctrl
    xprop
    net-tools
    perl
  ];
  postFixup = ''
    wrapProgram $out/bin/jumpapp \
      --prefix PATH : ${lib.makeBinPath finalAttrs.buildInputs}
    wrapProgram $out/bin/jumpappify-desktop-entry \
      --prefix PATH : ${lib.getBin perl}/bin
  '';

  meta = {
    homepage = "https://github.com/mkropat/jumpapp";
    description = "Run-or-raise application switcher for any X11 desktop";
    license = lib.licenses.mit;
    maintainers = [ lib.maintainers.matklad ];
    mainProgram = "jumpapp";
  };
})
