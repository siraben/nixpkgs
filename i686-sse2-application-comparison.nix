# Explicit application comparison on SSE2-capable i686 hardware. This does not
# alter the integration package defaults or claim generic-x87 correctness.
let
  pkgs = import /home/siraben/i686-iso-work/refresh-20261111/nixpkgs {
    system = "i686-linux";
    overlays = [
      (final: prev: {
        # Existing OpenColorIO #536904 approach, not a new CPU-policy proposal.
        # Use a package-set overlay so apps/plugins share one coherent OCIO.
        opencolorio = prev.opencolorio.overrideAttrs (old: {
          doCheck = true;
          env = old.env // {
            CXXFLAGS = old.env.CXXFLAGS + " -mfpmath=sse -msse2";
          };
        });
      })
    ];
  };
in
{
  krita = pkgs.krita;
  tlrender = pkgs.tlrender;
  djv = pkgs.djv;
}
