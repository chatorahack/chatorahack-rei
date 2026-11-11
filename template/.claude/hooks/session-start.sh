#!/bin/bash
# file: .claude/hooks/session-start.sh
# template: REI
# title: 起動のときの知らせ
# description: Claude Code の起動のたびに、起動の記録・人が渡した資料・新しい版・止めた印などを AI と人に知らせる
#
# SessionStart hook（雛形の版はここに書かない。受け取りの記録 .rei/received.cfg から読む。v0.3.0-beta.24）
# 起動したことを記録する（方針はCLAUDE.mdの@読み込みで届ける。hookでは注入しない＝二重にしない）。
# 記録はREIが起動したかを後から確かめる証拠。
# REI本体の場所が未記入なら「未同期」と出す（本体に届かなくても止まらずに続ける）。
#
# 出力（v0.3.0-beta.27）：標準出力には JSON を1つだけ出す（ほかの文字が混ざると Claude Code は JSON として読まない）。
#   hookSpecificOutput.additionalContext … AI に渡す文脈（[REI] の行と同じ中身）
#   systemMessage                         … 人の画面に出す知らせ（知らせることがあるときだけ）
# 公式：https://code.claude.com/docs/en/hooks（「systemMessage: Warning message shown to the user」、2026-11-08 確認）
set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/json-field.sh"
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || true
INPUT=$(cat)
EVENT=$(json_field hook_event_name "$INPUT")
SOURCE=$(json_field source "$INPUT")
LOG=.claude/hook-executed.log

CTX=""   # AI に渡す行
SYS=""   # 人の画面に出す行
say() { CTX="$CTX$1"$'\n'; }
tell() { SYS="$SYS$1"$'\n'; }
json_str() { # JSON の文字列の中身にする（制御文字は消し、\ と " と改行・タブを書き換える）
  local s
  s=$(printf '%s' "$1" | tr -d '\000-\010\013\014\016-\037')
  s="${s//\\/\\\\}"; s="${s//\"/\\\"}"; s="${s//$'\r'/}"; s="${s//$'\t'/\\t}"; s="${s//$'\n'/\\n}"
  printf '%s' "$s"
}

# 版は受け取りの記録から読む（git の設定ファイルの書式。docs/howto/upgrade.md「受け取りの記録」）。読めなければ unknown
REC=.rei/received.cfg
LOCAL=.rei/local.cfg   # 機械ごとの設定（git に入れない。写しのフォルダ、最後に比べた日）
VER=""
if [ -f "$REC" ] && command -v git >/dev/null 2>&1; then
  VER=$(git config --file "$REC" template.version 2>/dev/null || true)
fi
printf '%s event=%s source=%s rei=%s\n' "$(date -Iseconds)" "${EVENT:-SessionStart}" "${SOURCE:-unknown}" "${VER:-unknown}" >> "$LOG" 2>/dev/null || true

# 生ログ（Claude Codeが残す会話の全記録）のファイル名を記録する。あとで辿れるように。
# 場所は ~/.claude/projects/<作業フォルダから作られる名前>/<このファイル名> で導ける。
# フォルダの部分はアカウント名を含みうるので記録しない（ファイル名＝session_idだけ）。
TP=$(json_field transcript_path "$INPUT")
if [ -n "$TP" ]; then
  TP=$(printf '%s' "$TP" | sed 's/\\\\/\//g')
  printf '%s transcript=%s\n' "$(date -Iseconds)" "${TP##*/}" >> "$LOG" 2>/dev/null || true
fi

# AGENTS.md「REI本体の場所：」の後ろが空なら未同期
if ! grep -qE '^- REI本体の場所：[[:space:]]*[^[:space:]]' AGENTS.md 2>/dev/null; then
  say "[REI] REI本体：未設定（未同期）。このプロジェクトだけで続ける"
  printf '%s rei-body=unsynced\n' "$(date -Iseconds)" >> "$LOG" 2>/dev/null || true
fi

