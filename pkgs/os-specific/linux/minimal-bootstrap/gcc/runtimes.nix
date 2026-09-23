{ fetchurl, bash, buildPlatform, hostPlatform, gcc, gcc-buildbuild,
  glibc, binutils, gnumake, gnused, gnugrep, gawk, diffutils, findutils,
  gnutar, xz }:
let
  version = "15.3.0";
  triple = hostPlatform.config;
  libgccSpec = builtins.toFile "glibc-libgcc.specs" ''
    *libgcc:
    %{static|static-libgcc|static-pie:-lgcc -lgcc_eh}%{!static:%{!static-libgcc:%{!static-pie:%{!shared-libgcc:-lgcc --push-state --as-needed -lgcc_s --pop-state}%{shared-libgcc:-lgcc_s%{!shared: -lgcc}}}}}

  '';
  source = fetchurl {
    url = "mirror://gnu/gcc/gcc-${version}/gcc-${version}.tar.xz";
    hash = "sha256-+lnBvu+JlfJ8TXHB3yJ1hxiTFdPm+v8btDBuYbDFMOs=";
  };
  hostcc = gcc-buildbuild;
  targetcc = gcc;
  support = gcc.support;
  tools = [ hostcc binutils gnumake gnused gnugrep gawk diffutils findutils gnutar xz ];
  loader = if hostPlatform.system == "x86_64-linux" then "ld-linux-x86-64.so.2" else "ld-linux.so.2";
  targetFlags = "-mglibc -nostdinc -isystem ${gcc}/lib/gcc/${triple}/${version}/include -isystem ${glibc}/include -B${binutils}/bin/ -B${glibc}/lib/";
  libgcc = bash.runCommand "bootstrap-glibc-libgcc-${version}" {
    inherit version;
    pname = "libgcc";
    nativeBuildInputs = tools;
  } ''
    tar xf ${source}
    S=$PWD/gcc-${version}
    mkdir work
    cd work
    mkdir -p build-${triple}/libiberty gcc
    ln -s ${support}/lib/libiberty.a build-${triple}/libiberty/libiberty.a
    cd gcc
    export CC_FOR_BUILD="${hostcc}/bin/gcc -I${support}/include"
    export CXX_FOR_BUILD="${hostcc}/bin/g++ -I${support}/include"
    export CPP_FOR_BUILD="${hostcc}/bin/gcc -E -I${support}/include"
    export AS_FOR_BUILD=${binutils}/bin/as
    export LD_FOR_BUILD=${binutils}/bin/ld
    export OBJDUMP_FOR_BUILD=${binutils}/bin/objdump
    export CC="$CC_FOR_BUILD" CXX="$CXX_FOR_BUILD" CPP="$CPP_FOR_BUILD"
    export AS="$AS_FOR_BUILD" LD="$LD_FOR_BUILD" OBJDUMP="$OBJDUMP_FOR_BUILD"
    export CFLAGS=-O1 CXXFLAGS=-O1
    export LDFLAGS="-L${support}/lib"
    export CC_FOR_TARGET="${targetcc}/bin/gcc ${targetFlags}"
    export CPP_FOR_TARGET="${targetcc}/bin/gcc -E ${targetFlags}"
    export AS_FOR_TARGET=${binutils}/bin/as
    export LD_FOR_TARGET=${binutils}/bin/ld
    export OBJDUMP_FOR_TARGET=${binutils}/bin/objdump
    export CFLAGS_FOR_BUILD=-DGENERATOR_FILE=1
    bash "$S/gcc/configure" \
      --build=${triple} --host=${triple} --target=${triple} \
      --disable-multilib --enable-languages=c \
      --disable-nls --disable-plugin --disable-libssp \
      --with-sysroot=/ --with-native-system-header-dir=${glibc}/include
    sed -i 's,libgcc.mvars:.*$,libgcc.mvars:,' Makefile
    make -j $NIX_BUILD_CORES CFLAGS_FOR_TARGET=-O0 config.h libgcc.mvars tconfig.h tm.h options.h insn-constants.h version.h
    mkdir -p include ${triple}/libgcc
    cd ${triple}/libgcc
    export CC=${targetcc}/bin/gcc
    export CPP="${targetcc}/bin/gcc -E ${targetFlags}"
    export CFLAGS="-O0 ${targetFlags}"
    export LDFLAGS="-B${glibc}/lib -L${glibc}/lib -Wl,-dynamic-linker=${glibc}/lib/${loader}"
    bash "$S/libgcc/configure" \
      --prefix=$out --build=${triple} --host=${triple} \
      --enable-shared \
      gcc_cv_target_thread_file=posix cross_compiling=true
    make -j $NIX_BUILD_CORES MULTIBUILDTOP:=../
    make -j $NIX_BUILD_CORES install-strip MULTIBUILDTOP:=../
    mkdir -p $out/include $out/lib/gcc/${triple}/${version}
    cp gthr-default.h $out/include/
    shopt -s nullglob
    for f in $out/lib64/* $out/lib/*.*; do
      mv "$f" $out/lib/gcc/${triple}/${version}/
    done
    test -e $out/lib/gcc/${triple}/${version}/libgcc.a
    test -e $out/lib/gcc/${triple}/${version}/libgcc_eh.a
    test -e $out/lib/gcc/${triple}/${version}/libgcc_s.so.1
  '';
  runtime = libgcc;
  libstdcxx = bash.runCommand "bootstrap-glibc-libstdcxx-${version}" {
    inherit version;
    pname = "libstdcxx";
    nativeBuildInputs = tools;
  } ''
    tar xf ${source}
    S=$PWD/gcc-${version}
    mkdir build
    cd build
    export CC=${targetcc}/bin/gcc CXX=${targetcc}/bin/g++
    export CPPFLAGS="${targetFlags}"
    # The reused compiler was configured with static musl libgcc only.
    export CFLAGS="-O0 -specs=${libgccSpec} ${targetFlags} -B${glibc}/lib -B${runtime}/lib/gcc/${triple}/${version}/"
    export CXXFLAGS="$CFLAGS -I${libgcc}/include"
    export LDFLAGS="-B${glibc}/lib -B${runtime}/lib/gcc/${triple}/${version}/ -L${glibc}/lib -Wl,-rpath,${runtime}/lib/gcc/${triple}/${version} -Wl,-dynamic-linker=${glibc}/lib/${loader}"
    export AR=${binutils}/bin/ar NM=${binutils}/bin/nm
    export RANLIB=${binutils}/bin/ranlib OBJCOPY=${binutils}/bin/objcopy
    export MAKEINFO=true
    bash "$S/libstdc++-v3/configure" \
      --prefix=$out --libdir=$out/lib --build=${triple} --host=${triple} \
      --disable-multilib \
      --enable-shared --enable-static --enable-clocale=gnu \
      --disable-libstdcxx-pch --disable-vtable-verify \
      --enable-libstdcxx-visibility --with-default-libstdcxx-abi=new \
      --disable-libstdcxx-backtrace --disable-libstdcxx-filesystem-ts \
      gcc_cv_target_thread_file=posix cross_compiling=true
    grep -q '^#define _GLIBCXX_HAS_GTHREADS 1' config.h
    make -j $NIX_BUILD_CORES
    make -j $NIX_BUILD_CORES install-strip
    if [ -d $out/lib64 ]; then
      mkdir -p $out/lib
      shopt -s dotglob
      for f in $out/lib64/*; do
        mv --no-clobber "$f" $out/lib/
      done
      shopt -u dotglob
      rmdir $out/lib64
      ln -s lib $out/lib64
    fi
    test -e $out/lib/libstdc++.so.6
    test -e $out/lib/libstdc++.a
    rm -rf $out/share
  '';
in { inherit libgcc libstdcxx libgccSpec; }
