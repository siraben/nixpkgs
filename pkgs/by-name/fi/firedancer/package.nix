{ lib
, stdenv
, fetchFromGitHub
, openssl
, zlib
, lz4
, zstd
, git
, perl
, python3
, cmake
, protobuf
, pkg-config
, curl
, hostname
, rustPlatform
, cargo
, rustc
, rocksdb
, rust-jemalloc-sys-unprefixed
, cacert
, snappy
, secp256k1
, libclang
, llvmPackages
, enableRust ? false  # Disabled due to borsh proc macro issues in vendored environment
, enableShared ? false
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "firedancer";
  version = "0.701.20300";

  src = fetchFromGitHub {
    owner = "firedancer-io";
    repo = "firedancer";
    rev = "v${finalAttrs.version}";
    sha256 = "sha256-Zu+Hx2mK4MSb7mW9tgil/lIAfflcotJkFpFUQ/aHD8I=";
    fetchSubmodules = true;
    # The build process requires git information for versioning
    leaveDotGit = true;
    postFetch = ''
      cd "$out"
      git rev-parse HEAD > .git_commit
      rm -rf .git
    '';
  };

  cargoRoot = if enableRust then "agave" else null;
  
  cargoDeps = if enableRust then rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) src cargoRoot;
    hash = "sha256-ur1tcQ+3+6ExDRZmGjsPZq/NQ/iGKHDr7BxYD53rBRg=";
  } else null;


  nativeBuildInputs = [
    git
    perl
    python3
    cmake
    protobuf
    pkg-config
    curl
    hostname
  ] ++ lib.optionals enableRust [
    rustPlatform.cargoSetupHook
    cargo
    rustc
    libclang
  ];

  buildInputs = [
    openssl
    zlib
    lz4
    zstd
    secp256k1
  ] ++ lib.optionals enableRust [
    rocksdb
    rust-jemalloc-sys-unprefixed
    snappy  # rocksdb dependency
  ];

  postUnpack = ''
    # Make deps.sh executable
    chmod +x $sourceRoot/deps.sh
  '';

  postPatch = ''
    # Remove git status call from the build system
    substituteInPlace config/everything.mk \
      --replace-fail "git status --porcelain=2 --branch >> \$(OBJDIR)/info" "echo '# git info unavailable' >> \$(OBJDIR)/info"
      
    # Fix CPPFLAGS and LDFLAGS to use absolute OPT path without ./
    substituteInPlace config/base.mk \
      --replace-fail './$(OPT)/include' '$(OPT)/include' \
      --replace-fail '-L./$(OPT)/lib' '-L$(OPT)/lib'
      
    # Force enable libraries by overriding the detection
    # Replace the entire with-*.mk files to override their behavior
    cat > config/extra/with-lz4.mk << EOF
FD_HAS_LZ4:=1
CFLAGS+=-DFD_HAS_LZ4=1
CPPFLAGS+=-I${lz4.dev}/include
LDFLAGS+=-L${lz4.out}/lib -llz4
EOF
    
    cat > config/extra/with-zstd.mk << EOF
FD_HAS_ZSTD:=1
CFLAGS+=-DFD_HAS_ZSTD=1
CPPFLAGS+=-I${zstd.dev}/include
LDFLAGS+=-L${zstd.out}/lib -lzstd
EOF
    
    cat > config/extra/with-openssl.mk << EOF
FD_HAS_OPENSSL:=1
CFLAGS+=-DFD_HAS_OPENSSL=1
CPPFLAGS+=-DFD_HAS_OPENSSL=1 -I${openssl.dev}/include
LDFLAGS+=-L${openssl.out}/lib -lssl -lcrypto
EOF

    cat > config/extra/with-secp256k1.mk << EOF