# 新しい版の知らせ（v0.3.0-beta.24。写しの置き場所は beta.27 から .rei/local.cfg）。
# 写し（REI を clone したフォルダ）の CHANGELOG.md の一番上の版と、受け取りの記録の版を比べる。新しければ知らせるだけで、上げはしない。
# ネットには出ない（写しを新しくするのは人。git -C <写し> pull）。写しのパスはアカウント名を含みうるので、出さない・記録しない。
ver_gt() { # $1 が $2 より新しいか（x.y.z と、後ろの -beta.N などを見る。-beta の付かない版は付く版より新しい）
  [ "$1" = "$2" ] && return 1
  local ba="${1%%-*}" bb="${2%%-*}" pa="" pb=""
  case "$1" in *-*) pa="${1#*-}" ;; esac
  case "$2" in *-*) pb="${2#*-}" ;; esac
  if [ "$ba" != "$bb" ]; then
    [ "$(printf '%s\n%s\n' "$ba" "$bb" | sort -V | tail -1)" = "$ba" ]; return
  fi
  [ -z "$pa" ] && return 0
  [ -z "$pb" ] && return 1
  [ "$(printf '%s\n%s\n' "$pa" "$pb" | sort -V | tail -1)" = "$pa" ]
}
if [ -z "$VER" ]; then
  say "[REI] 版の記録（.rei/received.cfg）が読めません。新しい版があるかは見ていません（docs/howto/upgrade.md「受け取りの記録」）"
  tell "[REI] 版の記録（.rei/received.cfg）が読めないので、新しい版があるかを見ていません。docs/howto/upgrade.md「受け取りの記録」"
else
  COPY=""
  [ -f "$LOCAL" ] && COPY=$(git config --file "$LOCAL" copy.path 2>/dev/null || true)
  if [ -n "$COPY" ] && [ -f "$COPY/CHANGELOG.md" ]; then
    LATEST=$(tr -d '\r' < "$COPY/CHANGELOG.md" 2>/dev/null | grep -m1 -E '^## \[[0-9]+\.[0-9]+\.[0-9]+[^]]*\] - ' | sed -E 's/^## \[([^]]+)\].*/\1/')
    git config --file "$LOCAL" copy.last-checked "$(date +%Y-%m-%d)" >/dev/null 2>&1 || true
    CDATE=$(git -C "$COPY" log -1 --format=%cs 2>/dev/null || true)
    BASIS="手元の写しを見ています（写しの最後のコミット：${CDATE:-不明}。新しくするのは人：git -C <写し> pull）"
    if [ -n "$LATEST" ] && ver_gt "$LATEST" "$VER"; then
      R=0; M=0; O=0; N=0; H=0; P=0
      if [ -f "$COPY/changes.cfg" ]; then
        while IFS= read -r line; do
          [ -z "$line" ] && continue
          k="${line%% *}"; s="${line#* }"; v="${k#change.}"; v="${v%.severity}"
          ver_gt "$v" "$VER" || continue
          ver_gt "$v" "$LATEST" && continue
          # 先に取り込んだ版（[picked "<版>"]、upgrade-plan.sh --only。v0.3.0-beta.30）は数えない
          git config --file "$REC" --get "picked.$v.applied" >/dev/null 2>&1 && { P=$((P+1)); continue; }
          N=$((N+1))
          case "$s" in required) R=$((R+1)) ;; recommended) M=$((M+1)) ;; optional) O=$((O+1)) ;; esac
          # 上げるときに手作業が要る版（changes.cfg の manual。v0.3.0-beta.28）
          git config --file "$COPY/changes.cfg" --get "change.$v.manual" >/dev/null 2>&1 && H=$((H+1))
        done <<CHANGES
