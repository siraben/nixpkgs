{stdenv, fetchurl}:

stdenv.mkDerivation {
  name = "fribidi-0.10.7";
  src = fetchurl {
    url = http://fribidi.org/download/fribidi-0.10.7.tar.gz;
    md5 = "0cd9e69207e1c847c25c4b9d58f1544e";
  };
}
