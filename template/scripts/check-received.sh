#!/bin/bash
# file: scripts/check-received.sh
# template: REI
# title: 受け取りの記録の点検
# description: 受け取りの記録（.rei/received.cfg）の書式と、手元のパスが git に入っていないかを確かめる
#
# check-received.sh（v0.3.0-beta.28）：受け取りの記録（.rei/received.cfg）の書式と、手元のパスの混入を見る。
# コミットの前（.githooks/pre-commit）から呼ぶ。違っていたら場所を出して 1 で終わる。記録が無ければ（古い雛形）何もしない。
#   1. 記録が git の設定ファイルとして読めるか（1行でも崩れると、起動のときの知らせが全部止まる）
#   2. rei.format が 1 か（知らない書式の版なら、この雛形の点検では見られない）
#   3. template.version が1つだけで、版の形（x.y.z か x.y.z-alpha.N・-beta.N・-rc.N）か
#   4. template.commit が空か、16進の7〜40文字か。template.applied が空か、YYYY-MM-DD か
#   5. [template] の同じ項目が2回書かれていないか（git は最後の値を黙って使う。3方向の当てで残りやすい）
#   6. 機械ごとの設定 .rei/local.cfg を git に入れていないか（手元のパスが入る）
#   7. AGENTS.md に、アカウント名を含みうるパス（…\Users\…、/Users/…、/home/…）が無いか（git に入るので履歴に残る）
#   8. 先に取り込んだ版の印（[picked "<版>"]、upgrade-plan.sh --only。v0.3.0-beta.30）が、版の形で、記録の版より新しく、applied が YYYY-MM-DD か
#      （記録の版より新しくない印は、もう記録の版に含まれている。残しておくと、取り込んでいない版を「済」と見てしまうことがある）
# 使い方：bash scripts/check-received.sh   （リポジトリのどこからでも）
# 限界：意味（その版を本当に当てたか）は見ない。
set -u
export LC_ALL=C.UTF-8
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" || exit 2
NG=0
ng() { echo "[check-received] NG $1" >&2; NG=1; }
REC=.rei/received.cfg
VER_RE='^[0-9]+\.[0-9]+\.[0-9]+(-(alpha|beta|rc)\.[0-9]+)?$'
ver_gt() { # $1 が $2 より新しいか（session-start.sh・upgrade-plan.sh と同じ比べ方）
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

if [ -f "$REC" ]; then
  if ! git config --file "$REC" --list >/dev/null 2>&1; then
    ng "$REC が git の設定ファイルとして読めない（どの行かは：git config --file $REC --list）。項目の名前は英数字と - だけ"
  else
    f=$(git config --file "$REC" --get rei.format 2>/dev/null || true)
    [ "$f" = "1" ] || ng "$REC の rei.format が '${f:-無し}'（この点検が知っているのは 1）"
    n=$(git config --file "$REC" --get-all template.version 2>/dev/null | wc -l | tr -d ' ')
    v=$(git config --file "$REC" --get template.version 2>/dev/null || true)
    [ "$n" = "1" ] || ng "$REC の template.version が ${n} 行ある（1行だけにする）"
    printf '%s' "$v" | grep -qE "$VER_RE" || ng "$REC の template.version '${v:-無し}' が版の形でない（x.y.z か x.y.z-beta.N など）"
    c=$(git config --file "$REC" --get template.commit 2>/dev/null || true)
    [ -z "$c" ] || printf '%s' "$c" | grep -qE '^[0-9a-f]{7,40}$' || ng "$REC の template.commit '$c' がコミットの形でない（16進の7〜40文字）"
    a=$(git config --file "$REC" --get template.applied 2>/dev/null || true)
    [ -z "$a" ] || printf '%s' "$a" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' || ng "$REC の template.applied '$a' が日付の形でない（YYYY-MM-DD）"
    dup=$(git config --file "$REC" --list 2>/dev/null | sed -n 's/^\(template\.[^=]*\)=.*/\1/p' | sort | uniq -d | tr '\n' ' ')
    [ -z "$dup" ] || ng "$REC の [template] に同じ項目が2回ある：$dup（git は最後の値を使う。1つにする）"
    PV=$(git config --file "$REC" --get-regexp '^picked\.' 2>/dev/null | sed 's/^picked\.\(.*\)\.[a-z-]* .*$/\1/; s/^picked\.\(.*\)\.[a-z-]*$/\1/' | sort -u)
    while IFS= read -r pv; do
      [ -n "$pv" ] || continue
      if ! printf '%s' "$pv" | grep -qE "$VER_RE"; then ng "$REC の [picked \"$pv\"] が版の形でない"; continue; fi
      pa=$(git config --file "$REC" --get "picked.$pv.applied" 2>/dev/null || true)
      printf '%s' "$pa" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' || ng "$REC の [picked \"$pv\"] の applied '${pa:-無し}' が日付の形でない（YYYY-MM-DD）"
      if [ -n "$v" ] && ! ver_gt "$pv" "$v"; then
        ng "$REC の [picked \"$pv\"] は、記録の版 $v にもう含まれている（印を消す：git config --file $REC --remove-section picked.$pv）"
      fi
    done <<PICKED
$PV
PICKED
  fi
fi

if git ls-files --error-unmatch .rei/local.cfg >/dev/null 2>&1; then
  ng ".rei/local.cfg が git に入っている（機械ごとの設定で、手元のパスが入る。git rm --cached .rei/local.cfg）"
fi

if [ -f AGENTS.md ]; then
  hit=$(grep -nE '[A-Za-z]:[\\/]+Users[\\/]|/Users/|/home/' AGENTS.md 2>/dev/null | cut -d: -f1 | tr '\n' ' ')
  [ -z "$hit" ] || ng "AGENTS.md の ${hit}行目に、アカウント名を含みうるパスがある（git に入るので履歴に残る。手元の写しは .rei/local.cfg に）"
fi

exit $NG
