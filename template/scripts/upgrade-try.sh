#!/bin/bash
# file: scripts/upgrade-try.sh
# template: REI
# title: 版上げの試し
# description: 版上げを、本体の隣の別の作業フォルダで試してから入れる
# caution: 未コミットの変更があると止まる
#
# upgrade-try.sh（v0.3.0-beta.29）：雛形を新しい版に上げるのを、別の作業フォルダで試す。本体の作業フォルダには触らない。
# 別の作業フォルダは git worktree（ブランチを作らない detached）で、本体の隣に <プロジェクト名>-rei-try として作る。
#
# 使い方（プロジェクトのどこからでも）：
#   bash scripts/upgrade-try.sh <古い雛形の template> <新しい雛形の template>   … 試す
#   bash scripts/upgrade-try.sh --only <版>[,<版>…] <REI の写し>             … 版を選んで取り込むのを試す（v0.3.0-beta.30。必須は飛ばせない。
#                                                                               upgrade-plan.sh --only の説明を読む。受け取りの記録は当てず、報告に書き方を出す）
#   bash scripts/upgrade-try.sh --status                                      … 試しが残っているか
#   bash scripts/upgrade-try.sh --discard                                     … 試しを捨てる（git worktree remove。消せなければ止まる）
# 流れ（Detect → Plan → Stage → Validate → Report。入れるか捨てるかは人）：
#   1. 止める条件：作業ツリーに未コミットの変更がある、前の試しが残っている、git のロックファイル（index.lock）がある
#   2. 本体の HEAD と状態を控える
#   3. git worktree add --detach で試しのフォルダを作る
#   4. 新しい雛形の upgrade-plan.sh（REI_PLAN_FORMAT=tsv）のとおりに機械で当てる：入れ替え・足すは写す、3方向は git merge-file、消すは消す。
#      見る・確かめる・残す・受け取らないは当てずに報告に並べる
#   5. 確かめる：ぶつかりの印、bash の構文、JSON の書式（python があれば）、scripts/check-received.sh、雛形の点検の試験、
#      本体の HEAD と状態が変わっていないこと、git の設定（quotepath・autocrlf・filemode・safecrlf）
#   6. 報告を .rei/reports/upgrade-try-<日時>.md に書く（git に入れない。手元のパスが入るので、記録に貼るときは消す）
# 採るとき：報告の「採る」の手順（試しの中でコミット → 本体で git merge --ff-only）。捨てるとき：--discard。
# Claude Code は起動しない（試しのフォルダで起動すると、~/.claude/projects に別の記録ができる）。ネットには出ない。
# 限界：意味の変化（決まりが変わったので台帳の書き方も変えるべきか）は見ない。報告の「間の版」と CHANGELOG を読む。
set -u
export LC_ALL=C.UTF-8
TOP=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "[upgrade-try] git のリポジトリの中で流してください" >&2; exit 2; }
# 試しのフォルダ（git worktree）の中から流したら止める（v0.3.0-beta.32。中では名前が <名前>-rei-try になり、別の答えになる）
if [ "$(git rev-parse --path-format=absolute --git-dir 2>/dev/null)" != "$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" ]; then
  echo "[upgrade-try] ここは git worktree の中です（版上げの試しのフォルダかもしれません）。本体のフォルダで流してください。止めます" >&2; exit 2
