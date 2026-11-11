#!/bin/bash
# file: .claude/hooks/lib/json-field.sh
# template: REI
# title: JSON の値の取り出し（共通の部品）
# description: hook が受け取る JSON から、文字列の値を1つ取り出す。ほかの hook が読み込んで使う
#
# JSON文字列フィールドの値を1つ取り出す共通関数。
#
# どの hook も同じ取り出し方を使えるよう、1か所にまとめてある（フィールド名を引数で渡す）。
#
# 制約（正直に）：本格的なJSONパーサではない。grepの正規表現でトップレベルの単純な
# 文字列フィールドを1つ拾うだけで、ネストした同名キーやエスケープされたダブルクォートを
# 含む値までは正しく扱えない。hookが読む値（file_path・
# hook_event_name・source・transcript_path・session_id・tool_name）はいずれもこの制約の範囲内。バックスラッシュのJSON
# エスケープ（\\）はそのまま残る——パスとして使う場合は呼び出し側で
# sed 's/\\\\/\//g' 等により正規化すること（tr で変えると // になる）。
#
# 使い方: json_field <フィールド名> <JSON文字列>
#   例: FILE_PATH=$(json_field file_path "$INPUT")
json_field() {
  local field="$1" input="$2"
  printf '%s' "$input" | grep -o "\"${field}\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | head -1 | sed 's/.*"\([^"]*\)"$/\1/'
}
