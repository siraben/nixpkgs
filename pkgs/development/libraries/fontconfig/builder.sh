source $stdenv/setup

configureFlags="--with-confdir=$out/etc/fonts --disable-docs"

postInstall=postInstall
postInstall() {
    # Patch fonts.conf to include Nix font paths
    sed -i "s|<dir>/usr/share/fonts</dir>|<dir>$freefont_ttf/share/fonts</dir>|" \
        $out/etc/fonts/fonts.conf
}

genericBuild