fi
# git の出力に出る手元のパスを伏せる（アカウント名を含みうる。v0.3.0-beta.32）
hide() { local up; up=$(dirname "$TOP"); sed -e "s#$TOP#<プロジェクト>#g" -e "s#$up#..#g"; }
NAME=$(basename "$TOP")
WT="$(dirname "$TOP")/$NAME-rei-try"
wt_registered() { git -C "$TOP" worktree list --porcelain 2>/dev/null | sed -n 's/^worktree //p' | grep -q -- "/$NAME-rei-try\$"; }
# 試しのフォルダの指紋（変更・未追跡のファイルの一覧と中身）。当てた直後に控え、捨てるときに比べる。
# 同じなら、変わっているのはこのスクリプトが当てた分だけなので、戻してから普通に消す。違えば（人が直し始めていれば）止める
FP_FILE=$(git -C "$TOP" rev-parse --path-format=absolute --git-path rei-try-fingerprint 2>/dev/null)
# 試しのフォルダを作ったときのコミットの控え（v0.3.0-beta.34。採ったあとの片付けを、捨てたのと見分ける）
BASE_FILE=$(git -C "$TOP" rev-parse --path-format=absolute --git-path rei-try-base 2>/dev/null)
fingerprint() {
  { git -C "$WT" status --porcelain=v1 -uall 2>/dev/null
    git -C "$WT" diff HEAD 2>/dev/null
    git -C "$WT" ls-files -o --exclude-standard 2>/dev/null | while IFS= read -r u; do printf '%s %s\n' "$u" "$(git hash-object "$WT/$u" 2>/dev/null)"; done
  } | git hash-object --stdin
}

case "${1:-}" in
  --status)
    if wt_registered || [ -e "$WT" ]; then echo "[upgrade-try] 前の試しが残っています：../$NAME-rei-try（捨てるなら --discard）"; exit 1; fi
    echo "[upgrade-try] 試しは残っていません"; exit 0 ;;
  --discard)
    ADOPTED=""
    if wt_registered; then
      # 採ったあとか（試しのフォルダに変更が無く、そのコミットが本体に入っている）
      # 判断：試しのフォルダに変更が無い、HEAD が作ったときのコミット（控え）から進んでいる、そのコミットが本体に入っている
      WH=$(git -C "$WT" rev-parse HEAD 2>/dev/null || true); WB=$(cat "$BASE_FILE" 2>/dev/null || true)
      if [ -n "$WH" ] && [ -n "$WB" ] && [ "$WH" != "$WB" ] && [ -z "$(git -C "$WT" status --porcelain 2>/dev/null)" ] \
         && git -C "$TOP" merge-base --is-ancestor "$WH" HEAD 2>/dev/null; then ADOPTED=1; fi
      if [ -f "$FP_FILE" ] && { [ "$(cat "$FP_FILE")" = pending ] || [ "$(cat "$FP_FILE")" = "$(fingerprint)" ]; }; then
        # 試しを作ってから、だれも手を加えていない（pending＝当てている途中で止まった。v0.3.0-beta.32）：このスクリプトが当てた分を戻してから消す
        [ "$(cat "$FP_FILE")" = pending ] && echo "[upgrade-try] 当てている途中で止まった試しです。当てた分を戻してから消します"
        git -C "$WT" reset -q --hard 2>/dev/null; git -C "$WT" clean -q -fd 2>/dev/null
      fi
      if ! out=$(git -C "$TOP" worktree remove "$WT" 2>&1); then
        if [ -f "$FP_FILE" ]; then
          echo "[upgrade-try] 試しのフォルダを消せませんでした。試しを作ったあとに、だれかが中を直しています（またはほかのプログラムが開いています）：" >&2
        else
          echo "[upgrade-try] 試しのフォルダを消せませんでした。当てたあとの控え（指紋）が無いので、中の変更がこのスクリプトのものか分かりません（古い版の upgrade-try で作った、控えが消えた、など）：" >&2
        fi
        printf '%s\n' "$out" | hide | sed 's/^/  /' >&2
        echo "  直したものを残すなら、先に採る手順（報告の「採る」）で入れる。捨てると人が決めたら：git worktree remove --force ../$NAME-rei-try" >&2
        exit 1
      fi
      rm -f "$FP_FILE" "$BASE_FILE"
    elif [ -e "$WT" ]; then
      echo "[upgrade-try] ../$NAME-rei-try は git の試しのフォルダではありません。中を確かめて、人が消してください" >&2; exit 1
    fi
    git -C "$TOP" worktree prune 2>/dev/null || true
    left=$(git -C "$TOP" worktree list --porcelain 2>/dev/null | grep -c -- "/$NAME-rei-try\$" || true)
    if [ "${left:-0}" = 0 ] && [ ! -e "$WT" ]; then
      if [ -n "$ADOPTED" ]; then echo "[upgrade-try] 採った試しのフォルダを片付けました（中身は本体に入っています。残り 0）"
      else echo "[upgrade-try] 捨てました（残り 0）"; fi
      exit 0
    fi
    echo "[upgrade-try] まだ残っています：../$NAME-rei-try" >&2; exit 1 ;;
