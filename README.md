Time travel to 2008!
====================

This is a modified version of the nixpkgs from 2008, to allow some programs to successfully run and compile in 2023.

Here's how to start a temporary shell with Firefox, GIMP, Inkscape and Blender from 2008 available:

```
$ git clone git@github.com:blinry/nixpkgs.git
$ cd nixpkgs
$ nix-shell -p 'with (import ./. {}); [blender inkscape gimp firefox]'
```

This will take a long time to compile. If something goes wrong, feel free to open an issue (or try to fix it yourself, and submit a pull request)!

## Successfully Built Programs

The following programs have been successfully built and tested:
- **vim** 7.1
- **python** 2.4.4
- **perl** 5.8.8
- **wget** 1.10.2
- **bash** 3.2-p17
- **gcc** 4.1.2
- **ghc** 6.8.2 (Glasgow Haskell Compiler)
- **emacs** 22.1
- **joe** 3.3 (text editor)
- **inkscape** 0.45
- **GIMP** and **fsg** (with fontconfig fix)

## Fixes Applied

- **IPv4 forcing**: Added `-4` flag to curl in both `pkgs/stdenv/linux/scripts/download.sh` and `pkgs/build-support/fetchurl/builder.sh` to avoid IPv6 connection issues
- **libxslt URL update**: Changed libxslt source URL from `ftp://xmlsoft.org/libxml2/libxslt-1.1.22.tar.gz` to `https://download.gnome.org/sources/libxslt/1.1/libxslt-1.1.22.tar.gz` in `pkgs/development/libraries/libxslt/default.nix`
- **Fontconfig paths**: Fixed fontconfig to include Nix font paths instead of /usr/share/fonts
- **Emacs CRT patch**: Updated emacs-22 CRT patch to work with x86_64 systems
- **GHC source URLs**: Fixed GHC 6.8.2 source URLs and checksums

## Manual Downloads Required

Due to SSL/HTTPS issues with the bootstrap curl, some tarballs need to be manually downloaded and added to the Nix store. Here are the required downloads:

### Bootstrap Files (required first)
```bash
# Download bootstrap files
cd /tmp
curl -L -o static-tools.tar.bz2 "http://tarballs.nixos.org/stdenv-linux/x86_64/r6905/static-tools.tar.bz2"
curl -L -o binutils.tar.bz2 "http://tarballs.nixos.org/stdenv-linux/x86_64/r6905/binutils.tar.bz2"
curl -L -o gcc.tar.bz2 "http://tarballs.nixos.org/stdenv-linux/x86_64/r6905/gcc.tar.bz2"
curl -L -o glibc.tar.bz2 "http://tarballs.nixos.org/stdenv-linux/x86_64/r6905/glibc.tar.bz2"

# Add to Nix store
nix-store --add-fixed sha1 /tmp/static-tools.tar.bz2
nix-store --add-fixed sha1 /tmp/binutils.tar.bz2
nix-store --add-fixed sha1 /tmp/gcc.tar.bz2
nix-store --add-fixed sha1 /tmp/glibc.tar.bz2
```

