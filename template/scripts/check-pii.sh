#!/bin/bash
# file: scripts/check-pii.sh
# template: REI
# title: 個人情報の点検
# description: コミットする内容に、リポジトリの外の表に登録した個人情報が入っていないか確かめる
# caution: 表に無い語は止まらない
#
# 個人を特定できる情報の混入チェック
#
# 判定：このコミットで追加される行に、パターン表の語（大文字小文字を区別しない固定文字列）が含まれていたら止める。
# パターン表はリポジトリの外（既定は ~/.config/rei/pii_patterns.txt）に置く。作成・更新は人間が行う。
# 見本はこのリポジトリの pii_patterns.example.txt（書き方と伏せ字の一覧。値は入っていない）。
# AIはこのファイルの中身を開かない（.claude/settings.json の permissions.deny で Read を拒否。拒否はClaudeの道具とBashの
# cat・head・sed 等には効くが、grep -r のような名前を指定しない読み方や、このスクリプトのような別プロセスには効かない）。
# そのため、このスクリプトでも表を開くのは照合用の整形だけにし、中身を表示しない。
# 表示するのは該当したファイル名と行番号だけで、該当した値・行の中身は表示しない（ターミナルやログへの書き戻しを防ぐ）。
#
# 表の書式：1行に「元の文字列==>伏せ字」（例：<姓>==>{{PERSON_FAMILY_NAME}}）。「==>」より左だけを検索語として使う。
#   「==>」の無い1語だけの行も検索語として使える。空行と、先頭が # の行は無視する。改行コードはCRLFでもよい。
#   （伏せ字の部分は、このスクリプトでは使わない。書き方は git filter-repo --replace-text の置換表と同じ）
# 表が無い・有効な行が0のときは、止めずに注意だけ出す（作成前にすべてのコミットが止まるのを避けるため）。
# **照合の道具（git・awk等）が失敗したときは「該当なし」と扱わず、止める**（フェイルクローズ）。
# 限界：`git commit --no-verify`で回避できる。削除した行・コミットメッセージ・複数行に割れた値は対象外。
#
# 使い方: bash scripts/check-pii.sh（.githooks/pre-commit から呼ぶ。直接実行でも同じ結果になる）。PII_PATTERNS で表の場所を変えられる
# 検証: bash scripts/test-check-pii.sh
set -u
export LC_ALL=C.UTF-8
cd "$(git rev-parse --show-toplevel)" || { echo "[REI] 個人情報チェック：gitのリポジトリの場所を取得できないため止めます" >&2; exit 1; }

fail_tool() { echo "[REI] 個人情報チェック自体が失敗したため、コミットを止めます（$1）。原因を直すか、確かめたうえで --no-verify を使ってください" >&2; exit 1; }

# 表の場所（既定は ~/.config/rei/）。表示はユーザー名を含まない書き方にとどめる
# 追加の表：環境変数 PII_PATTERNS_EXTRA に、追加で読む表のパスを ; 区切りで書ける
# （例：種類の違う表を分けて置く）
TABLES=()   # 「パス<TAB>表示名」
if [ -n "${PII_PATTERNS:-}" ]; then
  TABLES+=("$PII_PATTERNS	環境変数PII_PATTERNSで指定した場所")
elif [ -n "${HOME:-}" ]; then
  TABLES+=("$HOME/.config/rei/pii_patterns.txt	~/.config/rei/pii_patterns.txt")
else
  echo "[REI] 注意：HOMEが設定されていないため、既定の個人情報のパターン表を探せません" >&2
fi
if [ -n "${PII_PATTERNS_EXTRA:-}" ]; then
  IFS=';' read -r -a EXTRA <<< "$PII_PATTERNS_EXTRA"
  for x in "${EXTRA[@]}"; do [ -n "$x" ] && TABLES+=("$x	環境変数PII_PATTERNS_EXTRAで指定した表")
  done