esac

USAGE="使い方：bash scripts/upgrade-try.sh <古い雛形の template> <新しい雛形の template>、または --only <版>[,<版>…] <REI の写し>（--status・--discard）"
MODE=full
if [ "${1:-}" = --only ]; then
  # 版を選んで取り込む（v0.3.0-beta.30）。一覧は写しの upgrade-plan.sh --only。版ごとに当ててから、次の版の一覧を試しのフォルダで出す
  [ $# -ge 3 ] && [ -n "$2" ] && [ -d "$3" ] || { echo "$USAGE" >&2; exit 2; }
  MODE=only; ONLYV="$2"; SRC=$(cd "$3" && pwd); PLANSH="$SRC/template/scripts/upgrade-plan.sh"
else
  [ $# -ge 2 ] && [ -d "$1" ] && [ -d "$2" ] || { echo "$USAGE" >&2; exit 2; }
  OLD=$(cd "$1" && pwd); NEW=$(cd "$2" && pwd); PLANSH="$NEW/scripts/upgrade-plan.sh"
fi
cd "$TOP" || exit 2
[ -f "$PLANSH" ] || { echo "[upgrade-try] 新しい雛形に scripts/upgrade-plan.sh がありません" >&2; exit 2; }
ERRF=$(mktemp)
if [ "$MODE" = only ]; then
  PLAN=$(REI_PLAN_FORMAT=tsv bash "$PLANSH" --only "$ONLYV" "$SRC" "$TOP" 2>"$ERRF" </dev/null); rc=$?
  [ "$rc" = 0 ] || { sed 's/^/  /' "$ERRF" >&2; rm -f "$ERRF"; echo "[upgrade-try] 取り込む版を決められませんでした。止めます（写しの upgrade-plan.sh が --only を知らない版なら、写しを新しくする）" >&2; exit 2; }
  CACHE=$(git -C "$TOP" rev-parse --path-format=absolute --git-path rei-versions)
else
  PLAN=$(REI_PLAN_FORMAT=tsv bash "$PLANSH" "$OLD" "$NEW" "$TOP" 2>"$ERRF" </dev/null)
fi
rm -f "$ERRF"
printf '%s\n' "$PLAN" | grep -q "^[a-z]*$(printf '\t')" || { echo "[upgrade-try] 新しい雛形の upgrade-plan.sh が機械の読む形（REI_PLAN_FORMAT=tsv、beta.29 から）を出しません" >&2; exit 2; }
if printf '%s\n' "$PLAN" | grep -q '^uptodate'; then
  [ "$MODE" = only ] && { echo "[upgrade-try] 取り込む版はありません（選んだ版は、もう取り込んでいます）"; exit 0; }
  echo "[upgrade-try] このプロジェクトの受け取りの記録は、もう新しい雛形の版です。試すことはありません"; exit 0
fi

# 1. 止める条件
LOCK=$(git rev-parse --git-path index.lock)
[ -e "$LOCK" ] && { echo "[upgrade-try] git のロックファイルが残っています（$(printf %s "$LOCK" | hide)）。ほかの git が動いていないか確かめてから、人が消してください。止めます" >&2; exit 1; }
DIRTY=$(git status --porcelain --untracked-files=no)
[ -z "$DIRTY" ] || { echo "[upgrade-try] 作業ツリーに未コミットの変更があります。先にコミットするか、よけてください。止めます：" >&2; printf '%s\n' "$DIRTY" | sed 's/^/  /' >&2; exit 1; }
if wt_registered || [ -e "$WT" ]; then echo "[upgrade-try] 前の試しが残っています（../$NAME-rei-try）。--status で見て、--discard で捨ててから試してください。止めます" >&2; exit 1; fi

# 2. 本体を控える
HEAD0=$(git rev-parse HEAD); ST0=$(git status --porcelain --untracked-files=no); BR0=$(git branch --show-current)

# 3. 試しのフォルダ
trap 'echo "[upgrade-try] 途中で止まりました。試しのフォルダが残っています：bash scripts/upgrade-try.sh --discard で捨てる" >&2; exit 130' INT TERM
git worktree add --quiet --detach "$WT" HEAD 2>/dev/null || { echo "[upgrade-try] 試しのフォルダを作れませんでした（../$NAME-rei-try）。止めます" >&2; exit 1; }
# 当てている途中の印（v0.3.0-beta.32）。途中で止まっても --discard が「人が直した」と取り違えないように。当て終わったら本当の指紋で上書きする
echo pending > "$FP_FILE" 2>/dev/null || true
git -C "$WT" rev-parse HEAD > "$BASE_FILE" 2>/dev/null || true

# 4. 当てる
TAB=$(printf '\t')
REPLACED=""; ADDED=""; REMOVED=""; MERGED=""; CONFLICT=""; LOOK=""; CHECK=""; KEEP=""; SKIP=""; XFILES=""; ERR=""; STEPSDONE=""
apply_rows() { # $1＝一覧（機械の形）。今の OLD・NEW の雛形から、試しのフォルダに当てる
while IFS="$TAB" read -r code f x; do
  [ -z "${code:-}" ] && continue
  case "$code" in
    replace|add)
      mkdir -p "$(dirname "$WT/$f")" && cp "$NEW/$f" "$WT/$f" || ERR="$ERR $f"
      [ "$code" = replace ] && REPLACED="$REPLACED$f"$'\n' || ADDED="$ADDED$f"$'\n' ;;
    merge)
      # 行末をそろえてから当てる（core.autocrlf=true だと試しのフォルダは CRLF、雛形は LF で、git merge-file は全部の行をぶつかりにする）。
      # 書き出すのは LF。コミットのときに .gitattributes の決まりで行末が決まる
      TM=$(mktemp -d)
      tr -d '\r' < "$WT/$f" > "$TM/p"; tr -d '\r' < "$OLD/$f" > "$TM/o"; tr -d '\r' < "$NEW/$f" > "$TM/n"
      git merge-file -L プロジェクト -L 古い雛形 -L 新しい雛形 "$TM/p" "$TM/o" "$TM/n" >/dev/null 2>&1; rc=$?
      cp "$TM/p" "$WT/$f"; rm -rf "$TM"
      if [ "$rc" -gt 0 ] && [ "$rc" -lt 128 ]; then CONFLICT="$CONFLICT$f（$rc か所）"$'\n'; elif [ "$rc" -ne 0 ]; then ERR="$ERR $f"; fi
      MERGED="$MERGED$f"$'\n' ;;
    remove) rm -f "$WT/$f"; REMOVED="$REMOVED$f"$'\n' ;;
    look) LOOK="$LOOK$f"$'\n' ;;
    check) CHECK="$CHECK$f"$'\n' ;;
    keep) KEEP="$KEEP$f"$'\n' ;;
    skip) SKIP="$SKIP$f"$'\n' ;;
  esac
  [ -n "${x:-}" ] && XFILES="$XFILES$f"$'\n'
