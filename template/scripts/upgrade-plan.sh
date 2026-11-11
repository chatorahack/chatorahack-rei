#!/bin/bash
# file: scripts/upgrade-plan.sh
# template: REI
# title: 版上げの一覧
# description: 雛形を新しい版に上げるとき、ファイルごとに何をするか（入れ替え・3方向・見る など）の一覧を出す
# caution: 何も書き換えない
#
# upgrade-plan.sh：雛形を新しい版に上げるとき、ファイルごとに何をすればよいかを出す。
# 見るだけで、ファイルは書き換えない。手順は docs/howto/upgrade.md。
#
# 使い方：bash scripts/upgrade-plan.sh <古い雛形の template> <新しい雛形の template> [<プロジェクト>]
#   <プロジェクト> を省くと、今いるフォルダ。
# 出す言葉：
#   入れ替え   … プロジェクトのファイルが古い雛形と同じ（手を加えていない）。新しい雛形のファイルで置き換えてよい
#   3方向      … プロジェクトで手を加えている。git merge-file で両方の変更を残す（下にコマンドを出す）
#   足す       … 新しい雛形で増えたファイル
#   消す       … 新しい雛形で無くなったファイルで、プロジェクトでも手を加えていない
#   見る       … プロジェクトが書いていくファイル（持ち主の表で project）が雛形で変わった。上書きしない。差分を読み、要るところだけ手で足す
#   確かめる   … 機械では決められない（新しい雛形で無くなったのに手を加えている、増えたのに同じ名前が既にある、など）
#   受け取らない … 受け取りの記録（.rei/received.cfg）の [skip "<パス>"] にあるファイル。数えない
#   済         … もう新しい雛形と同じ。数えない
# 持ち主の表は、新しい雛形の .rei/owners.cfg（v0.3.0-beta.25 から。無ければ、全部を雛形の持ち物として扱う）。
# 受け取りの記録の版が、もう新しい雛形の版と同じなら、何もせずに「済」と出す（2回流しても同じ結果。v0.3.0-beta.25）。
# 機械が読む形（v0.3.0-beta.29）：REI_PLAN_FORMAT=tsv で、1ファイル1行「言葉<TAB>ファイル<TAB>x（+x が要るとき）」だけを出す。
#   言葉：replace（入れ替え）・merge（3方向）・add（足す）・remove（消す）・look（見る）・check（確かめる）・keep（残す）・skip（受け取らない）・done（済）・uptodate（記録の版がもう新しい）
#   upgrade-try.sh などの道具がこれを読む。人が読む形の行の言葉や並びは変えてよいが、この形は変えない（変えるなら新しい言葉を足す）
# 実行権限（+x）が要るファイルには「（+x）」を付ける。git に入れるときは git update-index --chmod=+x。
#   Windows（Git for Windows）では、先頭が #! のファイルは権限に関わらず実行できると見えるので、「（+x）」が多めに付くことがある。
# 行末の CRLF と LF の違いは、中身の違いとして数えない。
# 雛形の版が同じファイル（古い雛形と新しい雛形で変わっていないもの）は出さない。
#
# 版を選んで取り込む（v0.3.0-beta.30）：
#   bash scripts/upgrade-plan.sh --only <版>[,<版>…] <REI の写し（clone したフォルダ）> [<プロジェクト>]
#   選んだ版の変更だけ（その版の雛形と、1つ前の版の雛形の差分）を、版の古い順に出す。
#   必須（changes.cfg の severity=required）は飛ばせない：記録の版より後で、選んだいちばん新しい版より前の、まだ取り込んでいない必須の版は、自動で足す。
#   受け取りの記録の版（template.version）は、途切れずに取り込み終わったところまでしか進めない。飛ばして先に取り込んだ版は [picked "<版>"] に書く。
#   版の雛形は、写しのタグ v<版> から git archive で、プロジェクトの git の管理フォルダの中（rei-versions/<版>/template）に取り出す（git に入らない。消してよい）。
#   2つ目からの版は、前の版を当てる前のプロジェクトで見ている。当てるのは upgrade-try.sh --only がおすすめ（版ごとに当ててから次を見る）。
#   機械が読む形（REI_PLAN_FORMAT=tsv）では、版ごとに1行「step<TAB><版><TAB><前の版>」だけを出す（取り込むものが無ければ uptodate）。
#   受け取りの記録そのもの（.rei/received.cfg）は、版ごとの差分では当てない（版の行がぶつかるため）。最後に出す「記録の書き方」で書く。
set -u
export LC_ALL=C.UTF-8
cfg() { git config --file "$1" "${@:2}" 2>/dev/null; }
ver_gt() { # $1 が $2 より新しいか（session-start.sh と同じ比べ方）
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
vsort() { # 版を古い順に並べる（x.y.z、alpha・beta・rc・正式版の順。版の形は CHANGELOG の冒頭で固定している）
  local v t n
  while IFS= read -r v; do
    [ -n "$v" ] || continue
    t=9; n=0
    case "$v" in *-alpha.*) t=1; n="${v##*.}" ;; *-beta.*) t=2; n="${v##*.}" ;; *-rc.*) t=3; n="${v##*.}" ;; esac
    printf '%s.%s.%s\t%s\n' "${v%%-*}" "$t" "$n" "$v"
  done | sort -t. -k1,1n -k2,2n -k3,3n -k4,4n -k5,5n | cut -f2
}