fi

TMPPAT=$(mktemp) || fail_tool "一時ファイルを作れない"
DIFF=$(mktemp) || fail_tool "一時ファイルを作れない"
trap 'rm -f "$TMPPAT" "$DIFF"' EXIT

# 表を整形：CRを除き、空行・空白だけの行・#で始まる行を除き、「==>」より左だけを残す（左が空の行は除く）
FOUND_TABLE=0
for t in "${TABLES[@]}"; do
  PAT="${t%%	*}"; PAT_SHOWN="${t#*	}"
  if [ ! -e "$PAT" ]; then
    echo "[REI] 注意：個人情報のパターン表（$PAT_SHOWN）が無いため、この表では確認していません（作り方は docs/howto/pii-check.md）" >&2
    continue
  fi
  [ -f "$PAT" ] && [ -r "$PAT" ] || fail_tool "パターン表を読めない（$PAT_SHOWN）"
  FOUND_TABLE=1
  awk '{ sub(/\r$/, ""); if ($0 ~ /^[[:space:]]*(#|$)/) next; i = index($0, "==>"); if (i > 0) $0 = substr($0, 1, i - 1); if ($0 == "") next; print tolower($0) }' "$PAT" >> "$TMPPAT" \
    || fail_tool "パターン表の整形に失敗（$PAT_SHOWN）"
done
if [ "$FOUND_TABLE" -eq 0 ]; then
  echo "[REI] 注意：個人情報のパターン表が1つも無いため、個人情報の混入チェックを行っていません" >&2
  exit 0
fi
if [ ! -s "$TMPPAT" ]; then
  echo "[REI] 注意：個人情報のパターン表に有効な行が無いため、個人情報の混入チェックを行っていません" >&2
  exit 0
fi

# core.quotepath=false：日本語などのファイル名がエスケープされて表示されるのを防ぐ
git -c core.quotepath=false diff --cached -U0 --no-color --diff-filter=ACMR > "$DIFF" || fail_tool "差分を取得できない"

# 差分を1行ずつ読み、追加された行の「新しいファイルでの行番号」を数えながら照合する。出力は「ファイル名<TAB>行番号」だけ
HITS=$(awk -v patfile="$TMPPAT" '
  BEGIN { while ((getline p < patfile) > 0) pats[++np] = p; close(patfile) }
  /^diff --git / { file = ""; next }
  /^\+\+\+ / { f = substr($0, 5); sub(/\t$/, "", f); if (f ~ /^"/) { sub(/^"/, "", f); sub(/"$/, "", f) }
               if (f == "/dev/null") file = ""; else { sub(/^b\//, "", f); file = f }; next }
  /^--- / { next }
  /^@@ / { if (match($0, /\+[0-9]+/)) n = substr($0, RSTART + 1, RLENGTH - 1) + 0; next }
  /^\+/ { if (file != "") { line = tolower(substr($0, 2)); for (k = 1; k <= np; k++) if (index(line, pats[k]) > 0) { print file "\t" n; break } } n++; next }
  /^ / { n++; next }
' "$DIFF") || fail_tool "照合に失敗"

if [ -n "$HITS" ]; then
  echo "[REI] 個人を特定できる情報（パターン表の語）を含む行が、このコミットに追加されています（値・行の中身は表示しません）:" >&2
  printf '%s\n' "$HITS" | awk -F'\t' '{ if (!($1 in seen)) { order[++m] = $1; seen[$1] = "" } lines[$1] = lines[$1] (lines[$1] == "" ? "" : ", ") $2 }
    END { for (i = 1; i <= m; i++) printf "- %s（%s行目）\n", order[i], lines[order[i]] }' >&2
  echo "伏せ字（{{PERSON}}・{{EMAIL_ADDRESS}}等。一覧は pii_patterns.example.txt）に置き換えてからコミットしてください。" >&2
  exit 1
fi
exit 0
