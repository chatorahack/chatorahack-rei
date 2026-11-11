#!/bin/bash
# file: .claude/hooks/stop-request.sh
# template: REI
# title: 「止めて」の受け取り
# description: 人が「止めて」と言ったら、止めた印を作る
#
# UserPromptSubmit hook：人間の「止めて」を受け取ったら、止めた印（.claude/stop-requested）を置く。
# 印がある間は stop-guard.sh がすべての道具を止める。印は自動では消さない（人間が手で消す）。
# 判定：prompt の値だけを取り出し（閉じ引用符まで）、\uXXXX を printf '%b' で戻し、
#   「突き止めて」「ストップウォッチ」などの複合の言葉を先に消してから、「止めて」「やめて」「ストップ」を位置を問わず拾う
#   （日本語は分かち書きしないので「作業を止めて」も拾う）。jqは使わない。
# 人が打ったものでない入力（別のセッションからのメッセージ・サブエージェントの報告・作業の知らせ）は見ない（lib/relayed-prompt.sh。v0.3.0-beta.13）。
# 否定の形（「止めていない」「止めてない」「やめていません」「ストップしていない」）は拾わない（報告の文に出る否定の形で止まらないように）。
#   「止めておいて」「止めてしまって」のように語尾が付いても、人が頼む言い方なので拾う。
# 限界：この仕組みを話題にして「止めて」と書くと止まる（語の検知では言及と区別できない）。
set -u
export LC_ALL=C.UTF-8
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/relayed-prompt.sh"
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || true
INPUT=$(cat)
LOG=.claude/hook-executed.log
MARK=.claude/stop-requested

TEXT=$(printf '%s' "$INPUT" | sed -nE 's/.*"prompt"[[:space:]]*:[[:space:]]*"(([^"\\]|\\.)*)".*/\1/p')
[ -n "$TEXT" ] || exit 0
DECODED=$(printf '%b' "$TEXT" 2>/dev/null || printf '%s' "$TEXT")
prompt_is_relayed "$DECODED" && exit 0

if printf '%s' "$DECODED" \
  | sed -E 's/(受け|突き|食い|引き|呼び|押し|せき|堰き|書き|言い|踏み|取り|噛み|思い|見|仕|つき|うけ|くい|ひき|よび)(止|と)めて//g; s/(ノン|ワン|バック|ショート)ストップ//g; s/ストップ(ウォッチ|ロス|高|安|モーション)//g; s/(止|と|や)めて(い)?(ない|なかった|なく|なけれ|ません)//g; s/ストップして(い)?(ない|なかった|なく|なけれ|ません)//g' \
  | grep -qE '(止めて|やめて|ストップ)'; then
  if date -Iseconds > "$MARK" 2>/dev/null; then
    printf '%s stop-guard requested\n' "$(date -Iseconds)" >> "$LOG" 2>/dev/null || true
    echo "[REI] 人間が「止めて」と言いました。止めた印（.claude/stop-requested）を置きました。人間が印を消すまで、すべての道具は止まります。何をしていたかを短く伝えてください（何もしていなければ「何もしていません」）。謝るのは、頼まれていないことをした場合と、間違えた場合だけです。頼まれたことをしていただけなら謝りません。そのあと、次の指示を待ってください。"
  else
    echo "[REI] 人間が「止めて」と言いましたが、止めた印を置けませんでした。道具は機械では止まっていません。何も始めず、次の指示を待ってください。"
  fi
fi
exit 0
