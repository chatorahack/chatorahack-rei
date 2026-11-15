#!/bin/bash
# file: .claude/hooks/plugin-check.sh
# template: REI
# title: プラグインの見張り
# description: .claude/settings.json の一覧（enabledPlugins）に書いたプラグインが、この PC に入っていないとき、起動のときに知らせる
#
# SessionStart hook。プラグインで足した機能は、入っていないと何も言わずに動かない（Claude Code が知らせるのは /plugin の Errors タブだけ）。
#   そこで、雛形に残るこの hook の側から見る（プラグインの側は、入っていないときには何も言えないため）。
# 読み方：.claude/settings.json の enabledPlugins から、値が true の名前（<プラグイン>@<マーケットプレイス>）を取り出し、
#   `claude plugin list --json` の id に無いものを、人の画面（systemMessage）と AI（additionalContext）に知らせる。
#   一覧が空なら、何もしない（claude も呼ばない。起動は遅くならない）。
# 公式：プラグインの一覧の欄は https://code.claude.com/docs/en/plugins/loading （enabledPlugins・extraKnownMarketplaces）。
#   `claude plugin list --json` は入っているプラグインを1行ずつ出す（Claude Code の CHANGELOG「errorDetails/noteDetails to each row of claude plugin list --json」）。
# 止めはしない（知らせるだけ）。会話の要約（source=compact）のときは知らせ直さない。
# 限界：見るのは .claude/settings.json だけ（settings.local.json や個人の設定で足したものは見ない）。
#   入っているかだけを見る。入っていても読み込めなかった・無効にしたものは、/plugin の Errors タブで見る。
#   claude のコマンドが見つからない・失敗した・JSON の配列でない出力だったときは、「確かめられなかった」と知らせる（黙って通さない）。
#   ほかのプロジェクトに入れたものも「入っている」と数える（claude plugin list は入れた場所ごとに1行出す）。
#   時間の上限は settings.json の登録の timeout（15秒）。それを超えると Claude Code がこの hook を止める（知らせは出ない）。
#   プラグインの場所（installPath）は、記録にも出力にも書かない（アカウント名を含む。docs/naming.md）。
set -u
export LC_ALL=C.UTF-8
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/json-field.sh"
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0
INPUT=$(cat)
SOURCE=$(json_field source "$INPUT")
[ "$SOURCE" = compact ] && exit 0
SET=.claude/settings.json
[ -f "$SET" ] || exit 0

# enabledPlugins の { … } の中から、true の名前を取り出す（改行をつないで1行にしてから読む。jq は使わない）
BLOCK=$(tr -d '\r\n' < "$SET" | sed -n 's/.*"enabledPlugins"[[:space:]]*:[[:space:]]*{\([^}]*\)}.*/\1/p')
WANT=$(printf '%s' "$BLOCK" | grep -o '"[^"]*"[[:space:]]*:[[:space:]]*true' | sed 's/^"\([^"]*\)".*/\1/')
[ -n "$WANT" ] || exit 0

say() {
  local m
  m=$(printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g')
  printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"},"systemMessage":"%s"}\n' "$m" "$m"
}

LIST=$(claude plugin list --json 2>/dev/null) || LIST=""
# JSON の配列でなければ（空・案内の文・エラーの文）、入っていないと決めつけず「確かめられなかった」にする
case "$(printf '%s' "$LIST" | tr -d ' \t\r\n' | cut -c1)" in
  "[") : ;;
  *) LIST="" ;;
esac
if [ -z "$LIST" ]; then
  say "[REI] プラグインの一覧（.claude/settings.json の enabledPlugins）に書いたものが入っているか、確かめられませんでした（claude plugin list が動かない）。/plugin の Errors タブで確かめてください"
  exit 0
fi
HAVE=$(printf '%s' "$LIST" | tr -d '\r\n' | grep -o '"id"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)"$/\1/')

MISSING=""
while IFS= read -r p; do
  [ -n "$p" ] || continue
  printf '%s\n' "$HAVE" | grep -qxF -- "$p" || MISSING="${MISSING:+$MISSING、}$p"
done <<< "$WANT"
[ -n "$MISSING" ] || exit 0

printf '%s plugin-missing=%s\n' "$(date -Iseconds)" "$MISSING" >> .claude/hook-executed.log 2>/dev/null || true
say "[REI] プラグインの一覧（.claude/settings.json の enabledPlugins）に書いてあるのに、この PC に入っていないものがあります：${MISSING}。そのプラグインの機能は、入れるまで動きません（入れ方は docs/howto/plugins.md。要らないなら一覧から消す）"
exit 0
