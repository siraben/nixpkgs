{lib, stdenvNoCC, git, perl, ncurses, coreutils, fetchFromGitHub, makeWrapper }:

stdenvNoCC.mkDerivation rec {
  pname = "diff-so-fancy";
  version = "1.4.3";

  src = fetchFromGitHub {
    owner = "so-fancy";
    repo = "diff-so-fancy";
    rev = "v${version}";
    sha256 = "sha256-/xdBvq2u1s5/yzjwr3MLxpaD1CNktcPijXJTKW3Bc4c=";
  };

  nativeBuildInputs = [
    makeWrapper
  ];

  buildInputs = [
    perl # needed for patchShebangs
  ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/lib/diff-so-fancy

    # diff-so-fancy executable searches for it's library relative to
    # itself, so we are copying executable to lib, and only symlink it
    # from bin/
    cp diff-so-fancy $out/lib/diff-so-fancy
    cp -r lib $out/lib/diff-so-fancy
    ln -s $out/lib/diff-so-fancy/diff-so-fancy $out/bin

    # ncurses is needed for `tput`
    wrapProgram $out/lib/diff-so-fancy/diff-so-fancy \
      --prefix PATH : "${git}/share/git/contrib/diff-highlight" \
      --prefix PATH : "${git}/bin" \
      --prefix PATH : "${coreutils}/bin" \
      --prefix PATH : "${ncurses.out}/bin"

    runHook postInstall
  '';

  meta = with lib; {
    homepage = "https://github.com/so-fancy/diff-so-fancy";
    description = "Good-looking diffs filter for git";
    license = licenses.mit;
    platforms = platforms.all;
    longDescription = ''
      diff-so-fancy builds on the good-lookin' output of git contrib's
      diff-highlight to upgrade your diffs' appearances.
    '';
    maintainers = with maintainers; [ fpletz globin ma27 ];
  };
}
