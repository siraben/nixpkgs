{
  runCommand,
  speechd,
}:

runCommand "speech-dispatcher-generic-execute-test" { } ''
  test -x /bin/sh
  test ! -e /bin/bash

  export HOME="$TMPDIR/home"
  mkdir -p "$HOME"

  cat > generic.conf <<'EOF'
  Debug 0
  GenericExecuteSynth "printf '%s' '$DATA' | tr '[:lower:]' '[:upper:]' > '$TMPDIR/spoken'"
  GenericLanguage "en" "en" "utf-8"
  AddVoice "en" "MALE1" "test"
  DefaultVoice "test"
  EOF

  coproc module {
    ${speechd}/libexec/speech-dispatcher-modules/sd_generic generic.conf
  }
  exec {module_out}<&"''${module[0]}"
  exec {module_in}>&"''${module[1]}"

  read_until() {
    local expected="$1" line
    while IFS= read -r -t 10 -u "$module_out" line; do
      echo "$line"
      if [[ "$line" == *"$expected" ]]; then
        return 0
      fi
    done
    echo "did not receive $expected" >&2
    return 1
  }

  printf 'INIT\n' >&"$module_in"
  read_until '299 OK LOADED SUCCESSFULLY'
  printf 'SPEAK\n' >&"$module_in"
  read_until '202 OK RECEIVING MESSAGE'
  printf 'generic shell works\n.\n' >&"$module_in"
  read_until '200 OK SPEAKING'
  read_until '702 END'

  test "$(<"$TMPDIR/spoken")" = 'GENERIC SHELL WORKS'

  printf 'QUIT\n' >&"$module_in"
  read_until '210 OK QUIT'
  exec {module_in}>&-
  wait "$module_PID"

  touch "$out"
''
