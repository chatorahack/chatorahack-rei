#!/bin/bash
# file: scripts/check-forward-only.sh
# template: REI
# title: 決定ファイルの書き換えの点検
# description: コミットの中で、decisions/ の決定ファイルが書き換えられていないか確かめる
#
# check-forward-only.sh
# decisions/・docs/adr/配下の既存ファイルが書き換え・削除・リネームされていないかを検査する
# （追記のみ許可、Forward-only原則）。独立したスクリプトにしてあるのは、
# Claude Code の hook 以外（git pre-commit、使うなら CI）からも同じ検査を呼べるようにするため。
# この雛形では .githooks/pre-commit から呼ぶ。Claude Code の hook だけに依存すると、
# そのhookが動かない状況（人が直接コミットする、ほかの AI の道具を使う）では検査が効かない。
# git pre-commit・CIはツール・AIを問わず効く。
#
# 使い方:
#   bash scripts/check-forward-only.sh                # working treeの未コミット変更のみ検査
#   bash scripts/check-forward-only.sh <BASE_COMMIT>   # 上記に加え、BASE_COMMIT..HEAD のコミット済み変更も検査
#
# 終了コード: 違反なし=0／違反あり=1（詳細は標準出力）

set -u
PROTECTED_PATHS="decisions docs/adr"

# ステータスコードはM（変更）・D（削除）・R（リネーム）のいずれかを対象にする。XY2文字の
# どちらかがM/D/Rであれば検知する。
MOD=$(git status --porcelain -- $PROTECTED_PATHS 2>/dev/null | grep -E '^([MDR].|.[MDR])' | grep -vE ' (decisions|docs/adr)/0000-')

COMMIT_MOD=""
BASE="${1:-}"
if [ -n "$BASE" ]; then
  # -M でリネーム検出を明示的に有効化し、--diff-filterにRを含める。
  COMMIT_MOD=$(git diff -M --diff-filter=MDR --name-only "$BASE" HEAD -- $PROTECTED_PATHS 2>/dev/null | grep -vE '^(decisions|docs/adr)/0000-')
fi

if [ -z "$MOD" ] && [ -z "$COMMIT_MOD" ]; then
  echo "OK   decisions/・docs/adr/の既存ファイルへの書き換え・削除・リネームなし"
  exit 0
fi

echo "FAIL 既存のdecisions/・docs/adr/が書き換え・削除・リネームされています（新しい番号のファイルで上書き宣言する）:"
[ -n "$MOD" ] && echo "$MOD"
[ -n "$COMMIT_MOD" ] && echo "$COMMIT_MOD（コミット済み、BASE=$BASE 以降）"
exit 1
