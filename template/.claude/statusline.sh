#!/bin/bash
# file: .claude/statusline.sh
# template: REI
# title: ステータスライン
# description: 画面の下に REI の版・新しい版・止めた印などを1行で出す。付けるかは人が選ぶ
#
# statusline.sh（v0.3.0-beta.31。版を記録から読むのは beta.33）：Claude Code の画面の下に、REI の状態を1行で出す（ステータスライン）。
# 付けるかは人が選ぶ（/rei の「ステータスラインを付ける」）。付けるときは、自分だけの設定 .claude/settings.local.json に書く。
# 共有の設定（.claude/settings.json）には書かない：プロジェクトの設定は個人の設定より優先されるので、
# 使う人が自分で作ったステータスラインが、そのプロジェクトで消えてしまう（公式 https://code.claude.com/docs/en/settings 「Settings precedence」、2026-11-08 確認）。
#
# 付けるときの値（.claude/settings.local.json の一番外の {} の中に足す。Windows でも / のまま。公式「Windows configuration」）：
#   "statusLine": { "type": "command", "command": "bash \"${CLAUDE_PROJECT_DIR:-.}/.claude/statusline.sh\"" }
#
# 応答のたびに動く（公式 https://code.claude.com/docs/en/statusline 「How status lines work」）ので、軽くする：
#   版の比べは起動のとき session-start.sh だけが行い、結果を .claude/rei-state に控える。ここはそれを bash だけで読む（ほかのプログラムを起こさない）
#   止めた印と、版上げの試しのフォルダがあるかは、その場で見る（ファイルがあるかだけ）
# 出すもの：REI <版>・停止中・新しい版 <版>（必須 N）・版上げの試しが残っています・/rei。パスは出さない。色は付けない（公式：エスケープは崩れることがある）
# 何があっても 0 で終わる（0 以外だと Claude Code は何も出さない）。
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
P="$(cd "$SCRIPT_DIR/.." && pwd)"
cat >/dev/null 2>&1   # Claude Code が渡す JSON は使わない（読み捨てる）
V=""; SV=""; L=""; R=""
# 版は受け取りの記録（.rei/received.cfg の [template] の version）から、その場で読む（v0.3.0-beta.33。上げた直後に古い版を出さない）
if [ -f "$P/.rei/received.cfg" ]; then
  sec=""
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%$'\r'}"; line="${line#"${line%%[![:space:]]*}"}"
    case "$line" in
      "["*) sec="$line" ;;
      version*=*) [ "$sec" = "[template]" ] && { V="${line#*=}"; V="${V#"${V%%[![:space:]]*}"}"; } ;;
    esac
  done < "$P/.rei/received.cfg"
fi
if [ -f "$P/.claude/rei-state" ]; then
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%$'\r'}"; line="${line#"${line%%[![:space:]]*}"}"
    case "$line" in
      "version = "*) SV="${line#version = }" ;;
      "latest = "*) L="${line#latest = }" ;;
      "required = "*) R="${line#required = }" ;;
    esac
  done < "$P/.claude/rei-state"
fi
# 控えが今の版のときに書かれたものでなければ（版を上げて、まだ起動し直していない）、新しい版は出さない
[ -n "$V" ] && [ "$SV" != "$V" ] && L=""
[ -n "$V" ] || V="$SV"
out="REI ${V:-（版は起動のあとに出ます）}"
[ -f "$P/.claude/stop-requested" ] && out="$out・停止中（止めた印）"
if [ -n "$L" ]; then
  case "$R" in ''|0) out="$out・新しい版 $L" ;; *) out="$out・新しい版 $L（必須 $R）" ;; esac
fi
NAME="${P##*/}"
[ -e "${P%/*}/$NAME-rei-try/.git" ] && out="$out・版上げの試しが残っています"
printf '%s・/rei\n' "$out"
exit 0