done <<PLANROWS
$1
PLANROWS
}
if [ "$MODE" = only ]; then
  # 版ごとに：その版と1つ前の版の雛形（写しのタグから取り出したもの）で、試しのフォルダの今の中身に対して一覧を出し、当てる
  while IFS="$TAB" read -r code v p; do
    [ "$code" = step ] || continue
    OLD="$CACHE/$p/template"; NEW="$CACHE/$v/template"
    apply_rows "$(REI_PLAN_FORMAT=tsv REI_PLAN_PART=1 REI_PLAN_ONLY=1 bash "$PLANSH" "$OLD" "$NEW" "$WT" 2>/dev/null </dev/null)"
    STEPSDONE="$STEPSDONE$v "
  done <<STEPROWS
$PLAN
STEPROWS
  # 2つの版で同じファイルを当てたときは1つに数える
  uq() { local o; o=$(printf '%s' "$1" | awk 'NF && !s[$0]++'); [ -n "$o" ] && printf '%s\n' "$o"; }
  for vn in REPLACED ADDED REMOVED MERGED CONFLICT LOOK CHECK KEEP SKIP XFILES; do
    val=$(uq "${!vn}"; echo .); printf -v "$vn" '%s' "${val%.}"
  done
else
  apply_rows "$PLAN"
  # 受け取りの記録は当てずに残した（v0.3.0-beta.32）。試しのフォルダの記録に、新しい版（と、新しい雛形が REI の clone ならそのコミット）だけを書く
  NV=$(git config --file "$NEW/.rei/received.cfg" template.version 2>/dev/null || true)
  if [ -n "$NV" ] && [ -f "$WT/.rei/received.cfg" ] && printf '%s' "$KEEP" | grep -qx '.rei/received.cfg'; then
    git config --file "$WT/.rei/received.cfg" template.version "$NV"
    NTOP=$(git -C "$NEW" rev-parse --show-toplevel 2>/dev/null || true)
    if [ -n "$NTOP" ] && [ "$NTOP" -ef "$NEW/.." ]; then git config --file "$WT/.rei/received.cfg" template.commit "$(git -C "$NEW" rev-parse HEAD)"; else git config --file "$WT/.rei/received.cfg" template.commit ""; fi
    RECWROTE="受け取りの記録の version を $NV にした（commit は$( [ -n "$NTOP" ] && [ "$NTOP" -ef "$NEW/.." ] && echo "新しい雛形のコミット" || echo "空にした。REI の写しのタグから書く")。applied・decision・claude-code は人が書く）"
  fi
