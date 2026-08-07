{
  linkFarm,
  maven,
  unzip,
}:

let
  archiveTest =
    {
      name,
      expectedTimestamp,
      mvnParameters ? "",
    }:
    maven.buildMavenPackage {
      pname = "maven-reproducible-archives-${name}-test";
      version = "1.0";

      src = ./reproducible-archives;

      mvnHash = "sha256-f77F8jGEOqt1UKfmG0yjqp8g553y1zs2/LP6+8CGLRs=";
      inherit mvnParameters;

      doCheck = false;

      installPhase = ''
        runHook preInstall

        mkdir -p $out
        cp jar-module/target/jar-module-1.0.jar $out/
        cp assembly-module/target/assembly-module-1.0-jar-with-dependencies.jar $out/

        for archive in $out/*.jar; do
          ${unzip}/bin/zipinfo -T "$archive" | awk '
            $7 ~ /^[0-9]/ && $7 != "${expectedTimestamp}" {
              print "unexpected archive timestamp: " $0 > "/dev/stderr"
              failed = 1
            }
            END { exit failed }
          '
        done

        runHook postInstall
      '';
    };
in
linkFarm "maven-reproducible-archives-tests" {
  default = archiveTest {
    name = "default";
    expectedTimestamp = "19800101.000002";
  };
  package-override = archiveTest {
    name = "package-override";
    expectedTimestamp = "20010203.040506";
    # buildMavenPackage prepends its default, so this duplicate CLI property
    # verifies that package-supplied mvnParameters takes precedence.
    mvnParameters = "-Dproject.build.outputTimestamp=2001-02-03T04:05:06Z";
  };
}
