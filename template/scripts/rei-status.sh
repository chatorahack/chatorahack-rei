#!/bin/bash
# file: scripts/rei-status.sh
# template: REI
# title: REI の状態
# description: REI の版・新しい版・版上げの試しなどを数行で出す。/rei が最初に流す
# caution: 見るだけで、何も書き換えない
#
# rei-status.sh（v0.3.0-beta.31。記録が無いときの3つの分け方は beta.34）：REI の状態を数行で出す。/rei（.claude/skills/rei/SKILL.md）が最初に流す。人が流してもよい。
# 見るだけで、ファイルは書き換えない。ネットには出ない。パス（写しの場所など）は出さない。
# 版の比べは起動のときの控え（.claude/rei-state、session-start.sh が書く）を読む。写しを新しくしたあとは、Claude Code を起動し直すと比べ直す。
set -u
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" || exit 0
cfg() { git config --file "$1" "${@:2}" 2>/dev/null; }
ST=.claude/rei-state
# 記録が無いときを3つに分ける（「記録が読めない」だけでは、REI でないのか・古いのか・壊れたのか分からないため）
if [ ! -f .rei/received.cfg ]; then
  if [ ! -f .claude/hooks/session-start.sh ]; then
    echo "REI の状態：このプロジェクトは REI から作ったものではない（受け取りの記録 .rei/received.cfg も、REI の起動の hook も無い）。REI を入れるかは人が決める"
    exit 0
  fi
  OV=$(grep -oE 'rei=[0-9]+\.[0-9]+\.[0-9]+(-(alpha|beta|rc)\.[0-9]+)?' .claude/hooks/session-start.sh 2>/dev/null | head -1 | cut -d= -f2)
  echo "REI の状態"
  if [ -n "$OV" ]; then
    echo "- このプロジェクトの版：$OV（受け取りの記録が無い古い雛形）"
    echo "- 上げ方：ふつうの上げ方で、古い雛形に本当の親（$OV の雛形）を使う（docs/howto/upgrade.md。このプロジェクトに無ければ、新しい雛形の docs/howto/upgrade.md）"
  else
    echo "- このプロジェクトの版：分からない（受け取りの記録も、起動の hook の版の行も無い。かなり古い雛形）"
    echo "- 上げるか作り直すかは人が決める。古い雛形には、作ったときの本当の親を使う。作り直すときに引き継ぐものは docs/howto/upgrade.md「作り直すとき」"
  fi
  echo "- 新しい版：この版の起動の hook は比べない（上げると、起動のときに比べる）"
  exit 0
fi
V=$(cfg .rei/received.cfg template.version || true)
echo "REI の状態（起動のときの控え：$(cfg "$ST" state.checked || echo 無し)）"
echo "- このプロジェクトの版：${V:-記録が壊れていて読めない（.rei/received.cfg。どの行かは git config --file .rei/received.cfg --list）}"
L=$(cfg "$ST" state.latest || true); N=$(cfg "$ST" state.between || true); R=$(cfg "$ST" state.required || true)
SV=$(cfg "$ST" state.version || true)
# 控えが今の版のときに書かれたものでなければ、まだ比べ直していない（v0.3.0-beta.33。上げた直後に「新しい版がある」と出さない）
if [ -n "$V" ] && [ -n "$SV" ] && [ "$SV" != "$V" ]; then
  echo "- 新しい版：版を上げたあと、まだ比べていない（Claude Code を起動し直すと比べる）"
else
case "$(cfg "$ST" state.copy || echo none)" in
  set)
    if [ -n "$L" ]; then echo "- 新しい版：$L がある（間の ${N:-?} 版のうち必須 ${R:-?}）。必須の版は飛ばさない"
    else echo "- 新しい版：無い（手元の写しと比べた。写しを新しくするのは人：git -C <写し> pull）"; fi ;;
  missing) echo "- 新しい版：見ていない（.rei/local.cfg の写しのフォルダに CHANGELOG.md が無い）" ;;
  unset) echo "- 新しい版：見ていない（写しのフォルダが未設定。REI を clone したフォルダを書く：git config --file .rei/local.cfg copy.path <フォルダ>）" ;;
  *) echo "- 新しい版：まだ比べていない（Claude Code を起動し直すと比べる）" ;;
esac
fi
PK=$(cfg .rei/received.cfg --get-regexp '^picked\..*\.applied$' | sed 's/^picked\.\(.*\)\.applied .*/\1/' | tr '\n' ' ')
[ -n "${PK// /}" ] && echo "- 先に取り込んだ版（--only）：${PK% }"
TRY="../$(basename "$(pwd)")-rei-try"
if [ -e "$TRY/.git" ]; then echo "- 版上げの試し：残っている（報告は .rei/reports/。捨てるなら bash scripts/upgrade-try.sh --discard）"; else echo "- 版上げの試し：無し"; fi
[ -f .claude/stop-requested ] && echo "- 止めた印：有り（.claude/stop-requested。人が消すまで AI はどの道具も使えない）"
if grep -q 'statusline\.sh' .claude/settings.local.json 2>/dev/null; then echo "- ステータスライン：付いている（.claude/settings.local.json）"
elif grep -q '"statusLine"' .claude/settings.local.json 2>/dev/null; then echo "- ステータスライン：自分で作ったものが付いている（REI のものではない）"
else echo "- ステータスライン：付いていない"; fi
exit 0
