#!/bin/bash
# file: .claude/hooks/first-time-guide.sh
# template: REI
# title: 初めての分野の案内
# description: 人が初めての分野の相談をしたとき、答える前に docs/unknown.md の手順を AI に思い出させる
#
# UserPromptSubmit hook：初めての分野の相談のとき、答える前に手順の文書を読むよう AI に知らせる。
# 出力（標準出力）は、その依頼に添えて AI に渡る。止めはしない（知らせるだけ）。
# 知らせの中身（何をするか）は文書（docs/unknown.md 4.〜5.・docs/domains/README.md）を正本にし、hook は「読め」だけを言う。
#   hook と文書の3か所に同じ指示を複製すると、直すたびに食い違うため（考え方：「態度は文書、発火は hook」）。
# 発火：きっかけの語があり、かつ同じセッションでまだ知らせていないとき（.claude/first-time-guide.<session_id> の印）。
#   「分からない」「書きたい」は入れない（途中の作業「このエラーが分かりません」「README を書きたい」でも当たるため）。
# 判定：prompt の値だけを取り出し、\uXXXX を printf '%b' で戻して、きっかけの語を探す（stop-request.sh と同じ読み方）。jq は使わない。
# 限界：語で拾うので、きっかけの語が無い初めての相談は拾わない（そのときは AGENTS.md 3. と docs/unknown.md だけが支え）。
set -u
export LC_ALL=C.UTF-8
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/json-field.sh"
source "$SCRIPT_DIR/lib/relayed-prompt.sh"
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || true
INPUT=$(cat)
LOG=.claude/hook-executed.log

TEXT=$(printf '%s' "$INPUT" | sed -nE 's/.*"prompt"[[:space:]]*:[[:space:]]*"(([^"\\]|\\.)*)".*/\1/p')
[ -n "$TEXT" ] || exit 0
DECODED=$(printf '%b' "$TEXT" 2>/dev/null || printf '%s' "$TEXT")
# 人が打ったものでない入力（別のセッションからのメッセージ・サブエージェントの報告・作業の知らせ）は見ない（v0.3.0-beta.13）
prompt_is_relayed "$DECODED" && exit 0
printf '%s' "$DECODED" | grep -qE '初めて|はじめて|初心者|未経験|やったことがない|何から|始めたい|作りたい' || exit 0

SID=$(json_field session_id "$INPUT")
SID=$(printf '%s' "$SID" | tr -cd 'A-Za-z0-9_-')
MARK=".claude/first-time-guide.${SID:-nosession}"
[ -n "$SID" ] && [ -e "$MARK" ] && exit 0
[ -n "$SID" ] && { : > "$MARK"; } 2>/dev/null

printf '%s first-time-guide fired\n' "$(date -Iseconds)" >> "$LOG" 2>/dev/null || true
cat <<'EOF'
[REI] 初めての分野の相談です。答える前に docs/unknown.md の 0.（持ち物の棚卸し）・4.〜5. と docs/domains/README.md（分野の地図と足し方）を読み、その手順に従ってください。人が渡した持ち物（資料・指された場所）は、答える前に必ず開いてください。地図に人間が足したものは、黙って外さないでください。
EOF
exit 0
