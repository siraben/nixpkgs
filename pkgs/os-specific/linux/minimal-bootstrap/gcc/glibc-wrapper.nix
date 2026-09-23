{ bash, gcc, libgcc, libstdcxx, libgccSpec, glibc, binutils, hostPlatform }:
let
  pname = "gcc";
  version = gcc.version;
  triple = hostPlatform.config;
  loader = {
    x86_64-linux = "ld-linux-x86-64.so.2";
    i686-linux = "ld-linux.so.2";
  }.${hostPlatform.system};
in
bash.runCommand "${pname}-${version}" {
  inherit pname version;
  meta = gcc.meta;
  passthru = {
    unwrapped = gcc;
    tests.hello-world = result: bash.runCommand "gcc-simple-program-${version}" {
      nativeBuildInputs = [ binutils result ];
    } ''
      cat > test.c <<'EOF'
      #include <stdio.h>
      int main(void) { puts("Hello World!"); return 0; }
      EOF
      gcc test.c -o test
      ./test
      mkdir $out
    '';
  };
} ''
  mkdir -p $out/bin $out/lib/gcc/${triple}/${version}/include $out/include $out/nix-support/runtime
  runtimeDir=$out/lib/gcc/${triple}/${version}
  for f in ${gcc}/lib/gcc/${triple}/${version}/include/*; do
    ln -s "$f" "$runtimeDir/include/$(basename "$f")"
  done
  for f in ${libgcc}/lib/gcc/${triple}/${version}/include/*; do
    ln -sfnT "$f" "$runtimeDir/include/$(basename "$f")"
  done
  for f in ${libgcc}/lib/gcc/${triple}/${version}/*; do
    [ "$(basename "$f")" = include ] && continue
    ln -s "$f" "$runtimeDir/$(basename "$f")"
    # A fallback -B prefix must not inject additional header directories.
    if [ ! -d "$f" ]; then
      ln -s "$f" "$out/nix-support/runtime/$(basename "$f")"
    fi
  done
  for f in ${libstdcxx}/lib/*; do
    ln -s "$f" "$out/lib/$(basename "$f")"
  done
  ln -s ${libstdcxx}/include/c++ $out/include/c++
  ln -s ${gcc}/libexec $out/libexec
  ln -s lib $out/lib64
  cp ${libgccSpec} $out/nix-support/libgcc.specs

  # Let GCC choose the input language and honor the caller's include switches.
  cat > $out/nix-support/headers.specs <<EOF
%rename link bootstrap_original_link
%rename cpp_unique_options bootstrap_original_cpp_unique_options

*link:
%(bootstrap_original_link) -dynamic-linker=${glibc}/lib/${loader} -rpath ${glibc}/lib -rpath ${libgcc}/lib/gcc/${triple}/${version} -rpath ${libstdcxx}/lib

*cpp_unique_options:
-nostdinc %{!nostdinc:%{!nostdinc++:%{,c++|,c++-header|,c++-system-header|,c++-user-header:-idirafter ${libstdcxx}/include/c++/${version} -idirafter ${libstdcxx}/include/c++/${version}/${triple} -idirafter ${libstdcxx}/include/c++/${version}/backward}} -idirafter $runtimeDir/include -idirafter ${glibc}/include} %(bootstrap_original_cpp_unique_options)

EOF
  for orig in ${gcc}/bin/*; do
    name=$(basename "$orig")
    case "$name" in
      gcc|*-gcc|gcc-${version}|*-gcc-${version}|cc|g++|*-g++|c++|*-c++|cpp|*-cpp)
        # The reused musl driver's --disable-shared configuration omits the
        # usual g++ default. Caller switches still follow and override it.
        case "$name" in
          g++|*-g++|c++|*-c++) defaultLibgcc=-shared-libgcc ;;
          *) defaultLibgcc= ;;
        esac
        cat > "$out/bin/$name" <<EOF
#!${bash}/bin/bash
export PATH="\$PATH:${binutils}/bin"
if [ "\$#" = 1 ] && [ "\$1" = -v ]; then exec "$orig" -v; fi
exec "$orig" -mglibc $defaultLibgcc -specs=$out/nix-support/libgcc.specs -specs=$out/nix-support/headers.specs \\
  "\$@" -B$out/nix-support/runtime/ -B${glibc}/lib/ -B${libstdcxx}/lib/ -L${libstdcxx}/lib
EOF
        chmod +x "$out/bin/$name"
        ;;
      *) ln -s "$orig" "$out/bin/$name" ;;
    esac
  done
''