$(git config --file "$COPY/changes.cfg" --get-regexp '^change\..*\.severity$' 2>/dev/null || true)
CHANGES
        HAND=""; [ "$H" -gt 0 ] && HAND="。手作業あり $H（CHANGELOG の各版の「上げ方」を読む）"
        PICK=""; [ "$P" -gt 0 ] && PICK="。先に取り込んだ $P 版は数えていない"
        if [ "$N" -gt 0 ]; then
          say "[REI] 新しい版 $LATEST があります（このプロジェクトは $VER）。間の $N 版：必須 $R・推奨 $M・任意 $O$HAND$PICK。上げるかは人が決めます（手順は docs/howto/upgrade.md。必須の版は飛ばさない）。$BASIS"
          NEWNOTICE="$LATEST"
          tell "[REI] REI の新しい版 $LATEST があります（このプロジェクトは $VER。間の $N 版のうち必須 $R$HAND$PICK）。上げるかはあなたが決めます（docs/howto/upgrade.md）。$BASIS"
        fi
      else
        say "[REI] 新しい版 $LATEST があります（このプロジェクトは $VER）。重さは数えていません（写しに changes.cfg が無い）。上げるかは人が決めます（docs/howto/upgrade.md）。$BASIS"
        NEWNOTICE="$LATEST"
        tell "[REI] REI の新しい版 $LATEST があります（このプロジェクトは $VER）。上げるかはあなたが決めます（docs/howto/upgrade.md）。$BASIS"
      fi
      [ "$R" -gt 0 ] && say "      必須の版があります。この知らせを人に伝えてください。"
      printf '%s rei-update=%s\n' "$(date -Iseconds)" "$LATEST" >> "$LOG" 2>/dev/null || true
    fi
  elif [ -n "$COPY" ]; then
    say "[REI] .rei/local.cfg の写しのフォルダ（copy.path）に CHANGELOG.md がありません。新しい版があるかは見ていません"
    tell "[REI] REI の写しのフォルダ（.rei/local.cfg の copy.path）に CHANGELOG.md が無いので、新しい版があるかを見ていません"
  elif ! grep -q 'version-check=off' "$LOG" 2>/dev/null; then
    # 写しが書かれていないときは、一度だけ知らせる（毎回は出さない。記録に印を残す）
    say "[REI] 新しい版があるかは見ていません（REI の写しのフォルダが未設定。docs/howto/upgrade.md「新しい版の知らせ」）"
    tell "[REI] 新しい版があるかは見ていません。REI を clone したフォルダを書くと、起動のときに比べます：git config --file .rei/local.cfg copy.path <フォルダ>（この知らせは一度だけ）"
    printf '%s version-check=off\n' "$(date -Iseconds)" >> "$LOG" 2>/dev/null || true
  fi
fi

# 版上げの試し（scripts/upgrade-try.sh の git worktree）が残っていれば知らせる（v0.3.0-beta.29）。パスは出さない
TRYNAME="$(basename "$(pwd)")-rei-try"
if command -v git >/dev/null 2>&1 && git worktree list --porcelain 2>/dev/null | sed -n 's/^worktree //p' | grep -q -- "/$TRYNAME\$"; then
  say "[REI] 版上げの試し（../$TRYNAME）が残っています。報告は .rei/reports/。入れるか捨てるかを人に聞く（bash scripts/upgrade-try.sh --status・--discard）"
  tell "[REI] 版上げの試し（../$TRYNAME）が残っています。入れるか捨てるかを決めてください（報告は .rei/reports/、捨てるなら bash scripts/upgrade-try.sh --discard）"
fi

# 止めた印が残っていれば知らせる（セッションをまたいでも、なぜ道具が止まっているか分かるように）
if [ -f .claude/stop-requested ]; then
  say "[REI] 停止中：前に人間が「止めて」と言った印（.claude/stop-requested）が残っています。人間が消すまで、すべての道具は止まります。"
  tell "[REI] 停止中：前に「止めて」と言った印（.claude/stop-requested）が残っています。消すまで、AI はどの道具も使えません。"
  printf '%s stop-guard still-stopped\n' "$(date -Iseconds)" >> "$LOG" 2>/dev/null || true
fi

# 人が渡した持ち物を見せる：この作業フォルダにある、REI の雛形以外のもの＝人間が渡した資料。
# 発見を AI の偶然の一覧に頼らず、毎セッション知らせる。初めての分野では、答える（特に簡易診断）の前に必ず開く。
# ls -A は名前だけ（所有者欄を出さない＝アカウント名などの個人情報を混ぜない）。
TPL=" AGENTS.md CHANGELOG.md CLAUDE.md GOAL.md START.md handoff.md policy.md decisions docs ledger scripts pii_patterns.example.txt _inbox _archive .rei .claude .gitignore .git .githooks .gitattributes "
HANDED=""
# 1行ずつ読む（空白を含む名前が2つに割れないように）。
# 空白を含む名前は「」で囲んで出す（どこまでが1つの名前か分かるように）
while IFS= read -r e; do
  [ -z "$e" ] && continue
  case "$TPL" in *" $e "*) continue ;; esac
  case "$e" in *" "*) HANDED="$HANDED 「$e」" ;; *) HANDED="$HANDED $e" ;; esac
