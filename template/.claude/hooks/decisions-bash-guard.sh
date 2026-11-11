#!/bin/bash
# file: .claude/hooks/decisions-bash-guard.sh
# template: REI
# title: 決定ファイルの書き換えの確認（Bash）
# description: AI が Bash のコマンドで decisions/ の決定ファイルを書き換えようとしたとき、人に確認を求める
#
# decisions-bash-guard.sh
# PreToolUse（Bash にマッチ）。Bash のコマンドで decisions/・docs/adr/ に書き込もうとしたら、確認を求める。
#
# なぜ要るか：decisions-guard.sh は Claude の編集の道具（Edit・Write）だけを見ている。Claude Code の
# acceptEdits モードでは、作業フォルダの中の cp・mv などのファイル操作と、> や >> による書き込みが
# 確認なしで通る（Claude Code の公式の手引き「Configure permissions」で確認、2026-10-25）。そのままだと、
# 決定ファイルを Bash で上書きできてしまう。
#
# 判定：コマンドに decisions/ か docs/adr/ が含まれ、かつ「書き込みの形」があるとき。
#   書き込みの形：その場所への > >>、cp・mv・rm・tee・truncate・dd・install、sed -i、
#   PowerShell の Set-Content・Add-Content・Out-File・Remove-Item・Move-Item・Copy-Item
# 読むだけのコマンド（ls decisions/、cat decisions/0001-*.md、2>/dev/null など）は止めない。
#
# 限界（正直に）：文字の並びで見るだけで、コマンドを解析していない。変数や別のスクリプトの中で書き込む形は
# 拾わない。cp で decisions/ から読み出すだけのコマンドも、確認を求めることがある（安全側）。
set -u
INPUT=$(cat)
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || true
printf '%s decisions-bash-guard\n' "$(date -Iseconds)" >> .claude/hook-executed.log 2>/dev/null || true

# 対象の場所が含まれていなければ、何もしない（パスの区切りは / と \ の両方）
printf '%s' "$INPUT" | grep -Eq 'decisions[/\\]|docs[/\\]+adr[/\\]' || exit 0

WRITE=0
# その場所への書き込みのリダイレクト（> や >> のすぐ後ろが decisions・adr のパス）
printf '%s' "$INPUT" | grep -Eq '>>?[[:space:]]*[^[:space:]]*(decisions|adr)[/\\]' && WRITE=1
# 書き込み・移動・削除のコマンド
printf '%s' "$INPUT" | grep -Eq '(^|[^A-Za-z_-])(cp|mv|rm|tee|truncate|dd|install)[[:space:]]' && WRITE=1
printf '%s' "$INPUT" | grep -Eq 'sed[[:space:]]+(-[A-Za-z]*i|--in-place)' && WRITE=1
printf '%s' "$INPUT" | grep -Eqi '(Set-Content|Add-Content|Out-File|Remove-Item|Move-Item|Copy-Item)' && WRITE=1

[ "$WRITE" -eq 1 ] || exit 0

echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"[REI decisions-bash-guard] Bash のコマンドで decisions/（または docs/adr/）に書き込もうとしています。既存の決定ファイルは書き換えません（Forward-only）。新しい決定は、編集の道具で新しい番号のファイルとして作ってください。"}}'
exit 0
