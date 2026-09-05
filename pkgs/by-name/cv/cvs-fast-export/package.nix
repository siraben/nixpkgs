{
  lib,
  buildGoModule,
  fetchFromGitLab,
  makeWrapper,
  asciidoctor,
  cvs,
  diffutils,
  findutils,
  git,
  python3,
  rcs,
  rsync,
}:

buildGoModule (finalAttrs: {
  pname = "cvs-fast-export";
  version = "2.4";

  src = fetchFromGitLab {
    owner = "esr";
    repo = "cvs-fast-export";
    rev = finalAttrs.version;
    hash = "sha256-FaMyqhfKqT07/VGURwqSBmmOKZtPtqHqNZWVKiqK7Hs=";
  };

  vendorHash = "sha256-Jaf6UFsO5JBeoASO8RRLh+8CcMAzfnnqNeh8EMHygU4=";

  nativeBuildInputs = [
    asciidoctor
    makeWrapper
  ];

  buildInputs = [ python3 ];

  nativeCheckInputs = [ git ];

  postPatch = ''
    patchShebangs cvssync cvsconvert cvsstrip
  '';

  ldflags = [ "-X main.version=${finalAttrs.version}" ];

  postBuild = ''
    for page in cvs-fast-export cvssync cvsconvert; do
      asciidoctor -D . -a nofooter -b manpage "$page.adoc"
    done
  '';

  postInstall = ''
    install -Dm755 cvssync cvsconvert cvsstrip -t $out/bin
    install -Dm644 cvs-fast-export.1 cvssync.1 cvsconvert.1 -t $out/share/man/man1

    wrapProgram $out/bin/cvssync --prefix PATH : ${lib.makeBinPath [ rsync ]}
    wrapProgram $out/bin/cvsconvert --prefix PATH : $out/bin:${
      lib.makeBinPath [
        cvs
        diffutils
        findutils
        git
        rcs
      ]
    }
    wrapProgram $out/bin/cvsstrip --prefix PATH : $out/bin
  '';

  meta = {
    description = "Export an RCS or CVS history as a fast-import stream";
    homepage = "https://gitlab.com/esr/cvs-fast-export";
    changelog = "https://gitlab.com/esr/cvs-fast-export/-/blob/${finalAttrs.src.rev}/NEWS.adoc";
    license = lib.licenses.gpl2Plus;
    maintainers = with lib.maintainers; [ dfoxfranke ];
    platforms = lib.platforms.unix;
    mainProgram = "cvs-fast-export";
  };
})
