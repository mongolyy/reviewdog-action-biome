#!/bin/sh
set -e

biome_json_to_rdf() {
  echo >&2 "=== biome_json_to_rdf start ==="
  if [ -z "$1" ]; then
    echo "❌ biome_json_to_rdf requires at least one argument"
    exit 1
  fi

  echo >&2 "=== biome ci 標準エラー出力 ==="
  # shellcheck disable=SC2086
  biome_ci_output=$(biome ci --reporter json $1 2>&1 1>/dev/null)
  echo >&2 "$biome_ci_output"

  echo >&2 "=== jq 処理1の結果 ==="
  jq_result1=$(echo "$biome_ci_output" | jq -r '
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
  ')
  echo >&2 "$jq_result1"

  echo >&2 "=== jq 処理2の結果 ==="
  jq_result2=$(echo "$jq_result1" | jq -s '.')
  echo >&2 "$jq_result2"

  echo >&2 "=== jq 処理3の結果（最終出力） ==="
  jq_result3=$(echo "$jq_result2" | jq '{diagnostics: .}')
  echo >&2 "$jq_result3"

  # 元の処理結果を返す
  echo "$jq_result3"
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