done <<HANDED_LIST
$(ls -A 2>/dev/null)
HANDED_LIST
if [ -n "$HANDED" ]; then
  say "[REI] 人が渡したもの（この作業フォルダの、REI の雛形以外）：$HANDED"
  say "      初めての分野の相談なら、答える（特に簡易診断）の前に、これを必ず開いて中身を見てください。開いていないのに「無い・空」と書かないこと（docs/unknown.md 0.）。"
  printf '%s handed=%s\n' "$(date -Iseconds)" "$HANDED" >> "$LOG" 2>/dev/null || true
fi

# 受け取った資料の置き場（_inbox）に、処理していない資料があれば見せる（v0.3.0-beta.6）。
# 「_about.txt」は説明なので数えない。名前に空白があっても1件として数えるよう、1行ずつ読む。
INBOX=""
if [ -d _inbox ]; then
  while IFS= read -r e; do
    [ -z "$e" ] && continue
    [ "$e" = "_about.txt" ] && continue
    INBOX="$INBOX $e"
  done <<INBOX_LIST
$(ls -A _inbox 2>/dev/null)
INBOX_LIST
fi
if [ -n "$INBOX" ]; then
  say "[REI] _inbox に処理していない資料：$INBOX"
  say "      開いて中身を見たうえで、台帳か docs に要ることを書き、元の資料を _archive へ移す（docs/howto/inbox.md。移す前に人に確かめる）。"
  printf '%s inbox=%s\n' "$(date -Iseconds)" "$INBOX" >> "$LOG" 2>/dev/null || true
fi

# 状態の控え（v0.3.0-beta.31）：ステータスライン（.claude/statusline.sh）と /rei が読む。git に入れない（.gitignore）。
# ステータスラインは応答のたびに動くので、版の比べはここ（起動のとき）だけで行い、結果を控える。パスは書かない
if [ -d .claude ]; then
  CP=unset; [ -n "${COPY:-}" ] && { [ -f "$COPY/CHANGELOG.md" ] && CP=set || CP=missing; }
  NW="${NEWNOTICE:-}"
  printf '# REI の状態の控え（起動のときに session-start.sh が書く。git に入れない）\n[state]\n\tversion = %s\n\tlatest = %s\n\tbetween = %s\n\trequired = %s\n\tcopy = %s\n\tchecked = %s\n' \
    "${VER:-}" "$NW" "${N:-}" "${R:-}" "$CP" "$(date +%Y-%m-%d)" > .claude/rei-state 2>/dev/null || true
fi

# /rei（状態とメニュー、v0.3.0-beta.31）：AI には最初の一度だけ伝える。人には、ほかの知らせを出すときに1行添える
if ! grep -q 'rei-menu-told' "$LOG" 2>/dev/null; then
  say "[REI] /rei（.claude/skills/rei）で、人が REI の状態とメニュー（新しい版を見る・試す・版を選ぶ・画面の下のステータスラインを付ける）を出せる。版上げやステータスラインのことを聞かれたら案内する"
  printf '%s rei-menu-told\n' "$(date -Iseconds)" >> "$LOG" 2>/dev/null || true
fi
[ -n "$SYS" ] && tell "[REI] 状態とメニューは /rei"

# 出力：JSON を1つだけ（何も知らせることが無ければ何も出さない）
CTX="${CTX%$'\n'}"; SYS="${SYS%$'\n'}"
if [ -n "$CTX" ] || [ -n "$SYS" ]; then
  out='{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"'"$(json_str "$CTX")"'"}'
  [ -n "$SYS" ] && out="$out"',"systemMessage":"'"$(json_str "$SYS")"'"'
  printf '%s}\n' "$out"
fi
exit 0