if [ "${1:-}" = --only ]; then
  WANT=$(printf '%s' "${2:-}" | tr ',' ' '); SRC="${3:-}"; PROJ="${4:-.}"
  [ -n "$WANT" ] && [ -n "$SRC" ] && [ -d "$SRC" ] && [ -d "$PROJ" ] || { echo "使い方：bash scripts/upgrade-plan.sh --only <版>[,<版>…] <REI の写し（clone したフォルダ）> [<プロジェクト>]" >&2; exit 2; }
  CHG="$SRC/changes.cfg"; REC="$PROJ/.rei/received.cfg"
  git -C "$SRC" rev-parse --git-dir >/dev/null 2>&1 && [ -f "$CHG" ] || { echo "[upgrade-plan] REI の写しには、REI を clone したフォルダ（changes.cfg とタグ v<版> があるもの）を渡す" >&2; exit 2; }
  CUR=$(cfg "$REC" template.version || true)
  [ -n "$CUR" ] || { echo "[upgrade-plan] このプロジェクトの受け取りの記録（.rei/received.cfg）の版が読めません。--only は記録の版から先を選びます（記録の無い雛形は、まずふつうの上げ方で上げる）" >&2; exit 2; }
  CACHE=$(git -C "$PROJ" rev-parse --path-format=absolute --git-path rei-versions 2>/dev/null || true)
  [ -n "$CACHE" ] || { echo "[upgrade-plan] --only は git のリポジトリのプロジェクトで使う（版の雛形を git の管理フォルダの中に取り出す）" >&2; exit 2; }
  ALLV=$(cfg "$CHG" --get-regexp '^change\..*\.severity$' | sed 's/^change\.\(.*\)\.severity .*/\1/' | vsort | awk '!s[$0]++')
  isin() { printf '%s\n' "$2" | grep -qxF -- "$1"; }
  picked() { cfg "$REC" --get "picked.$1.applied" >/dev/null; }
  REQ=""; NOTE=""
  for v in $WANT; do
    isin "$v" "$ALLV" || { echo "[upgrade-plan] 版 $v は REI の変更の索引（写しの changes.cfg）にありません。版の形（0.3.0-beta.30 など）と、写しが新しいか（git -C <写し> pull）を確かめる" >&2; exit 2; }
    ver_gt "$v" "$CUR" || { echo "[upgrade-plan] 版 $v は、もう受け取っています（このプロジェクトの記録の版は $CUR）" >&2; exit 2; }
    if picked "$v"; then NOTE="$NOTE版 $v は前に取り込みました（[picked]）。"; continue; fi
    REQ="$REQ$v"$'\n'
  done
  MAXREQ=$(printf '%s' "$REQ" | vsort | tail -1)
  # 記録の版より後の版を古い順に見て、取り込むもの（指定・必須）を決める。前の版（差分の元）は索引の1つ前
  ROWS=""; STEPS=""; PREV=""; NEWCUR="$CUR"; RUN=1; TAB=$(printf '\t')
  while IFS= read -r v; do
    [ -n "$v" ] || continue
    if ver_gt "$v" "$CUR"; then
      s=$(cfg "$CHG" --get "change.$v.severity" || true)
      if picked "$v"; then st=done
      elif [ -n "$REQ" ] && isin "$v" "$REQ"; then st=want
      elif [ -n "$MAXREQ" ] && [ "$s" = required ] && ver_gt "$MAXREQ" "$v"; then st=need
      else st=leave
      fi
      ROWS="$ROWS$v$TAB$s$TAB$st"$'\n'
      if [ "$st" = want ] || [ "$st" = need ]; then
        [ -n "$PREV" ] || { echo "[upgrade-plan] 版 $v の1つ前の版が、索引（changes.cfg）にありません" >&2; exit 2; }
        STEPS="$STEPS$v$TAB$PREV"$'\n'
      fi
      # 途切れずに取り込み終わるところまで、記録の版を進める
      if [ "$RUN" = 1 ] && [ "$st" != leave ]; then NEWCUR="$v"; else RUN=0; fi
    fi
    PREV="$v"
  done <<VERS
