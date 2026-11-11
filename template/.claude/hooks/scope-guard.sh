#!/bin/bash
# file: .claude/hooks/scope-guard.sh
# template: REI
# title: プロジェクトの外への書き込みの確認
# description: AI が Edit・Write でプロジェクトの外に書き込もうとしたとき、人に確認を求める
# caution: Bash のコマンドでの書き込みは見ない
#
# scope-guard.sh
# PreToolUse（Edit|Write|MultiEdit にマッチ）。書き込み先が、このプロジェクト（${CLAUDE_PROJECT_DIR}）の外なら確認（ask）を求める。
#
# なぜ要るか：Claude Code の hook は、セッションを起動したプロジェクトの設定からしか読まれない。別のプロジェクトに
# 書き込んでも、相手のプロジェクトの hook は動かない。そこで、書き込む側のプロジェクトの hook として
# 「自分のプロジェクトの外に書こうとしている」ことを見つける。
#
# Windows ではドライブ名の大文字・小文字が揺れる（C: と c:）ので、比べる前に
# ドライブ名を小文字にそろえる。相対パスはプロジェクトの場所から解き、「.」「..」も解いてから比べる。
#
# 限界（正直に）：確認を求めるだけで、止めはしない（-p で動かすときは確認できないので止まる）。Bash の
# コマンドでの外への書き込みは見ない（Bash で決定ファイルに書く形は decisions-bash-guard.sh が見る）。
set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/json-field.sh"
INPUT=$(cat)
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || true

FILE_PATH=$(json_field file_path "$INPUT")
# JSON の中のバックスラッシュは2文字1組で1文字分。sed で2文字を1文字の / にしてから比べる（tr だと // になる）
PROJECT_ROOT=$(cd "${CLAUDE_PROJECT_DIR:-.}" && { pwd -W 2>/dev/null || pwd; })
NORM_FILE_PATH=$(printf '%s' "$FILE_PATH" | sed 's/\\\\/\//g')
NORM_PROJECT_ROOT=$(printf '%s' "$PROJECT_ROOT" | sed 's/\\\\/\//g')
# Windows の短い名前（8.3 形式、例：ABCDEF~1）を長い名前にそろえる。同じフォルダが2通りに書かれて、
# 中なのに外と判定されることがある。まだ無いファイルは、親のフォルダだけそろえる
long_name() {
  local p="$1" d b q
  command -v cygpath >/dev/null 2>&1 || { printf '%s' "$p"; return; }
  if q=$(cygpath -m -l "$p" 2>/dev/null) && [ -e "$p" ]; then printf '%s' "$q"; return; fi
  d=$(dirname "$p"); b=$(basename "$p")
  if [ -d "$d" ] && q=$(cygpath -m -l "$d" 2>/dev/null); then printf '%s/%s' "$q" "$b"; else printf '%s' "$p"; fi
}
# ドライブ名（X:）を小文字にそろえる
lower_drive() { printf '%s' "$1" | sed 's/^\([A-Za-z]\):/\L\1:/'; }
# パスの中の「.」と「..」を、文字の上で解く（v0.3.0-beta.14）。まだ無いファイルにも使えるよう、ディスクは見ない。
# 解かずに頭の文字だけ比べると、<プロジェクト>/../x を中と見てしまう。シンボリックリンクは辿らない
resolve_dots() {
  local p="$1" head="" seg out=""
  local -a segs parts=()
  case "$p" in
    [A-Za-z]:/*) head="${p%%/*}"; p="${p#*/}" ;;
    /*) p="${p#/}" ;;
  esac
  IFS=/ read -r -a segs <<< "$p"
  # 空の配列を "${a[@]}" で展開すると、bash 4.4 より前（macOS の /bin/bash 3.2）では set -u で止まるので、${a[@]+...} の形にする
  for seg in ${segs[@]+"${segs[@]}"}; do
    case "$seg" in
      ''|.) ;;
      ..) [ ${#parts[@]} -gt 0 ] && parts=("${parts[@]:0:${#parts[@]}-1}") ;;
      *) parts+=("$seg") ;;
    esac
  done
  for seg in ${parts[@]+"${parts[@]}"}; do out="$out/$seg"; done
  printf '%s%s' "$head" "${out:-/}"
}
# 相対パスは、プロジェクトの場所から見たものとして頭に付ける（../x をプロジェクトの中とみなさないように）
case "$NORM_FILE_PATH" in
  /*|[A-Za-z]:*|'') : ;;
  *) NORM_FILE_PATH="$NORM_PROJECT_ROOT/$NORM_FILE_PATH" ;;
esac
[ -n "$NORM_FILE_PATH" ] && NORM_FILE_PATH=$(lower_drive "$(long_name "$(resolve_dots "$NORM_FILE_PATH")")")
NORM_PROJECT_ROOT=$(lower_drive "$(long_name "$(resolve_dots "$NORM_PROJECT_ROOT")")")

printf '%s scope-guard\n' "$(date -Iseconds)" >> .claude/hook-executed.log 2>/dev/null || true

if [ -z "$NORM_PROJECT_ROOT" ]; then
  # プロジェクトの場所が分からない＝環境の異常。黙って通すと、この hook が効いていないことに誰も気づかないので記録する
  printf 'degraded scope-guard %s reason=project_root_unresolved\n' "$(date -Iseconds)" >> .claude/guard-status 2>/dev/null || true
  exit 0
fi
[ -z "$NORM_FILE_PATH" ] && exit 0

case "$NORM_FILE_PATH" in
  "$NORM_PROJECT_ROOT"/*|"$NORM_PROJECT_ROOT")
    exit 0 ;;
  *)
    echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"[REI scope-guard] このプロジェクトの外への書き込みです。別のプロジェクト・共有のフォルダに書く前に、何を・どこに・なぜ書くかを人に確かめてください。"}}'
    exit 0 ;;
esac
