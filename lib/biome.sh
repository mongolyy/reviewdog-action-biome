#!/bin/sh
set -e

biome_json_to_rdf() {
  if [ -z "$1" ]; then
    echo "❌ biome_json_to_rdf requires at least one argument"
    exit 1
  fi
  
  # shellcheck disable=SC2086
  biome ci --formatter json $1 2>/dev/null | jq -r '
    .files[] | 
    select(.diagnostics != null) | 
    .diagnostics[] | 
    {
      message: .message,
      location: {
        path: .location.file,
        range: {
          start: {
            line: .location.start.line,
            column: .location.start.column
          },
          end: {
            line: .location.end.line,
            column: .location.end.column
          }
        }
      },
      severity: (
        if .kind == "error" then "ERROR"
        elif .kind == "warning" then "WARNING"
        else "INFO"
        end
      ),
      code: {
        value: .name
      },
      original_output: .message
    }
  ' | jq -s '.' | jq '{diagnostics: .}'
}

biome_check() {
  if [ -z "$1" ]; then
    echo "❌ biome_check requires at least one argument"
    exit 1
  fi

  biome_version=$(biome --version)
  if awk -v ver="$biome_version" 'BEGIN { if (ver >= 1.8) exit 1; }'; then
    # The following processes will be removed when biome 2.0.0 is released
    # shellcheck disable=SC2086
    biome check --apply $1 2>&1 1>/dev/null |
      sed 's/ *$//' |
      awk 'BEGIN { RS=""; ORS="\n\n" } { if (index($0, "│") > 0) { print "  ```\n" $0 "\n  ```" } else { print $0 } }'
  else
    # shellcheck disable=SC2086
    biome check --write $1 2>&1 1>/dev/null |
      sed 's/ *$//' |
      awk 'BEGIN { RS=""; ORS="\n\n" } { if (index($0, "│") > 0) { print "  ```\n" $0 "\n  ```" } else { print $0 } }'
  fi
}

biome_ci() {
  if [ -z "$1" ]; then
    echo "❌ biome_ci requires at least one argument"
    exit 1
  fi
  # shellcheck disable=SC2086
  biome ci --max-diagnostics=30 $1 2>&1 1>/dev/null |
    sed 's/\x1B\[[0-9;]*[JKmsu]//g' |
    sed 's/✖/×/g' |
    sed 's/ℹ/i/g' |
    sed 's/ *$//' |
    awk 'BEGIN { RS=""; ORS="\n\n" } { if (index($0, "│") > 0) { print "  ```\n" $0 "\n  ```" } else { print $0 } }'
}