$ALLV
VERS
  if [ -z "$STEPS" ]; then
    [ "${REI_PLAN_FORMAT:-text}" = tsv ] && { printf 'uptodate\t.rei/received.cfg\t\n'; exit 0; }
    echo "済        取り込む版はありません。$NOTE"; echo "---- 何かすることがあるファイル：0"; exit 0
  fi
  # 版の雛形を取り出す（写しのタグ v<版>。取り出したものは、タグのコミットが同じなら使い回す）
  tpl_of() {
    local v="$1" d="$CACHE/$1" c
    c=$(git -C "$SRC" rev-parse -q --verify "refs/tags/v$v^{commit}" 2>/dev/null) || { echo "[upgrade-plan] 写しにタグ v$v がありません（版 $v の雛形を取り出せない）。写しを新しくする：git -C <写し> fetch --tags" >&2; return 1; }
    if [ ! -f "$d/.commit" ] || [ "$(cat "$d/.commit")" != "$c" ] || [ ! -d "$d/template" ]; then
      rm -rf "${CACHE:?}/$1"; mkdir -p "$d" || return 1
      git -C "$SRC" archive --format=tar "$c" template | tar -x -C "$d" || { echo "[upgrade-plan] 版 $v の雛形を取り出せませんでした" >&2; return 1; }
      printf '%s\n' "$c" > "$d/.commit"
    fi
  }
  while IFS="$TAB" read -r v p; do
    [ -n "$v" ] || continue
    tpl_of "$v" || exit 2; tpl_of "$p" || exit 2
  done <<S1
$STEPS
S1
  if [ "${REI_PLAN_FORMAT:-text}" = tsv ]; then
    printf '%s' "$STEPS" | while IFS="$TAB" read -r v p; do [ -n "$v" ] && printf 'step\t%s\t%s\n' "$v" "$p"; done
    exit 0
  fi
  echo "---- 版を選んで取り込む（--only。このプロジェクトの記録の版 $CUR より後。CHANGELOG の各版を読む）"
  printf '%s' "$ROWS" | while IFS="$TAB" read -r v s st; do
    [ -n "$v" ] || continue
    case "$s" in required) j="必須" ;; recommended) j="推奨" ;; optional) j="任意" ;; *) j="$s" ;; esac
    case "$st" in want) k="取り込む（選んだ）" ;; need) k="取り込む（必須は飛ばせないので足した）" ;; done) k="済（前に取り込んだ）" ;; *) k="取り込まない" ;; esac
    echo "版 $v  $j  $(cfg "$CHG" --get "change.$v.feature" || true)  … $k"
    m=$(cfg "$CHG" --get "change.$v.manual" || true); [ -n "$m" ] && [ "$st" != leave ] && [ "$st" != done ] && echo "          手作業：$m"
  done
  [ -n "$NOTE" ] && echo "$NOTE"
  echo "----"
  printf '%s' "$STEPS" | while IFS="$TAB" read -r v p; do
    [ -n "$v" ] || continue
    echo "==== 版 $v（版 $p の雛形からの差分）"
    REI_PLAN_PART=1 REI_PLAN_ONLY=1 bash "${BASH_SOURCE[0]}" "$CACHE/$p/template" "$CACHE/$v/template" "$PROJ"
  done
  echo "---- 記録の書き方（ファイルを全部当てて確かめたあと、いちばん最後に）"
  if [ "$NEWCUR" != "$CUR" ]; then
    echo "     記録の版を $NEWCUR にする（$CUR の後から $NEWCUR まで、途切れずに取り込んだ）：git config --file .rei/received.cfg template.version $NEWCUR"
    c=$(git -C "$SRC" rev-parse -q --verify "refs/tags/v$NEWCUR^{commit}" 2>/dev/null || true)
    [ -n "$c" ] && echo "     受け取ったコミットも書く：git config --file .rei/received.cfg template.commit $c"
  else
    echo "     記録の版は $CUR のまま（間に取り込まない版があるので進めない。進めると、取り込んでいない版が知らせにも一覧にも出なくなる）"
  fi
  TODAY=$(date +%Y-%m-%d)
  printf '%s' "$STEPS" | while IFS="$TAB" read -r v p; do
    [ -n "$v" ] && ver_gt "$v" "$NEWCUR" && echo "     先に取り込んだ版の印：git config --file .rei/received.cfg picked.$v.applied $TODAY"
  done
  cfg "$REC" --get-regexp '^picked\..*\.applied$' | sed 's/^picked\.\(.*\)\.applied .*/\1/' | while IFS= read -r v; do
    [ -n "$v" ] && ! ver_gt "$v" "$NEWCUR" && echo "     記録の版に含まれた印を消す：git config --file .rei/received.cfg --remove-section picked.$v"
  done
  echo "     この一覧には手元のパスが入っています。decisions/ などの記録に貼るときは、パスを消すか相対パスにする（アカウント名が入ることがある）"
  exit 0
