#!/bin/bash
# file: .claude/hooks/turn-log.sh
# template: REI
# title: 依頼の始まりと終わりの記録
# description: 1回の依頼（ターン）の始まりと終わりを時刻付きで記録する。見積もりと実績を比べるため
#
# 1回の依頼（ターン）の始まりと終わりを、時刻付きで記録する。自己申告に頼らない時間の記録。
# 使い方：settings.json の UserPromptSubmit から「turn-log.sh start」、Stop から「turn-log.sh end」で呼ぶ。
# 記録：.claude/hook-executed.log に「時刻 turn-start session=<先頭8文字>」「時刻 turn-end session=<先頭8文字>」。
# 何も出力しない（Stop hookの出力はClaudeの動きを変えうるため）。止める判定はしない。
set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/json-field.sh"
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || true
INPUT=$(cat)
KIND="${1:-unknown}"
SID=$(json_field session_id "$INPUT")
printf '%s turn-%s session=%s\n' "$(date -Iseconds)" "$KIND" "${SID:0:8}" >> .claude/hook-executed.log 2>/dev/null || true
exit 0
