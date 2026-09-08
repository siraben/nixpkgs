data_home=${XDG_DATA_HOME:-${HOME:+$HOME/.local/share}}
if [[ -z "$data_home" ]]; then
  exit 0
fi

desktop_file="$data_home/applications/anytype.desktop"
if [[ ! -f "$desktop_file" || -L "$desktop_file" ]]; then
  exit 0
fi
if ! file_size=$(stat --format=%s -- "$desktop_file") || (( file_size > 4096 )); then
  exit 0
fi

if ! mapfile -t lines < "$desktop_file"; then
  exit 0
fi
if (( ${#lines[@]} != 11 )); then
  exit 0
fi

legacy_exec='^Exec="/nix/store/[0-9a-df-np-sv-z]{32}-electron-unwrapped-[^/"]+/libexec/electron/electron"( --ozone-platform-hint=auto)? %u$'
if [[ ${lines[0]} != '[Desktop Entry]' \
  || ${lines[1]} != 'Name=Anytype' \
  || ${lines[2]} != 'Comment=Project management and knowledge workspace' \
  || ! ${lines[3]} =~ $legacy_exec \
  || ${lines[4]} != 'Terminal=false' \
  || ${lines[5]} != 'Type=Application' \
  || ${lines[6]} != 'Icon=anytype' \
  || ${lines[7]} != 'Categories=Utility;Office;Calendar;ProjectManagement;' \
  || ${lines[8]} != 'StartupWMClass=anytype' \
  || ${lines[9]} != 'Keywords=project management;' \
  || ${lines[10]} != 'MimeType=x-scheme-handler/anytype;' ]]; then
  exit 0
fi

# Preserve the exact file in case the user wants to inspect or restore it.
backup_base="$desktop_file.anytype-generated.bak"
backup="$backup_base"
suffix=1
while [[ -e "$backup" || -L "$backup" ]]; do
  backup="$backup_base.$suffix"
  suffix=$((suffix + 1))
done
if ! mv -- "$desktop_file" "$backup"; then
  exit 0
fi