fi

fingerprint > "$FP_FILE" 2>/dev/null || true

# 5. 確かめる
cnt() { printf '%s' "$1" | grep -c . || true; }
lines() { printf '%s' "$1" | sed '/^$/d; s/^/- /'; }
MARKS=""
while IFS= read -r f; do [ -n "$f" ] && grep -q '^<<<<<<< ' "$WT/$f" 2>/dev/null && MARKS="$MARKS$f"$'\n'; done <<M
$MERGED
M
SYNTAX=""
while IFS= read -r f; do
  [ -n "$f" ] || continue
  case "$f" in *.sh|.githooks/*) bash -n "$WT/$f" 2>/dev/null || SYNTAX="$SYNTAX$f（bash の構文）"$'\n' ;; esac
done <<S
$REPLACED$ADDED$MERGED
S
PY=""; command -v python >/dev/null 2>&1 && python -I -c 'pass' >/dev/null 2>&1 && PY=python
JSONR=""
while IFS= read -r f; do
  [ -n "$f" ] || continue
  case "$f" in *.json)
    if [ -n "$PY" ]; then "$PY" -I -c 'import json,sys; json.load(open(sys.argv[1],encoding="utf-8"))' "$WT/$f" >/dev/null 2>&1 && JSONR="$JSONR$f：読める"$'\n' || JSONR="$JSONR$f：**読めない**（Claude Code は黙って読み飛ばす）"$'\n'
    else JSONR="$JSONR$f：見ていない（python が無い）。Claude Code を起動したときの警告で確かめる"$'\n'; fi ;;
  esac
done <<J
$REPLACED$ADDED$MERGED
J
TESTS=""
if [ -f "$WT/scripts/check-received.sh" ]; then
  if out=$(cd "$WT" && bash scripts/check-received.sh 2>&1); then TESTS="${TESTS}check-received.sh：通過"$'\n'; else TESTS="${TESTS}check-received.sh：**止まった**（$(printf '%s' "$out" | head -3 | tr '\n' ' ')）"$'\n'; fi
fi
for t in test-check-pii.sh test-check-control-chars.sh; do
  [ -f "$WT/scripts/$t" ] || continue
  last=$(cd "$WT" && bash "scripts/$t" 2>&1 | tail -1)
  TESTS="${TESTS}$t：$last"$'\n'
done
HEAD1=$(git rev-parse HEAD); ST1=$(git status --porcelain --untracked-files=no)
if [ "$HEAD0" = "$HEAD1" ] && [ "$ST0" = "$ST1" ]; then SAME="変わっていない（HEAD・追跡しているファイル）"; else SAME="**変わった**（HEAD $HEAD0 → $HEAD1。試しの途中で本体を触ったか、ほかの作業があった）"; fi
GITSET=""
for k in core.quotepath core.autocrlf core.filemode core.safecrlf; do GITSET="$GITSET$k=$(git config --get "$k" 2>/dev/null || echo 既定) "; done
RECV_COMMIT=$(git config --file "$TOP/.rei/received.cfg" template.commit 2>/dev/null || true)
RECORD=""
if [ "$MODE" = only ]; then
  TXT=$(bash "$PLANSH" --only "$ONLYV" "$SRC" "$TOP" 2>/dev/null </dev/null)
  HEADER=$(printf '%s\n' "$TXT" | sed -n '/^---- 版を選んで取り込む/,/^----$/p')
  # 「説明：コマンド」の行を、「# 説明」とコマンドの2行に（コマンドの行は、試しのフォルダでそのまま流せる）
  RECORD=$(printf '%s\n' "$TXT" | sed -n '/^---- 記録の書き方/,$p' | sed '1d; /^ *この一覧には/d; s/^ *//' | sed -E 's/^(.*)：(git config .*)$/# \1\n\2/; t; s/^/# /')
  NEWVER="選んで取り込んだ版 ${STEPSDONE% }"