fi

OLD="${1:-}"; NEW="${2:-}"; PROJ="${3:-.}"
for d in "$OLD" "$NEW" "$PROJ"; do
  [ -n "$d" ] && [ -d "$d" ] || { echo "使い方：bash scripts/upgrade-plan.sh <古い雛形の template> <新しい雛形の template> [<プロジェクト>]" >&2; exit 2; }
done
# 中身が同じか。行末の CR の違い（CRLF と LF）は同じと見る（Windows で取り出したプロジェクトと zip で取った雛形を、
# 中身が同じなら同じと見るため）
same() { cmp -s "$1" "$2" && return 0; cmp -s <(tr -d '\r' < "$1") <(tr -d '\r' < "$2"); }
list() { (cd "$1" && find . -type f ! -path './.git/*' ! -name 'hook-executed.log' ! -name 'guard-status' ! -name 'stop-requested' ! -name 'rei-state' -print | sed 's#^\./##'); }

# 2回目は「済」（受け取りの記録の版が、新しい雛形の版と同じ）。--only の版ごとの一覧（REI_PLAN_PART=1）では見ない
NEWVER=$(cfg "$NEW/.rei/received.cfg" template.version || true)
PROJVER=$(cfg "$PROJ/.rei/received.cfg" template.version || true)
if [ -z "${REI_PLAN_PART:-}" ] && [ -n "$NEWVER" ] && [ "$PROJVER" = "$NEWVER" ]; then
  [ "${REI_PLAN_FORMAT:-text}" = tsv ] && { printf 'uptodate\t.rei/received.cfg\t\n'; exit 0; }
  echo "済        このプロジェクトの受け取りの記録（.rei/received.cfg）は、もう $NEWVER です。することはありません"
  echo "---- 何かすることがあるファイル：0"
  exit 0
fi

# 間の版の重さと手作業（新しい雛形の隣の changes.cfg。v0.3.0-beta.28）。必須の版は飛ばさない
OLDVER="${PROJVER:-$(cfg "$OLD/.rei/received.cfg" template.version || true)}"
# 古い雛形には受け取りの記録が無いことがある。版は session-start.sh の rei= の行にある（「間の版」が黙って抜けないように）
VER_ERE='[0-9]+\.[0-9]+\.[0-9]+(-(alpha|beta|rc)\.[0-9]+)?'
[ -n "$OLDVER" ] || OLDVER=$(grep -oE "rei=$VER_ERE" "$PROJ/.claude/hooks/session-start.sh" 2>/dev/null | head -1 | cut -d= -f2)
[ -n "$OLDVER" ] || OLDVER=$(grep -oE "rei=$VER_ERE" "$OLD/.claude/hooks/session-start.sh" 2>/dev/null | head -1 | cut -d= -f2)
CHG="$NEW/../changes.cfg"
if [ -z "${REI_PLAN_PART:-}" ] && [ "${REI_PLAN_FORMAT:-text}" != tsv ]; then
  # 間の版を出せないときは、黙らずに1行出す（v0.3.0-beta.32）
  if [ -z "$OLDVER" ]; then echo "---- 間の版：古い雛形の版が分からないので出せない（受け取りの記録も rei= の行も無い）。REI の CHANGELOG を古い版から読む"
  elif [ ! -f "$CHG" ]; then echo "---- 間の版：新しい雛形の隣に changes.cfg が無いので出せない（必須・手作業が分からない）。REI のタグ全体を取り出す（docs/howto/upgrade.md「用意するもの」）"
  fi
