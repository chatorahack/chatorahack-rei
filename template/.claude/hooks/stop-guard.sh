#!/bin/bash
# file: .claude/hooks/stop-guard.sh
# template: REI
# title: 止めた印があるときの停止
# description: 止めた印（.claude/stop-requested）があれば、AI が道具を使うのを止める
#
# PreToolUse hook（すべての道具）：止めた印（.claude/stop-requested）があれば、道具の使用を拒否する。
# 印が無いときは、使った道具の名前を記録だけする（「何を読んだか」の証拠）。
# 印は人間が手で消す（このhookはBashも止めるので、AIは印を消せない）。
set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/json-field.sh"
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || true
INPUT=$(cat)
LOG=.claude/hook-executed.log
TOOL=$(json_field tool_name "$INPUT")

if [ -f .claude/stop-requested ]; then
  printf '%s stop-guard deny tool=%s\n' "$(date -Iseconds)" "${TOOL:-unknown}" >> "$LOG" 2>/dev/null || true
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"[REI stop-guard] 人間が「止めて」と言ったため、すべての道具を止めています。再開するには、人間がClaude Codeの外（普通のターミナル等）で .claude/stop-requested を消してください（例：rm .claude/stop-requested）。"}}'
  exit 0
fi
printf '%s tool=%s\n' "$(date -Iseconds)" "${TOOL:-unknown}" >> "$LOG" 2>/dev/null || true
exit 0
