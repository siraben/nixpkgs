{
  lib,
  stdenv,
  fetchurl,
  apr,
  jdk,
  openssl,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "tomcat-native";
  version = "2.0.15";

  src = fetchurl {
    url = "mirror://apache/tomcat/tomcat-connectors/native/${finalAttrs.version}/source/tomcat-native-${finalAttrs.version}-src.tar.gz";
    hash = "sha256-jasJ8hrVGcnknlKH+NjeibsXal45aEefJ5SMMbKjtrQ=";
  };

  sourceRoot = "tomcat-native-${finalAttrs.version}-src/native";

  buildInputs = [
    apr
    jdk
    openssl
  ];

  configureFlags = [
    "--with-apr=${apr.dev}"
    "--with-java-home=${jdk}"
    "--with-ssl=${openssl.dev}"
  ];

  meta = {
    description = "Optional component for use with Apache Tomcat that allows Tomcat to use certain native resources for performance, compatibility, etc";
    homepage = "https://tomcat.apache.org/native-doc/";
    license = lib.licenses.asl20;
    platforms = lib.platforms.unix;
    maintainers = with lib.maintainers; [ aanderse ];
  };
})
