{
  lib,
  stdenv,
  stdenvNoCC,
  gcc6-with-gcj,
  fastjar,
  zlib,
}:

# Synthetic JDK 1.5: AOT-compiles ECJ via gcj into a native javac, then
# stitches a JAVA_HOME layout together from gcj-6 tools and fastjar.
# Just barely enough to drive IcedTea 2.x's OpenJDK 7 bootstrap.

stdenvNoCC.mkDerivation {
  pname = "java-gcj-compat";
  inherit (gcc6-with-gcj) version;

  # No upstream source; this is purely an assembly recipe.
  dontUnpack = true;

  nativeBuildInputs = [ gcc6-with-gcj ];

  buildPhase = ''
    runHook preBuild

    gcc6=${gcc6-with-gcj}

    # libgcj jars may live in lib, lib64, or share/java depending on multilib.
    for d in "$gcc6/lib" "$gcc6/lib64" "$gcc6/share/java"; do
      if [ -e "$d/libgcj-${gcc6-with-gcj.version}.jar" ]; then
        libgcj_dir=$d
        break
      fi
    done
    : "''${libgcj_dir:?could not find libgcj-*.jar in $gcc6}"

    for f in "$gcc6/share/java/ecj.jar" "$gcc6/share/java/ecj-4.9.jar" "${gcc6-with-gcj.ecjJar}"; do
      if [ -e "$f" ]; then
        ecj_jar=$f
        break
      fi
    done
    : "''${ecj_jar:?could not find ecj.jar}"

    install -d $out/lib/jvm/java-1.5-gcj/{bin,lib,jre/lib}

    # stdenvNoCC has no CC wrapper, so supply CRT paths and runtime libs by hand.
    glibc_lib="${lib.getLib stdenv.cc.libc}/lib"
    gcc6_runtime=$(dirname "$(find $gcc6 -name 'libgcc_s.so' | head -1)")
    "$gcc6/bin/gcj-6.5" \
      -B"$glibc_lib" -L"$glibc_lib" -L"$gcc6_runtime" -L"${zlib.out}/lib" \
      -Wl,-Bsymbolic -findirect-dispatch \
      -Wl,-rpath="$gcc6_runtime" \
      -o $out/lib/jvm/java-1.5-gcj/bin/javac \
      --main=org.eclipse.jdt.internal.compiler.batch.Main \
      "$ecj_jar" -lgcj

    # Some tools (e.g. sinjdoc) are not built; skip silently.
    link_if_exists() {
      [ -e "$1" ] && ln -s "$1" "$2" || true
    }
    link_if_exists "$gcc6/bin/gij-6.5"           $out/lib/jvm/java-1.5-gcj/bin/java
    link_if_exists "$gcc6/bin/gjavah-6.5"        $out/lib/jvm/java-1.5-gcj/bin/javah
    ln -s          ${fastjar}/bin/fastjar        $out/lib/jvm/java-1.5-gcj/bin/jar
    link_if_exists "$gcc6/bin/sinjdoc"           $out/lib/jvm/java-1.5-gcj/bin/javadoc
    link_if_exists "$gcc6/bin/grmic-6.5"         $out/lib/jvm/java-1.5-gcj/bin/rmic
    link_if_exists "$gcc6/bin/gkeytool-6.5"      $out/lib/jvm/java-1.5-gcj/bin/keytool
    link_if_exists "$gcc6/bin/grmiregistry-6.5"  $out/lib/jvm/java-1.5-gcj/bin/rmiregistry
    link_if_exists "$gcc6/bin/gjarsigner-6.5"    $out/lib/jvm/java-1.5-gcj/bin/jarsigner
    link_if_exists "$gcc6/bin/gappletviewer-6.5" $out/lib/jvm/java-1.5-gcj/bin/appletviewer
    link_if_exists "$gcc6/bin/gnative2ascii-6.5" $out/lib/jvm/java-1.5-gcj/bin/native2ascii
    link_if_exists "$gcc6/bin/gserialver-6.5"    $out/lib/jvm/java-1.5-gcj/bin/serialver
    link_if_exists "$gcc6/bin/gorbd-6.5"         $out/lib/jvm/java-1.5-gcj/bin/orbd
    link_if_exists "$gcc6/bin/gtnameserv-6.5"    $out/lib/jvm/java-1.5-gcj/bin/tnameserv

    ln -s "$libgcj_dir/libgcj-tools-${gcc6-with-gcj.version}.jar" \
      $out/lib/jvm/java-1.5-gcj/lib/tools.jar
    ln -s "$libgcj_dir/libgcj-${gcc6-with-gcj.version}.jar" \
      $out/lib/jvm/java-1.5-gcj/jre/lib/rt.jar
    ln -s lib/jvm/java-1.5-gcj $out/jdk

    runHook postBuild
  '';

  dontInstall = true;

  passthru.home = "${placeholder "out"}/lib/jvm/java-1.5-gcj";

  meta = {
    description = "Synthetic JDK 1.5 from gcj+ECJ";
    homepage = "https://www.gnu.org/software/classpath/";
    license = lib.licenses.gpl3Plus;
    platforms = [
      "x86_64-linux"
      "i686-linux"
    ];
  };
}
