#!/bin/sh
set -e

biome_json_to_rdf() {
  if [ -z "$1" ]; then
    echo "❌ biome_json_to_rdf requires at least one argument"
    exit 1
  fi

  # デバッグ情報を常に表示
  echo "=== biome_json_to_rdf start ==="

  # エラーハンドリングを一時的に無効化
  set +e

  # デバッグ情報を常に表示
  echo "=== biome ci 標準出力 ==="
  # 改行コードを確実に削除するために複数の方法を組み合わせる
  biome_ci_stdout=$(biome ci --reporter json $1 2>/dev/null)
  # 改行なしで出力

  biome ci --reporter json $1 2>/dev/null > biome_ci_output.json
  cat biome_ci_output.json

  echo "jq debug"
  cat biome_ci_output.json | jq -r 'tostring' 2>&1 || echo "Failed to parse JSON with jq"

  echo "=== jq処理 ==="
  # jq処理1: JSONオブジェクトへの変換
  jq_result1=$(echo "$biome_ci_stdout" | jq -r '
    .diagostics[] |
    {
      message: .descriptio,
      location: {
        path: (if .location.path.file != null then .location.path.file else "unknown" end),
        range: {
          start: {
            line: (if .location.span != null then .location.span[0] else 1 end),
            column: (if .location.span != null then .location.span[1] else 1 end)
          },
          end: {
            line: (if .location.span != null then .location.span[0] else 1 end),
            column: (if .location.span != null then .location.span[1] else 1 end)
          }
        }
      },
      severity: (
        if .severity == "error" then "ERROR"
        elif .severity == "warning" then "WARNING"
        else "INFO"
        end
      ),
      code: {
        value: .category
      },
      original_output: .description
    }
  ' 2>&1 1>/dev/null)
  jq1_exit_code=$?

  # デバッグ情報を常に表示
  echo "=== jq 処理1の結果（終了コード: $jq1_exit_code） ==="
  echo "$jq_result1"

  # jq処理1が失敗した場合
  if [ -z "$jq_result1" ] || [ "$jq1_exit_code" -ne 0 ]; then
    echo "⚠️ jq処理1が失敗したか、出力が空です。空のJSONを返します。"
    echo "入力JSON: $biome_ci_output"
    echo '{"diagnostics": []}'
    return 0
  fi

  # jq処理2: 配列への変換
  jq_result2=$(echo "$jq_result1" | jq -s '.' 2>/dev/null)
  jq2_exit_code=$?

  # デバッグ情報を常に表示
  echo "=== jq 処理2の結果（終了コード: $jq2_exit_code） ==="
  echo "$jq_result2"

  # jq処理2が失敗した場合
  if [ -z "$jq_result2" ] || [ "$jq2_exit_code" -ne 0 ]; then
    echo "⚠️ jq処理2が失敗したか、出力が空です。空のJSONを返します。"
    echo '{"diagnostics": []}'
    return 0
  fi

  # jq処理3: diagnosticsキーの追加
  jq_result3=$(echo "$jq_result2" | jq '{diagnostics: .}' 2>/dev/null)
  jq3_exit_code=$?

  # デバッグ情報を常に表示
  echo "=== jq 処理3の結果（終了コード: $jq3_exit_code） ==="
  echo "$jq_result3"

  # jq処理3が失敗した場合
  if [ -z "$jq_result3" ] || [ "$jq3_exit_code" -ne 0 ]; then
    echo "⚠️ jq処理3が失敗したか、出力が空です。空のJSONを返します。"
    echo '{"diagnostics": []}'
    return 0
  fi

  # エラーハンドリングを再度有効化
  set -e

  # 元の処理結果を返す（標準出力）
  printf "%s" "$jq_result3"
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