FD_HAS_SECP256K1:=1
CFLAGS+=-DFD_HAS_SECP256K1=1
CPPFLAGS+=-I${secp256k1}/include
LDFLAGS+=-L${secp256k1}/lib -lsecp256k1
EOF
    
    ${lib.optionalString enableRust ''
      # Force enable rocksdb for Rust build
      cat > config/extra/with-rocksdb.mk << EOF
FD_HAS_ROCKSDB:=1
CPPFLAGS+=-DFD_HAS_ROCKSDB=1 -DROCKSDB_LITE=1 -I${rocksdb}/include
LDFLAGS+=-L${rocksdb}/lib -lrocksdb -L${snappy}/lib -lsnappy
EOF
    ''}
    
    # Use the saved git commit hash
    if [ -f .git_commit ]; then
      export GIT_COMMIT=$(cat .git_commit)
      substituteInPlace src/app/fdctl/with-version.mk \
        --replace-fail '$(shell git rev-parse HEAD)' "$GIT_COMMIT"
      substituteInPlace src/app/firedancer/version.mk \
        --replace-fail '$(shell git rev-parse HEAD)' "$GIT_COMMIT"
    else
      substituteInPlace src/app/fdctl/with-version.mk \
        --replace-fail '$(shell git rev-parse HEAD)' '00000000'
      substituteInPlace src/app/firedancer/version.mk \
        --replace-fail '$(shell git rev-parse HEAD)' '00000000'
    fi
    
    ${lib.optionalString enableRust ''
      # Fix Rust-related build issues - replace entire target rules
      substituteInPlace src/app/fdctl/Local.mk \
        --replace-fail 'check-agave-hash:
	@$(eval AGAVE_COMMIT_LS_TREE=$(shell git ls-tree HEAD | grep agave | awk '"'"'{print $$3}'"'"'))
	@$(eval AGAVE_COMMIT_SUBMODULE=$(shell git --git-dir=agave/.git --work-tree=agave rev-parse HEAD))
	@if [ "$(AGAVE_COMMIT_LS_TREE)" != "$(AGAVE_COMMIT_SUBMODULE)" ]; then \
		echo "Error: agave submodule is not up to date. Please run \`git submodule update\` before building"; \
		exit 1; \
	fi' 'check-agave-hash:
	@echo "Skipping agave hash check in Nix build"'
        
      # Skip rustup-based toolchain management
      substituteInPlace src/app/fdctl/Local.mk \
        --replace-fail 'update-rust-toolchain:
	@$(eval TOOLCHAIN_VERSION=$(shell sed -n '"'"'s/^channel = "\(.*\)"$$/\1/p'"'"' agave/rust-toolchain.toml))
	@$(eval TOOLCHAIN_EXISTS=$(shell rustup toolchain list | grep -c $(TOOLCHAIN_VERSION)))
	@if [ "$(TOOLCHAIN_EXISTS)" -eq 0 ]; then \
		echo "Installing rust toolchain $(TOOLCHAIN_VERSION)"; \
		rustup toolchain add $(TOOLCHAIN_VERSION); \
	fi' 'update-rust-toolchain:
	@echo "Using Nix-provided Rust toolchain"'
    ''}
  '';

  # Skip the configure phase as this is a Makefile-based project
  dontConfigure = true;
  
  # Enable parallel building
  enableParallelBuilding = true;
  
  # Enable unstable Rust features for borsh schema support
  RUSTC_BOOTSTRAP = lib.optionalString enableRust "1";

  # Set up build environment
  preBuild = ''
    # Set up environment
    export OPT=$(pwd)/opt
    export PREFIX=$(pwd)/opt
    export CC=gcc
    export CXX=g++
    
    ${lib.optionalString enableRust ''
      # Set up Rust environment
      export CARGO_HOME=$TMPDIR/cargo
      export RUSTFLAGS="-C force-frame-pointers=yes"
      export RUST_PROFILE=release
      
      # Set up for cargo
      export ROCKSDB_LIB_DIR=${rocksdb}/lib
      export SNAPPY_LIB_DIR=${snappy}/lib
      
      # Fix proc macro workspace issues
      export CARGO_MANIFEST_DIR=$(pwd)/agave
      # Set CARGO env var to help proc-macro-crate
      export CARGO="${cargo}/bin/cargo"
      
      # Set up clang for bindgen
      export LIBCLANG_PATH="${libclang.lib}/lib"
      export BINDGEN_EXTRA_CLANG_ARGS="-isystem ${libclang.lib}/lib/clang/${lib.versions.major libclang.version}/include"
      
    ''}
  '';

  buildPhase = ''
    runHook preBuild
    
    ${lib.optionalString enableRust ''
      # Create a minimal Cargo.toml in the parent directory to help proc macros
      cat > Cargo.toml << 'EOF'
[workspace]
members = ["agave"]
EOF
    ''}
    
    # Build firedancer without Rust components first
    make -j$NIX_BUILD_CORES MACHINE=linux_gcc_x86_64 ${lib.optionalString (!enableRust) "rust=off"}
    
    ${lib.optionalString enableRust ''
      # Build Rust components (fdctl) - need to set proper cargo path
      export PATH="${cargo}/bin:${rustc}/bin:$PATH"
      # The build expects cargo in agave directory
      ln -sf ${cargo}/bin/cargo agave/cargo
      
      # Build Rust components
      make -j$NIX_BUILD_CORES rust MACHINE=linux_gcc_x86_64
    ''}
    
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    
    # Create output directories
    mkdir -p $out/bin
    mkdir -p $out/lib
    mkdir -p $out/include
    
    # Copy built binaries
    find build -name "fdctl" -type f -executable -exec cp {} $out/bin/ \;
    find build -name "fd_*" -type f -executable -exec cp {} $out/bin/ \;
    
    # Copy libraries if any
    find build -name "*.a" -exec cp {} $out/lib/ \; || true
    find build -name "*.so" -exec cp {} $out/lib/ \; || true
    
    # Copy headers
    cp -r src/* $out/include/ || true
    
    runHook postInstall
  '';

  meta = with lib; {
    description = "A new validator client for Solana";
    longDescription = ''
      Firedancer is a new validator client for Solana that is:
      - Fast: Designed from the ground up to be fast
      - Secure: Architecture allows running with highly restrictive sandbox
      - Independent: Written from scratch for client diversity
      
      Note: Rust support (for the fdctl binary) is currently disabled by default
      due to borsh 1.5.7 proc macro issues in the vendored cargo environment.
      The borsh derive macros fail with "Failed to get the path of the workspace
      manifest" when building in Nix.
    '';
    homepage = "https://jumpcrypto.com/firedancer/";
    license = licenses.asl20;
    maintainers = with maintainers; [ ];
    platforms = platforms.linux;
    mainProgram = lib.optionalString enableRust "fdctl";
  };
})
