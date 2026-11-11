#!/bin/bash
# file: scripts/test-check-control-chars.sh
# template: REI
# title: 制御文字の点検の試験
# description: check-control-chars.sh が期待どおりに止める・通すかを確かめる
#
# check-control-chars.sh の試験
# 使い方: bash scripts/test-check-control-chars.sh [点検のスクリプトの場所]   （終了コード 0=全部期待どおり）
# 一時フォルダに git を作り、制御文字の入った行・CRLF の行・普通の行を足して、止まる／通るを見る。
set -u
CHECK="${1:-$(cd "$(dirname "$0")" && pwd)/check-control-chars.sh}"
TMP=$(mktemp -d)
cd "$TMP" || exit 1
git init -q
git config user.name "test"
git config user.email "test@example.invalid"
git config core.autocrlf false
FAILS=0
try() { # 名前 期待(0=通る/1=止まる) 書く中身(printf の書式)
  rm -f t.md; git reset -q 2>/dev/null
  printf "$3" > t.md
  git add t.md
  bash "$CHECK" >/dev/null 2>&1; local rc=$?
  local got=0; [ "$rc" -ne 0 ] && got=1
  if [ "$got" -eq "$2" ]; then echo "ok   $1"; else echo "NG   $1（期待=$2 実際の終了コード=$rc）"; FAILS=$((FAILS+1)); fi
}
try "普通の行は通る" 0 'docs/notes\n'
try "CRLF の行は通る" 0 'line1\r\nline2\r\n'
try "垂直タブ（化けた \\v）は止まる" 1 'docs\x0balue\n'
try "BEL（化けた \\a）は止まる" 1 'notes\x07rchive\n'
try "行の途中の CR（化けた \\r）は止まる" 1 'docs\x0deadme\n'
try "日本語だけの行は通る" 0 '作業記録の行です\n'
cd /; rm -rf "$TMP"
[ "$FAILS" -eq 0 ] && echo "全部期待どおり" || echo "期待と違う：$FAILS 件"
exit "$FAILS"
