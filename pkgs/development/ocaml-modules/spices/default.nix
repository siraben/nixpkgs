{
  lib,
  buildDunePackage,
  fetchurl,
  colors,
  tty,
}:

buildDunePackage (finalAttrs: {
  pname = "spices";
  version = "0.0.2";

  minimalOCamlVersion = "5.1";

  src = fetchurl {
    url = "https://github.com/leostera/minttea/releases/download/${finalAttrs.version}/minttea-${finalAttrs.version}.tbz";
    hash = "sha256-0eB7OuxcPdv9bf2aIQEeir44mQfx5W2AJj7Vb4pGtLI=";
  };

  propagatedBuildInputs = [
    colors
    tty
  ];

  doCheck = true;

  meta = {
    description = "Declarative styles for TUI applications";
    homepage = "https://github.com/leostera/minttea";
    changelog = "https://github.com/leostera/minttea/blob/${finalAttrs.version}/CHANGES.md";
    license = lib.licenses.mit;
    maintainers = [ ];
  };
})
