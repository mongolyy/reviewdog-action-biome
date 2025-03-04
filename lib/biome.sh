#!/bin/sh
set -e

biome_json_to_rdf() {
  if [ -z "$1" ]; then
    echo "❌ biome_json_to_rdf requires at least one argument" >&2
    exit 1
  fi

  # デバッグ情報を常に表示
  echo "=== biome_json_to_rdf start ===" >&2

  # エラーハンドリングを一時的に無効化
  set +e

  # biome ciの実行と出力の取得
  # shellcheck disable=SC2086
  biome_ci_output=$(biome ci --reporter json $1 2>&1 1>/dev/null)
  biome_exit_code=$?

  # デバッグ情報を常に表示
  echo "=== biome ci 標準エラー出力（終了コード: $biome_exit_code） ===" >&2
  echo "$biome_ci_output" >&2

  # biome ciが失敗した場合でも処理を続行
  if [ -z "$biome_ci_output" ] || [ "$biome_exit_code" -ne 0 ]; then
    echo "⚠️ biome ciコマンドが失敗したか、出力が空です。空のJSONを返します。" >&2
    echo '{"diagnostics": []}'
    return 0
  fi

  # jq処理1: JSONオブジェクトへの変換
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
  ' 2>/dev/null)
  jq1_exit_code=$?

  # デバッグ情報を常に表示
  echo "=== jq 処理1の結果（終了コード: $jq1_exit_code） ===" >&2
  echo "$jq_result1" >&2

  # jq処理1が失敗した場合
  if [ -z "$jq_result1" ] || [ "$jq1_exit_code" -ne 0 ]; then
    echo "⚠️ jq処理1が失敗したか、出力が空です。空のJSONを返します。" >&2
    echo "入力JSON: $biome_ci_output" >&2
    echo '{"diagnostics": []}'
    return 0
  fi

  # jq処理2: 配列への変換
  jq_result2=$(echo "$jq_result1" | jq -s '.' 2>/dev/null)
  jq2_exit_code=$?

  # デバッグ情報を常に表示
  echo "=== jq 処理2の結果（終了コード: $jq2_exit_code） ===" >&2
  echo "$jq_result2" >&2

  # jq処理2が失敗した場合
  if [ -z "$jq_result2" ] || [ "$jq2_exit_code" -ne 0 ]; then
    echo "⚠️ jq処理2が失敗したか、出力が空です。空のJSONを返します。" >&2
    echo '{"diagnostics": []}'
    return 0
  fi

  # jq処理3: diagnosticsキーの追加
  jq_result3=$(echo "$jq_result2" | jq '{diagnostics: .}' 2>/dev/null)
  jq3_exit_code=$?

  # デバッグ情報を常に表示
  echo "=== jq 処理3の結果（終了コード: $jq3_exit_code） ===" >&2
  echo "$jq_result3" >&2

  # jq処理3が失敗した場合
  if [ -z "$jq_result3" ] || [ "$jq3_exit_code" -ne 0 ]; then
    echo "⚠️ jq処理3が失敗したか、出力が空です。空のJSONを返します。" >&2
    echo '{"diagnostics": []}'
    return 0
  fi

  # エラーハンドリングを再度有効化
  set -e

  # 元の処理結果を返す（標準出力）
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
