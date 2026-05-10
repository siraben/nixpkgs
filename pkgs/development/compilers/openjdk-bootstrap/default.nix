{
  lib,
  newScope,
}:

# Full-source Java bootstrap chain. Only the terminal source-build
# stage is intended for direct use; earlier stages exist solely as
# boot JDKs for the next link.

lib.makeScope newScope (self: {
  gcc6-with-gcj = self.callPackage ./gcc6-with-gcj { };
  fastjar = self.callPackage ./fastjar { };
  java-gcj-compat = self.callPackage ./java-gcj-compat { };
  openjdk7-icedtea = self.callPackage ./openjdk7-icedtea { };
  openjdk8-icedtea = self.callPackage ./openjdk8-icedtea {
    boot-jdk = self.openjdk7-icedtea;
  };
})
