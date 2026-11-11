#!/bin/bash
# file: scripts/check-control-chars.sh
# template: REI
# title: 制御文字の点検
# description: 記録に見えない制御文字（記録の見た目と中身をずらすもの）が入っていないか確かめる
#
# 制御文字の点検
#
# このコミットで足す行に、見えない制御文字（NUL・BEL・BS・VT・FF・行の途中の CR）が混ざっていたら止める。
# プログラムの文字列でファイルを書くと、パスの \a・\r・\v などが制御文字に化け、エラーにならずに壊れる
# （AI がよく起こす失敗の型）。
# 行末の CRLF の CR は止めない。表示するのはファイル名と件数だけで、行の中身は出さない。
# 照合の道具が失敗したときは「該当なし」と扱わず止める（フェイルクローズ）。
#
# 使い方: bash scripts/check-control-chars.sh（.githooks/pre-commit から呼ぶ）
# 限界：git commit --no-verify で回避できる。バイナリのファイル（画像・圧縮など）は見ない。
set -u
cd "$(git rev-parse --show-toplevel)" || exit 1

FILES=$(git diff --cached --name-only --diff-filter=AM) || { echo "[制御文字] git の一覧を取れませんでした。止めます" >&2; exit 1; }
[ -z "$FILES" ] && exit 0

FOUND=0
while IFS= read -r f; do
  [ -z "$f" ] && continue
  case "$f" in
    *.png|*.jpg|*.jpeg|*.gif|*.ico|*.pdf|*.zip|*.gz|*.sqlite|*.db|*.xlsx|*.docx|*.pptx) continue ;;
  esac
  # 足した行だけ（先頭が + で、+++ ではない行）。行末の CR は外してから見る
  ADDED=$(git diff --cached -U0 --no-color -- "$f") || { echo "[制御文字] $f の差分を取れませんでした。止めます" >&2; exit 1; }
  # grep -P は使わない（環境によって動かない）。tr で制御文字だけを残して数える
  N=$(printf '%s\n' "$ADDED" | grep -a '^+' | grep -av '^+++' | sed 's/\r$//' | LC_ALL=C tr -dc '\000\007\010\013\014\015' | wc -c | tr -d ' ')
  case "$N" in
    ''|*[!0-9]*) echo "[制御文字] 照合の道具が失敗しました（数を数えられない）。止めます" >&2; exit 1 ;;
  esac
  if [ "$N" -gt 0 ]; then
    echo "[制御文字] $f：足した行に、見えない制御文字が $N 文字入っています" >&2
    FOUND=1
  fi
done <<EOF
$FILES
EOF

if [ "$FOUND" -ne 0 ]; then
  echo "パスの \\a・\\r・\\v などが化けていないか確かめ、エディタ（AI なら編集の道具）で直してからコミットしてください。" >&2
  exit 1
fi
exit 0
