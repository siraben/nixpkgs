{
  fetchFromGitHub,
  lib,
  python3,
  testers,
}:

python3.pkgs.buildPythonApplication (finalAttrs: {
  pname = "metagoofil";
  version = "1.4.0";
  pyproject = false;

  src = fetchFromGitHub {
    owner = "opsdisk";
    repo = "metagoofil";
    tag = "v${finalAttrs.version}";
    hash = "sha256-EY3DHSevIcBOkXIy19l3UDT72DvDU9FfqLZuFV7H7uo=";
  };

  postPatch = ''
    substituteInPlace metagoofil.py \
      --replace-fail 'open("user_agents.txt")' "open(\"$out/share/metagoofil/user_agents.txt\")"
  '';

  dependencies = with python3.pkgs; [
    google
    requests
  ];

  installPhase = ''
    runHook preInstall

    install -Dm755 metagoofil.py $out/bin/metagoofil
    install -Dm644 metagoofil.py $out/${python3.sitePackages}/metagoofil.py
    install -Dm644 user_agents.txt $out/share/metagoofil/user_agents.txt

    runHook postInstall
  '';

  pythonImportsCheck = [ "metagoofil" ];

  # Upstream has no tests. Exercise the CLI without performing a live search,
  # and instantiate the scanner to check access to the packaged user-agent list.
  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck

    $out/bin/metagoofil --help | grep -F "Metagoofil v${finalAttrs.version}"
    if $out/bin/metagoofil -d example.invalid -t pdf -l -1 2>error.log; then
      echo "metagoofil unexpectedly accepted a negative search limit" >&2
      exit 1
    fi
    grep -F "invalid value '-1', must be an int >= 0" error.log
    PYTHONPATH="$out/${python3.sitePackages}:$PYTHONPATH" python - <<'PY'
    from metagoofil import Metagoofil

    scanner = Metagoofil(
        domain="example.invalid",
        delay=0,
        save_links=None,
        url_timeout=1,
        search_max=0,
        download_file_limit=0,
        save_directory=".",
        number_of_threads=0,
        file_types=[],
        user_agent=None,
        download_files=False,
    )
    assert scanner.random_user_agents
    PY

    runHook postInstallCheck
  '';

  passthru.tests.version = testers.testVersion {
    package = finalAttrs.finalPackage;
    command = "metagoofil --help";
    version = "v${finalAttrs.version}";
  };

  meta = {
    description = "Tool to find publicly hosted files through Google searches";
    homepage = "https://github.com/opsdisk/metagoofil";
    changelog = "https://github.com/opsdisk/metagoofil/releases/tag/${finalAttrs.src.tag}";
    license = lib.licenses.gpl3Plus;
    maintainers = with lib.maintainers; [ siraben ];
    mainProgram = "metagoofil";
  };
})