### Additional Package Tarballs (as needed during build)
```bash
# pcre-7.1
curl -L -o /tmp/pcre-7.1.tar.bz2 "http://tarballs.nixos.org/sha256/0rpkcw07jas3fw6ava3ni5zcrmbncwa8xlsa0lzq6z2iph5510li"
nix-store --add-fixed sha256 /tmp/pcre-7.1.tar.bz2

# GConf-2.14.0
curl -L -o /tmp/GConf-2.14.0.tar.bz2 "http://tarballs.nixos.org/md5/d07c2efcaf477cf34225c604a04b6271"
nix-store --add-fixed md5 /tmp/GConf-2.14.0.tar.bz2

# ORBit2-2.14.5
curl -L -o /tmp/ORBit2-2.14.5.tar.bz2 "http://tarballs.nixos.org/md5/5b3ca3d7ed13a76c9e7bb4a890fe68af"
nix-store --add-fixed md5 /tmp/ORBit2-2.14.5.tar.bz2

# XML-Simple-2.14
curl -L -o /tmp/XML-Simple-2.14.tar.gz "http://tarballs.nixos.org/md5/f321058271815de28d214c8efb9091f9"
nix-store --add-fixed md5 /tmp/XML-Simple-2.14.tar.gz

# gail-1.9.3
curl -L -o /tmp/gail-1.9.3.tar.bz2 "http://tarballs.nixos.org/md5/1e8825da60fd19833dfc6b2068f05ec9"
nix-store --add-fixed md5 /tmp/gail-1.9.3.tar.bz2

# icon-naming-utils-0.8.2
curl -L -o /tmp/icon-naming-utils-0.8.2.tar.gz "http://tarballs.nixos.org/sha256/0ml00nrnd7bkdm09wdj592axwg6v6lcb9yvazc540ls8by6kkzl7"
nix-store --add-fixed sha256 /tmp/icon-naming-utils-0.8.2.tar.gz

# gnome-icon-theme-2.16.1
curl -L -o /tmp/gnome-icon-theme-2.16.1.tar.bz2 "http://tarballs.nixos.org/md5/4a5da64a6084fdddf056e553a929c169"
nix-store --add-fixed md5 /tmp/gnome-icon-theme-2.16.1.tar.bz2

# gnome-keyring-0.6.0
curl -L -o /tmp/gnome-keyring-0.6.0.tar.bz2 "http://tarballs.nixos.org/md5/1e3a3a12b19fc5ebe95363658c2256d8"
nix-store --add-fixed md5 /tmp/gnome-keyring-0.6.0.tar.bz2

# gnome-mime-data-2.4.3
curl -L -o /tmp/gnome-mime-data-2.4.3.tar.bz2 "http://tarballs.nixos.org/md5/2abe573a6e84b71c58a661d4bafa9bd6"
nix-store --add-fixed md5 /tmp/gnome-mime-data-2.4.3.tar.bz2

# libgnomeprint-2.12.1
curl -L -o /tmp/libgnomeprint-2.12.1.tar.bz2 "http://tarballs.nixos.org/md5/ea729d4968fe2169c84efb12ace5f6cc"
nix-store --add-fixed md5 /tmp/libgnomeprint-2.12.1.tar.bz2

# libgnomeprintui-2.12.1
curl -L -o /tmp/libgnomeprintui-2.12.1.tar.bz2 "http://tarballs.nixos.org/md5/fa0b0410c3ba8b6899c5ed278f02cbe5"
nix-store --add-fixed md5 /tmp/libgnomeprintui-2.12.1.tar.bz2

# gnome-vfs-2.16.3
curl -L -o /tmp/gnome-vfs-2.16.3.tar.bz2 "http://tarballs.nixos.org/md5/586d6fe3740385c000a864d5e2cf8215"
nix-store --add-fixed md5 /tmp/gnome-vfs-2.16.3.tar.bz2

# libbonobo-2.16.0
curl -L -o /tmp/libbonobo-2.16.0.tar.bz2 "http://tarballs.nixos.org/md5/30cdcf2b5316888f10fea6362b38499c"
nix-store --add-fixed md5 /tmp/libbonobo-2.16.0.tar.bz2

# libbonoboui-2.16.0
curl -L -o /tmp/libbonoboui-2.16.0.tar.bz2 "http://tarballs.nixos.org/md5/603ffc92491ef27ccfbc2b69abd3906b"
nix-store --add-fixed md5 /tmp/libbonoboui-2.16.0.tar.bz2

# libgnomeui-2.16.1
curl -L -o /tmp/libgnomeui-2.16.1.tar.bz2 "http://tarballs.nixos.org/md5/d9b975952bf5feee8818d3fb18cca0b3"
nix-store --add-fixed md5 /tmp/libgnomeui-2.16.1.tar.bz2

# gtkhtml-3.12.2
curl -L -o /tmp/gtkhtml-3.12.2.tar.bz2 "http://tarballs.nixos.org/md5/8c943647fd26cf4594b2e97055e22584"
nix-store --add-fixed md5 /tmp/gtkhtml-3.12.2.tar.bz2
```

### GHC (Glasgow Haskell Compiler) Tarballs
```bash
# GHC 6.8.2 source
curl -L -o /tmp/ghc-6.8.2-src.tar.bz2 "https://downloads.haskell.org/~ghc/6.8.2/ghc-6.8.2-src.tar.bz2"
cp /tmp/ghc-6.8.2-src.tar.bz2 /tmp/ghc-6.8.2-src.tar.bz2.tmp
nix-store --add-fixed md5 /tmp/ghc-6.8.2-src.tar.bz2.tmp

# GHC 6.8.2 extra libraries
curl -L -o /tmp/ghc-6.8.2-src-extralibs.tar.bz2 "https://downloads.haskell.org/~ghc/6.8.2/ghc-6.8.2-src-extralibs.tar.bz2"
cp /tmp/ghc-6.8.2-src-extralibs.tar.bz2 /tmp/ghc-6.8.2-src-extralibs.tar.bz2.tmp
nix-store --add-fixed md5 /tmp/ghc-6.8.2-src-extralibs.tar.bz2.tmp

# GHC 6.4.2 binary (bootstrap compiler)
curl -L -o /tmp/ghc-6.4.2-x86_64-unknown-linux.tar.bz2 "http://tarballs.nixos.org/md5/8f5fe48798f715cd05214a10987bf6d5"
nix-store --add-fixed md5 /tmp/ghc-6.4.2-x86_64-unknown-linux.tar.bz2

# GMP 4.2.2 (GHC dependency)
curl -L -o /tmp/gmp-4.2.2.tar.bz2 "ftp://ftp.nluug.nl/pub/gnu/gmp/gmp-4.2.2.tar.bz2"
nix-store --add-fixed sha256 /tmp/gmp-4.2.2.tar.bz2
```

Check out the full documentation at https://blinry.org/nix-time-travel/.