fi
if [ -z "${REI_PLAN_PART:-}" ] && [ "${REI_PLAN_FORMAT:-text}" != tsv ] && [ -n "$OLDVER" ] && [ -n "$NEWVER" ] && [ -f "$CHG" ]; then
  echo "---- 間の版（$OLDVER より後、$NEWVER まで。CHANGELOG の各版を読む）"
  cfg "$CHG" --get-regexp '^change\..*\.severity$' | while IFS= read -r line; do
    k="${line%% *}"; s="${line#* }"; v="${k#change.}"; v="${v%.severity}"
    ver_gt "$v" "$OLDVER" || continue
    ver_gt "$v" "$NEWVER" && continue
    printf '%s\t%s\n' "$v" "$s"
  done | sort -t "$(printf '\t')" -k1,1V | while IFS="$(printf '\t')" read -r v s; do
    case "$s" in required) j="必須" ;; recommended) j="推奨" ;; optional) j="任意" ;; *) j="$s" ;; esac
    pk=""; cfg "$PROJ/.rei/received.cfg" --get "picked.$v.applied" >/dev/null && pk="  … 済（前に --only で取り込んだ）"
    echo "版 $v  $j  $(cfg "$CHG" --get "change.$v.feature" || true)$pk"
    r=$(cfg "$CHG" --get "change.$v.reason" || true); [ -n "$r" ] && echo "          必須の理由：$r"
    m=$(cfg "$CHG" --get "change.$v.manual" || true); [ -n "$m" ] && echo "          手作業：$m"
  done
  echo "----"
fi

# 持ち主の表（新しい雛形の）と、受け取らないファイル（プロジェクトの記録の）
PROJECT_PATS=$(cfg "$NEW/.rei/owners.cfg" --get-all owner.project.path || true)
SHARED_PATS=$(cfg "$NEW/.rei/owners.cfg" --get-all owner.shared.path || true)
owner() { # $1 のファイルの持ち主：project・shared・template
  local p
  while IFS= read -r p; do [ -n "$p" ] || continue; case "$1" in $p) echo project; return ;; esac; done <<P1
$PROJECT_PATS
P1
  while IFS= read -r p; do [ -n "$p" ] || continue; case "$1" in $p) echo shared; return ;; esac; done <<P2
$SHARED_PATS
P2
  echo template
}
skipped() { # 受け取らない（[skip "<パス>"] に reason がある）なら理由を出して 0
  [ -f "$PROJ/.rei/received.cfg" ] || return 1
  local r
  r=$(cfg "$PROJ/.rei/received.cfg" --get "skip.$1.reason") || return 1
  printf '%s' "${r:-理由なし}"
}
note() { case "$1" in *.json) echo "          （JSON。当てたあと、書式が崩れていないか確かめる。崩れると Claude Code は黙ってそのファイルを読み飛ばす）" ;; esac; }

