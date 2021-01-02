{ stdenv, callPackage, rustPlatform, fetchFromGitHub, mruby, gcc }:

let
  mruby' = mruby.overrideAttrs (oA: {
    nativeBuildInputs = oA.nativeBuildInputs ++ [ gcc ];
    src = fetchFromGitHub {
      owner = "artichoke";
      repo = "mruby";
      rev = "5aa6da1a30d78640b5775464e221d54c2c54f59c";
      sha256 = "08ybjczrkafgh5spwwcyz2z2892b3fbsk9zvp6smsyjjd54cw86y";
    };
  });
in
# mruby'
callPackage ./mruby.nix { }
# rustPlatform.buildRustPackage rec {
#   pname = "artichoke";
#   version = "unstable-2021-01-01";

#   RUST_BACKTRACE = 1;

#   src = fetchFromGitHub {
#     owner = "artichoke";
#     repo = "artichoke";
#     rev = "939fffc015255736e4f80fee422efdc88af2a620";
#     sha256 = "1yh90ywsin66xsfnwwz021l4q6l1hadizw7s38fx0vv66q7l792d";
#   };

#   # buildInputs = stdenv.lib.optionals stdenv.isDarwin [ Security ];
#   nativeBuildInputs = [ mruby ];

#   cargoSha256 = "139aszd9h3bhbnm2wiw54qn50hjp72xj71qz03kaahks7y3zyihf";

#   meta = with stdenv.lib; {
#     description = "Ruby implementation written in Rust";
#     homepage = "https://github.com/artichoke/artichoke";
#     license = licenses.mit;
#     maintainers = with maintainers; [ siraben ];
#   };
# }
