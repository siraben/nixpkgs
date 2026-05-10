{
  lib,
  newScope,
}:

# Full-source Java bootstrap chain. Only `openjdk24` (or whichever
# stage you pin) is intended for direct use; earlier stages exist
# solely as boot JDKs for the next link.

let
  # Each stage's boot JDK is openjdk${major-1} (or openjdk8-icedtea
  # for stage 9). `jdkRepo` is always `jdk${major}u`.
  sourceStages = [
    {
      version = "9.0.4";
      gitRev = "8854ff6038bae78491314b05742c071e964d4b3f";
      srcHash = "sha256-GJsNHF8QzwAjon6raImZQVDYsLOQP0EW/Zmv7l/fSYs=";
      # Pointer/integer comparisons that gcc-15's gnu++17 default rejects
      # outright; -fpermissive doesn't cover them.
      patches = [ ./openjdk9/patches/fix-build-with-gcc15.patch ];
    }
    {
      version = "10.0.2";
      gitRev = "e45c316ba2b31366c2a1dcbd1b39f81f7e3cb445";
      srcHash = "sha256-BsSTX7WkyVOX6OjO1WDI8RnH9j065nG8gC9Wlo6p9gY=";
      patches = [ ./openjdk10/patches/fix-build-with-gcc15.patch ];
    }
    {
      version = "11.0.28";
      gitRev = "141d7af9cd3c41de974c3d3f8017d6b21dc6d36c";
      srcHash = "sha256-yJljuO6jflh6kbe4ipflPiNDbKvKyA4grMAFu4UCM+Y=";
      patches = [ ./openjdk11/patches/fix-c23-empty-parens.patch ];
    }
    {
      version = "12.0.2";
      gitRev = "jdk-12.0.2-ga";
      srcHash = "sha256-c7HKYceKNplC/Bb+GR21gsYI0Svt4AOq/TkgnwhdheY=";
      patches = [
        ./openjdk12/patches/JDK-8241296.patch
        ./openjdk12/patches/make-4.3.patch
      ];
    }
    {
      version = "13.0.14";
      gitRev = "jdk-13.0.14-ga";
      srcHash = "sha256-pRzVwCej1NqmMcID//wxDHerFU4sgV8RlxNDBXOJIu0=";
    }
    {
      version = "14.0.2";
      gitRev = "a718f22fc087a923ccb873ee76d8f0b2e6a16863";
      srcHash = "sha256-Bjueu3HnS0IqLZn11qsJKaqm4bYmfVCs+MJ53pdeaR4=";
    }
    {
      version = "15.0.10";
      gitRev = "2357372439135daf40d69b34bf9a48d16768b666";
      srcHash = "sha256-/VwtAMJn/bFOQDRVMcHWoKMwoxwHLpFSNZovRMamtEE=";
    }
    {
      version = "16.0.2";
      gitRev = "3b56f0b15cee132d6366e8ec03e05c918a42b4f1";
      srcHash = "sha256-/8XHNrf9joCCXMCyPncT54JhqlF+KBL7eAf8hUW/BxU=";
    }
    {
      version = "17.0.16";
      gitRev = "162dbac82cf31c6948414944af836187aff9e6ca";
      srcHash = "sha256-YN9mPfi3oMGjeRIren2cdWWySpYXsIcOnP29Zh3ym8c=";
    }
    {
      version = "18.0.2.1";
      gitRev = "823b5c16e97921e62154faef9bf285d16e1bb64e";
      srcHash = "sha256-L6dsN0kqWcfemM8LBg62qtHQdymwRQoV1ndc8r+0qn8=";
    }
    {
      version = "19.0.2";
      gitRev = "1ea4fe35ee49a3672d038bd5200f7750eaf6e18d";
      srcHash = "sha256-pBEHmBtIgG4Czou4C/zpBBYZEDImvXiLoA5CjOzpeyI=";
    }
    {
      version = "20.0.2";
      gitRev = "0660291f832e766d10838088c7251af956dc18a6";
      srcHash = "sha256-CZH2JwR+MrkTlLdcVYuFRB3McdrM0A+1YaSjNpjYwak=";
    }
    {
      version = "21.0.9";
      gitRev = "643cd2bbc86ec2e5c3b1bcfc0c4fdbdd857bea59";
      srcHash = "sha256-VYTitbgKgd9co9LXVnneaaKjMwAXFmscYp9McJV01Jg=";
    }
    {
      version = "22.0.2";
      gitRev = "1e23fd3990562e79c1a4d4cb28550d5430a2a03f";
      srcHash = "sha256-Zo1LOumkt9zTaPqbDcRL8lVJMqVle0QqzThtIz0JRNo=";
    }
    {
      version = "23.0.2";
      gitRev = "0dbd39c39c20a1f0c7017768c930bba10589e77c";
      srcHash = "sha256-zlL2DV6iOfV3hgq/Ci95gTwVrhcvz5MWsg4/+O2ntE8=";
    }
    {
      version = "24.0.2";
      gitRev = "c7abb957cb125f7a8c7e10cf1cc1499022c9e6e5";
      srcHash = "sha256-YgkTSh7U/tJxiJIi8fxCkVgcogMQbcN4PgjmlcHcOBE=";
    }
  ];
in

lib.makeScope newScope (
  self:
  let
    mkSourceStage =
      stage:
      let
        major = lib.versions.major stage.version;
        prev = toString (lib.toInt major - 1);
      in
      lib.nameValuePair "openjdk${major}" (
        self.jdk-source-build (
          stage
          // {
            jdkRepo = "jdk${major}u";
            boot-jdk = self."openjdk${prev}" or self.openjdk8-icedtea;
          }
        )
      );
  in
  {
    gcc6-with-gcj = self.callPackage ./gcc6-with-gcj { };
    fastjar = self.callPackage ./fastjar { };
    java-gcj-compat = self.callPackage ./java-gcj-compat { };
    openjdk7-icedtea = self.callPackage ./openjdk7-icedtea { };
    openjdk8-icedtea = self.callPackage ./openjdk8-icedtea {
      boot-jdk = self.openjdk7-icedtea;
    };
    jdk-source-build = self.callPackage ./jdk-source-build.nix { };
  }
  // lib.listToAttrs (map mkSourceStage sourceStages)
)
