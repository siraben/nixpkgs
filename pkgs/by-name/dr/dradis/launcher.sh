#!/bin/sh
set -eu
umask 077

if [ "${1-}" = "--version" ] || [ "${1-}" = "-v" ]; then
  echo "dradis $DRADIS_VERSION"
  exit 0
fi

if [ -n "${DRADIS_DATA_DIR-}" ]; then
  data_dir=$DRADIS_DATA_DIR
elif [ -n "${XDG_DATA_HOME-}" ]; then
  data_dir=$XDG_DATA_HOME/dradis
elif [ -n "${HOME-}" ]; then
  data_dir=$HOME/.local/share/dradis
else
  echo "dradis: set DRADIS_DATA_DIR, XDG_DATA_HOME, or HOME" >&2
  exit 1
fi

mkdir -p "$data_dir"
data_dir=$(cd "$data_dir" && pwd -P)
mkdir -p "$data_dir/credentials" "$data_dir/log" "$data_dir/storage"
chmod 700 "$data_dir" "$data_dir/credentials" "$data_dir/log" "$data_dir/storage"

source_store=${DRADIS_APP_SOURCE%/share/dradis}
source_name=${source_store##*/}
source_hash=${source_name%%-*}
app_id=$DRADIS_VERSION-$source_hash
app_dir=$data_dir/app-$app_id
if [ ! -e "$app_dir/.initialized" ]; then
  stage=$data_dir/.app-$app_id.$$
  cleanup() {
    chmod -R u+w "$stage" 2>/dev/null || true
    rm -rf "$stage"
  }
  trap cleanup EXIT
  trap 'exit 129' HUP
  trap 'exit 130' INT
  trap 'exit 143' TERM
  if [ -e "$stage" ]; then
    chmod -R u+w "$stage"
    rm -rf "$stage"
  fi
  mkdir -p "$stage"
  # Rails resolves symlinked application files back into the immutable store,
  # so initialize one writable-root application tree per package output.
  cp -a "$DRADIS_APP_SOURCE"/. "$stage"/
  chmod -R u+w "$stage"

  for path in app/views/tmp tmp; do
    rm -rf "${stage:?}/$path"
    mkdir -p "$stage/$path"
  done
  for path in config/credentials log storage; do
    rm -rf "${stage:?}/$path"
  done
  ln -s "$data_dir/credentials" "$stage/config/credentials"
  ln -s "$data_dir/log" "$stage/log"
  ln -s "$data_dir/storage" "$stage/storage"
  touch "$stage/.initialized"

  if ! mv -T "$stage" "$app_dir" 2>/dev/null; then
    test -e "$app_dir/.initialized"
  fi
  trap - EXIT HUP INT TERM
fi

cd "$app_dir"
export BUNDLE_GEMFILE="$app_dir/Gemfile"
export BUNDLE_FROZEN=1
export BUNDLE_IGNORE_CONFIG=1
export BUNDLE_WITHOUT="development:test"
export GEM_HOME="$DRADIS_GEM_HOME"
export GEM_PATH="$DRADIS_GEM_HOME"
export BOOTSNAP_CACHE_DIR="$app_dir/tmp/cache"
export NODE_ENV=production
export RAILS_ENV=production
export SANDBOX=false
export RAILS_LOG_TO_STDOUT=enabled
export RAILS_SERVE_STATIC_FILES=enabled

if [ "$DRADIS_COMMAND" = dradis-rails ]; then
  exec "$DRADIS_RUBY" "$app_dir/bin/rails" "$@"
fi

flock "$data_dir/.lock" "$DRADIS_RUBY" "$app_dir/bin/rails" db:prepare
exec "$DRADIS_RUBY" "$app_dir/bin/rails" server "$@"