ALL=$( { list "$OLD"; list "$NEW"; } | sort -u)
# 1つのファイルの結果を出す。人が読む形（既定）と、機械が読む形（REI_PLAN_FORMAT=tsv：「言葉<TAB>ファイル<TAB>+x」。v0.3.0-beta.29）
r() { # $1＝機械の言葉、$2＝人が読む行
  if [ "${REI_PLAN_FORMAT:-text}" = tsv ]; then printf '%s\t%s\t%s\n' "$1" "$f" "${x:+x}"; else echo "$2"; fi
}
n=0
while IFS= read -r f; do
  [ -z "$f" ] && continue
  o="$OLD/$f"; w="$NEW/$f"; p="$PROJ/$f"
  [ -f "$o" ] && [ -f "$w" ] && same "$o" "$w" && continue
  [ -f "$o" ] || [ -f "$w" ] || continue
  x=""
  # 受け取りの記録は当てない（v0.3.0-beta.32。3方向にすると、雛形の version とプロジェクトの commit が隣の行でぶつかる）。
  # プロジェクトに記録があれば残し、最後に版（とコミット）だけを書く。記録の無いプロジェクト（beta.23 まで）には「足す」
  if [ "$f" = .rei/received.cfg ] && [ -f "$p" ]; then
    if [ -n "${REI_PLAN_ONLY:-}" ]; then r keep "残す      $f（受け取りの記録。--only では当てず、最後の「記録の書き方」で書く）"
    else r keep "残す      $f（受け取りの記録。当てずに、最後に版を書く：下の「終わったら」）"; n=$((n+1)); fi
    continue
  fi
  if why=$(skipped "$f"); then r skip "受け取らない $f（$why）"; continue; fi
  [ -f "$w" ] && [ -x "$w" ] && x="（+x）"
  who=$(owner "$f")
  if [ -f "$p" ] && [ -f "$w" ] && same "$p" "$w"; then r done "済        $f"; continue; fi
  if [ "$who" = project ] && [ -f "$p" ]; then
    if [ -f "$w" ]; then
      r look "見る      $f（プロジェクトのファイル。雛形で変わったところ：diff \"$o\" \"$w\"）"
      n=$((n+1))
    else
      r keep "残す      $f（雛形から無くなったが、プロジェクトのファイルなので残す）"
    fi
    continue
  fi
  if [ -f "$o" ] && [ -f "$w" ]; then
    if [ ! -f "$p" ]; then r check "確かめる  $f（新しい雛形で変わったが、プロジェクトに無い。消したのなら足さない。足さないと決めたら、受け取りの記録に [skip] を書く）"
    elif same "$p" "$o"; then r replace "入れ替え  $f$x"
    else r merge "3方向     $f$x"; [ "${REI_PLAN_FORMAT:-text}" = tsv ] || { echo "          git merge-file -L プロジェクト -L 古い雛形 -L 新しい雛形 \"$p\" \"$o\" \"$w\""; note "$f"; }
    fi
  elif [ -f "$w" ]; then
    if [ ! -f "$p" ]; then r add "足す      $f$x"
    else r check "確かめる  $f（新しい雛形で増えたが、同じ名前のファイルが既にある）"
    fi
  else
    [ -f "$p" ] || continue
    if same "$p" "$o"; then r remove "消す      $f（新しい雛形で無くなった。名前が変わっただけのことがある）"
    else r check "確かめる  $f（新しい雛形で無くなったが、プロジェクトで手を加えている）"
    fi
  fi
  n=$((n+1))
done <<EOF
$ALL
EOF
[ "${REI_PLAN_FORMAT:-text}" = tsv ] && exit 0
echo "---- 何かすることがあるファイル：$n"
[ -n "${REI_PLAN_PART:-}" ] && exit 0
# 前に --only で先に取り込んだ版の印（[picked]）は、記録の版に含まれたら消す（v0.3.0-beta.30）
cfg "$PROJ/.rei/received.cfg" --get-regexp '^picked\..*\.applied$' | sed 's/^picked\.\(.*\)\.applied .*/\1/' | while IFS= read -r v; do
  [ -n "$v" ] && [ -n "$NEWVER" ] && ! ver_gt "$v" "$NEWVER" && echo "     先に取り込んだ版の印も消す：git config --file .rei/received.cfg --remove-section picked.$v"
done
[ -n "$NEWVER" ] && echo "     終わったら、受け取りの記録の版を $NEWVER にする（いちばん最後に。先に変えると、この一覧が「済」と出る）：git config --file .rei/received.cfg template.version $NEWVER"
# 受け取ったコミット（新しい雛形が REI の clone の中なら、値まで出す。v0.3.0-beta.28）
NEWCOMMIT=""
TOP=$(git -C "$NEW" rev-parse --show-toplevel 2>/dev/null || true)
# 新しい雛形の1つ上が、その git のいちばん上（＝REI を clone したフォルダ）のときだけ（ほかのリポジトリの中に置いた雛形のコミットは出さない）
[ -n "$TOP" ] && [ "$TOP" -ef "$NEW/.." ] && NEWCOMMIT=$(git -C "$NEW" rev-parse HEAD 2>/dev/null || true)
if [ -n "$NEWCOMMIT" ]; then
  echo "     受け取ったコミットも書く：git config --file .rei/received.cfg template.commit $NEWCOMMIT"
else
  echo "     受け取ったコミットも書く：git config --file .rei/received.cfg template.commit \"\$(git -C <REI の写し> rev-parse 'v$NEWVER^{commit}')\""
fi
echo "     この一覧には手元のパスが入っています。decisions/ などの記録に貼るときは、パスを消すか相対パスにする（アカウント名が入ることがある）"
exit 0
