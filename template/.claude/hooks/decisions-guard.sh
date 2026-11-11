#!/bin/bash
# file: .claude/hooks/decisions-guard.sh
# template: REI
# title: 決定ファイルの書き換えの確認（Edit・Write）
# description: AI が Edit・Write で decisions/ の決定ファイルを書き換えようとしたとき、人に確認を求める
#
# decisions-guard.sh
# PreToolUse（Edit|Write|MultiEditにマッチ）。同一プロジェクト内での`decisions/`・`docs/adr/`
# 配下の既存ファイルへの直接編集を、書き込みの瞬間に検知する。
#
# scope-guard.shとの違い：scope-guard.shは「このプロジェクトの外への書き込みか」（境界の話）を見る。
# decisions-guard.shは「このプロジェクトの中であっても、Forward-only対象の既存ファイルに触れて
# いないか」（内容の話）を見る。コミット時の点検（scripts/check-forward-only.sh）が事後検知なのに対して、こちらは
# 事前検知（ツール呼び出しの直前）——サブエージェント内の呼び出しにも同様に効く
# （PreToolUse はサブエージェントの中でも動く）。
#
# 限界（正直に）：あくまで催促（permissionDecision: "ask"）であり強制ではない。
set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/json-field.sh"
INPUT=$(cat)
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || true

printf '%s decisions-guard agent=main\n' "$(date -Iseconds)" >> .claude/hook-executed.log 2>/dev/null || true

FILE_PATH=$(json_field file_path "$INPUT")
# JSON中のバックスラッシュは2文字1組でエスケープされた1文字分。tr '\\' '/'だと // になるので、
# sed で2文字を1文字の / にしてから比べる。
NORM_FILE_PATH=$(printf '%s' "$FILE_PATH" | sed 's/\\\\/\//g')

if [ -z "$NORM_FILE_PATH" ]; then
  exit 0
fi

# decisions/・docs/adr/配下で、0000-*（テンプレート雛形）以外を対象にする。
case "$NORM_FILE_PATH" in
  */decisions/0000-*|*/docs/adr/0000-*) exit 0 ;;
  */decisions/*|*/docs/adr/*) : ;;
  *) exit 0 ;;
esac

# 相対パスに変換して、実際にgitで追跡されている既存ファイルかどうかを判定する
# （新規作成中のファイルは対象外——追記は許可する）。
# pwd -W が無い環境（macOS・Linux など）では pwd を使う。
PROJECT_ROOT_NORM=$(cd "${CLAUDE_PROJECT_DIR:-.}" && { pwd -W 2>/dev/null || pwd; } | sed 's/\\\\/\//g')
if [ -z "$PROJECT_ROOT_NORM" ]; then
  # scope-guard.shと同じ理由で自己申告する（黙って無効になると誰も気づかないため）。
  printf 'degraded decisions-guard %s reason=project_root_unresolved CLAUDE_PROJECT_DIR=%s\n' \
    "$(date -Iseconds)" "${CLAUDE_PROJECT_DIR:-<unset>}" >> .claude/guard-status 2>/dev/null || true
  exit 0
fi
REL_PATH="${NORM_FILE_PATH#$PROJECT_ROOT_NORM/}"
# gitの外では追跡の判定ができず、ガードが黙って無効になるので記録に残す
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  printf 'degraded decisions-guard %s reason=not_a_git_repo file=%s\n' "$(date -Iseconds)" "$REL_PATH" >> .claude/guard-status 2>/dev/null || true
  exit 0
fi
if ! git ls-files --error-unmatch "$REL_PATH" >/dev/null 2>&1; then
  exit 0
fi

echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"ask\",\"permissionDecisionReason\":\"[REI decisions-guard] 既存の決定ファイル（${REL_PATH}）への直接編集です。Forward-only原則により、既存ファイルは書き換えません。覆す場合は新しい番号のファイルを追加してください。\"}}"
exit 0
