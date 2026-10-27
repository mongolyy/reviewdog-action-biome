#!/bin/sh
set -e

# Since Biome v2.6, the summary lines are written to stderr instead of stdout.
# Drop them so that only diagnostics are passed to reviewdog.
remove_biome_summary() {
  sed -E \
    -e '/^Checked [0-9]+ files? in /d' \
    -e '/^Found [0-9]+ (errors?|warnings?|infos?)\.$/d' \
    -e '/^Skipped [0-9]+ suggested fix(es)?\.$/d' \
    -e '/^If you wish to apply the suggested \(unsafe\) fixes/d'
}

biome_check() {
  if [ -z "$1" ]; then
    echo "❌ biome_check requires at least one argument"
    exit 1
  fi
  # shellcheck disable=SC2068,SC2086
  biome check --colors=off --write $@ 2>&1 1>/dev/null |
    sed 's/ *$//' |
    remove_biome_summary |
    awk 'BEGIN { RS=""; ORS="\n\n" } { if (index($0, "│") > 0) { print "  ```\n" $0 "\n  ```" } else { print $0 } }'
}

biome_ci() {
  if [ -z "$1" ]; then
    echo "❌ biome_ci requires at least one argument"
    exit 1
  fi
  # shellcheck disable=SC2068,SC2086
  biome ci --colors=off --max-diagnostics=30 $@ 2>&1 1>/dev/null |
    sed 's/\x1B\[[0-9;]*[JKmsu]//g' |
    sed 's/✖/×/g' |
    sed 's/ℹ/i/g' |
    sed 's/ *$//' |
    remove_biome_summary |
    awk 'BEGIN { RS=""; ORS="\n\n" } { if (index($0, "│") > 0) { print "  ```\n" $0 "\n  ```" } else { print $0 } }'
}
