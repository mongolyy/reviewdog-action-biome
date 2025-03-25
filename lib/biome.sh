#!/bin/sh
set -e

biome_json_to_rdf() {
  if [ -z "$1" ]; then
    echo "❌ biome_json_to_rdf requires at least one argument"
    exit 1
  fi

  # jq処理1: JSONオブジェクトへの変換
  jq_result1=$(biome ci --colors=off --reporter json $1 2>/dev/null | tr -d '[:cntrl:]' | jq -r '
    .diagnostics[] |
    {
      message: .description,
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
      original_output: .description,
      suggestions: (
        # 現在のコンテキスト（診断情報）を変数に保存
        . as $diag |
        if $diag.advices != null and $diag.advices.advices != null then
          # まずdiffを含むadviceを見つける
          [$diag.advices.advices[] | select(.diff != null) | .diff] |
          if length > 0 then
            # diffが存在する場合は最初のdiffを使用
            .[0] as $diff |
            [
              {
                range: {
                  start: {
                    line: (if $diag.location.span != null then $diag.location.span[0] else 1 end),
                    column: (if $diag.location.span != null then $diag.location.span[1] else 1 end)
                  },
                  end: {
                    line: (if $diag.location.span != null then $diag.location.span[0] else 1 end),
                    column: (if $diag.location.span != null then $diag.location.span[1] + 3 else 1 end)
                  }
                },
                # dictionaryから修正後のテキストを抽出する
                text: (
                  $diff |
                  if .dictionary != null and .ops != null then
                    # insertの操作からテキストを抽出
                    (.ops[] | select(.diffOp.insert != null) | .diffOp.insert.range as $range |
                     .dictionary[$range[0]:$range[1]]) // ""
                  else
                    # 適切な修正情報が抽出できない場合は空文字列
                    ""
                  end
                )
              }
            ]
          else
            []
          end
        else
          []
        end
      )
    }
  ')
  jq1_exit_code=$?

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

  # jq処理2が失敗した場合
  if [ -z "$jq_result2" ] || [ "$jq2_exit_code" -ne 0 ]; then
    echo "⚠️ jq処理2が失敗したか、出力が空です。空のJSONを返します。"
    echo '{"diagnostics": []}'
    return 0
  fi

  # jq処理3: diagnosticsキーの追加
  jq_result3=$(echo "$jq_result2" |
    jq '{source: {name:"biome", url: "https://biomejs.dev/"}, diagnostics: .}' 2>/dev/null)
  jq3_exit_code=$?

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