else
  NEWVER=$(git config --file "$NEW/.rei/received.cfg" template.version 2>/dev/null || true)
  HEADER=$(bash "$PLANSH" "$OLD" "$NEW" "$TOP" 2>/dev/null </dev/null | sed -n '/^---- 間の版/,/^----$/p')
fi

# 6. 報告
mkdir -p "$TOP/.rei/reports"
RP=".rei/reports/upgrade-try-$(date +%Y%m%d-%H%M%S).md"
{
  echo "# 版上げの試しの報告（$(date +%Y-%m-%d\ %H:%M)）"
  echo
  echo "- この報告には手元のパスが入ることがあります。decisions/ などの記録に貼るときは、パスを消すか相対パスにしてください"
  echo "- 試しのフォルダ：../$NAME-rei-try（本体の隣。ブランチは作っていない＝detached）"
  echo "- 本体：ブランチ ${BR0:-（detached）}、HEAD ${HEAD0:0:12}。試しの前と後で $SAME"
  if [ "$MODE" = only ]; then echo "- 版を選んで取り込む（--only）：${STEPSDONE% }。受け取りの記録は当てていない（下の「記録の書き方」で書く）"
  else echo "- 新しい雛形の版：${NEWVER:-不明}。受け取りの記録の commit（今）：${RECV_COMMIT:-空}"; fi
  [ -n "${RECWROTE:-}" ] && echo "- $RECWROTE"
  echo "- git の設定：$GITSET（Windows では filemode=false だと実行権限の変更が差分に出ないことがある）"
  echo
  echo "## 影響の範囲（このプロジェクトで計算）"
  echo
  echo "| 入れ替え | 3方向 | ぶつかり | 足す | 消す | 見る | 確かめる | 残す | 受け取らない |"
  echo "|---|---|---|---|---|---|---|---|---|"
  echo "| $(cnt "$REPLACED") | $(cnt "$MERGED") | $(cnt "$CONFLICT") | $(cnt "$ADDED") | $(cnt "$REMOVED") | $(cnt "$LOOK") | $(cnt "$CHECK") | $(cnt "$KEEP") | $(cnt "$SKIP") |"
  echo
  # 言葉の意味（「入れ替えにプロジェクトの書き足しが無いか」が分かるように）
  echo "- 入れ替え：プロジェクトのファイルが古い雛形と同じもの（プロジェクトの書き足しは無い。確かめなくてよい）。足す：プロジェクトに無かったもの。3方向：両方が変えたもの"
  [ "$(git config --get core.autocrlf 2>/dev/null)" = true ] && echo "- 試しのフォルダの行末は CRLF（core.autocrlf=true）。手で直すとき、LF を前提にした置き換え（sed・スクリプト）は当たらないことがある。Edit で直すか、行末をそろえてから"
  echo
  [ -n "$HEADER" ] && { echo "## 間の版（CHANGELOG の各版を読む）"; echo; echo '```'; printf '%s\n' "$HEADER"; echo '```'; echo; }
  [ -n "$RECORD" ] && { echo "## 記録の書き方（試しのフォルダで、ファイルを直し終えたあと、いちばん最後に）"; echo; echo '```sh'; printf '%s\n' "$RECORD"; echo '```'; echo; }
  if [ -n "$CONFLICT" ]; then
    echo "## ぶつかったところ（試しのフォルダで <<<<<<< の印を直す。プロジェクトの書き足しを残す）"; echo; lines "$CONFLICT"; echo
    # 中身の抜粋（直し方を決める材料として）。1ファイル 40 行まで
    while IFS= read -r f; do
      [ -n "$f" ] && [ -f "$WT/$f" ] && grep -q '^<<<<<<< ' "$WT/$f" || continue
      echo "### $f"; echo; echo '```'
      tr -d '\r' < "$WT/$f" | awk '/^<<<<<<< /{on=1} on{print; n++} /^>>>>>>> /{on=0; print "…"} n>=40{exit}'
      echo '```'; echo
    done <<CF
$MARKS
CF
  fi
  if [ -n "$LOOK" ]; then
    echo "## 見る（プロジェクトのファイル。当てていない。雛形で変わったところを読み、要るところだけ手で足す）"; echo; lines "$LOOK"; echo
    if [ "$MODE" = full ]; then
      # 雛形で変わったところを見るコマンド（差分を見られるように）
      echo '```sh'
      while IFS= read -r f; do [ -n "$f" ] && echo "diff -u \"$OLD/$f\" \"$NEW/$f\""; done <<LK
$LOOK
LK
      echo '```'; echo
    fi
  fi
  [ -n "$CHECK" ] && { echo "## 確かめる（機械では決められない。人に聞く）"; echo; lines "$CHECK"; echo; }
  if [ -n "$XFILES" ]; then
    echo "## 実行権限（試しのフォルダで git add のあと、下の1行をそのまま流す）"; echo; lines "$XFILES"; echo
    echo '```sh'
    printf 'git update-index --chmod=+x --'; while IFS= read -r f; do [ -n "$f" ] && printf " '%s'" "$f"; done <<XF
$XFILES
XF
    echo; echo '```'; echo
  fi
  echo "## 確かめたこと"
  echo
  [ -n "$MARKS" ] && { echo "- ぶつかりの印が残っているファイル："; lines "$MARKS" | sed 's/^/  /'; } || echo "- ぶつかりの印：無し"
  [ -n "$SYNTAX" ] && { echo "- **構文の誤り**："; lines "$SYNTAX" | sed 's/^/  /'; } || echo "- bash の構文：誤り無し"
  [ -n "$JSONR" ] && lines "$JSONR"
  [ -n "$TESTS" ] && lines "$TESTS"
  [ -n "$ERR" ] && echo "- **当てられなかったファイル**：$ERR"
  echo
  echo "## 採る・捨てる（決めるのは人）"
  echo
  echo "採るとき（試しのフォルダで直してから）："
  echo
  # 手作業の版を、確かめる項目として並べる（「間の版」の手作業が当たるかを確かめられるように）
  MANUAL=$(printf '%s\n' "$HEADER" | awk '/^版 /{v=$2} /^ *手作業：/{sub(/^ *手作業：/,""); print "- [ ] 版 " v "：" $0 "（このプロジェクトに当たるかを確かめる。当たらなければ、何もしない）"}')
  if [ -n "$MANUAL" ]; then echo "手作業（間の版の CHANGELOG の「上げ方」も読む）："; echo; printf '%s\n' "$MANUAL"; echo; fi
  echo '```sh'
  echo "cd ../$NAME-rei-try"
  echo "#  1. ぶつかり・見る・確かめる・手作業を直す"
  echo "#  2. decisions/ に版上げを1つ書く（ファイル名を、次の decision に使う）"
  if [ "$MODE" = full ]; then
    echo "#  3. 受け取りの記録（version は書いてある）"
    echo "git config --file .rei/received.cfg template.applied $(date +%Y-%m-%d)"
    echo "git config --file .rei/received.cfg template.decision decisions/<番号>-<件名>.md"
    echo "git config --file .rei/received.cfg template.claude-code \"\$(claude --version | cut -d' ' -f1)\""
    # 新しい雛形が REI の clone でないとき（zip で取った雛形、別のリポジトリの中のフォルダ）は、commit を書けない
    NT=$(git -C "$NEW" rev-parse --show-toplevel 2>/dev/null || true)
    if [ -z "$NT" ] || ! [ "$NT" -ef "$NEW/.." ]; then
      echo "#     commit は空のまま（新しい雛形が REI の clone でない、zip で取った雛形、など）。REI を clone した写しから受け取ったなら：git config --file .rei/received.cfg template.commit \"\$(git -C <写し> rev-parse 'v${NEWVER}^{commit}')\""
    fi
  else
    echo "#  3. 受け取りの記録：上の「記録の書き方」のコマンド"
  fi
  echo "git add -A"
  [ -n "$XFILES" ] && echo "#  実行権限：上の「実行権限」の1行"
  if [ "$MODE" = only ]; then echo "git commit -m \"REI の雛形の版 ${STEPSDONE% } を取り込む\""
  else echo "git commit -m \"REI の雛形を ${NEWVER:-新しい版} に上げる\""; fi
  echo "C=\$(git rev-parse HEAD)"
  echo "cd ../$NAME"
  echo "git merge --ff-only \$C   # 本体が試しの前から動いていなければ、そのまま進む"
  echo "bash scripts/upgrade-try.sh --discard"
  echo '```'
  echo
  echo "捨てるとき：bash scripts/upgrade-try.sh --discard（消せないときは止まります。強制するかは人が決める）"
} > "$TOP/$RP"

echo "[upgrade-try] 試しました。入れ替え $(cnt "$REPLACED")・3方向 $(cnt "$MERGED")（ぶつかり $(cnt "$CONFLICT")）・足す $(cnt "$ADDED")・消す $(cnt "$REMOVED")・見る $(cnt "$LOOK")・確かめる $(cnt "$CHECK")"
echo "               本体は $SAME"
echo "               報告：$RP（試しのフォルダ：../$NAME-rei-try。入れるか捨てるかは人が決める）"
git check-ignore -q "$RP" 2>/dev/null || echo "               このプロジェクトの .gitignore に .rei/reports/ がまだありません（新しい雛形で入ります）。報告はコミットしないでください（手元のパスが入ることがあります）"
exit 0
