#!/bin/bash
# file: .claude/hooks/lib/relayed-prompt.sh
# template: REI
# title: 人が打った入力かの見分け（共通の部品）
# description: hook が受け取った入力が、人が打ったものか、別のセッションから届いたものかを見分ける
#
# UserPromptSubmit の入力のうち、人が打ったものでないもの（別のセッションからのメッセージ、
# サブエージェントの報告、バックグラウンドの作業の知らせ）を見分ける。Claude Code はこれらを
# 人の入力と同じ通り道で渡すので、中の言葉で「止めて」や「初めて」の hook が動いてしまう。
# 見分け方：先頭（空白を除く）が、Claude Code がこれらに付ける決まった書き出しで始まるか。
# 限界：書き出しは Claude Code の版で変わりうる。人がこの書き出しで始まる文を貼ったときも、人の入力として扱わない。
# 使い方：source して `prompt_is_relayed "$DECODED" && exit 0`
prompt_is_relayed() {
  local first
  first=$(printf '%s' "$1" | sed -n '/[^[:space:]]/{s/^[[:space:]]*//;p;q;}')
  case "$first" in
    "Another Claude session sent a message:"*|"<task-notification>"*|"<cross-session-message"*|"<agent-message"*|"[SYSTEM NOTIFICATION"*|"<system-reminder>"*) return 0 ;;
  esac
  return 1
}
