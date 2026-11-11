#!/bin/bash
# file: scripts/test-check-pii.sh
# template: REI
# title: 個人情報の点検の試験
# description: check-pii.sh が期待どおりに止める・通すかを、ダミーの語で確かめる
#
# check-pii.sh の検証（ダミーの語のみ使用。実行: bash scripts/test-check-pii.sh）。直接実行（ロケール無し）とpre-commit経由の両方で期待どおりかを見る
set -u
unset PII_PATTERNS_EXTRA   # 利用者の環境の設定でテストの結果が変わらないようにする（E系で明示的に指定する）
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"   # このリポジトリのルート
W=$(mktemp -d) || { echo "一時フォルダを作れない" >&2; exit 1; }; trap 'cd /; rm -rf "$W"' EXIT; mkdir -p "$W/home/.config/rei"
P="$W/pats"; mkdir -p "$P"
printf 'dummyname\n' > "$P/hit.txt"
: > "$P/empty.txt"
printf 'dummyname\n\n' > "$P/blank.txt"
printf '# comment line\ndummyname\n' > "$P/comment.txt"
printf 'dummyname\r\n' > "$P/crlf.txt"
mkdir -p "$P/isdir.txt"
printf '# 実名\ndummyname==>{{PERSON}}\n==>{{EMPTY_TEST}}\n' > "$P/arrow.txt"
printf '# only replacement side\nzzz==>dummyname\n' > "$P/rightonly.txt"
pass=0; failn=0
check() { # 名前 期待(0/1) 実際
  if [ "$2" = "$3" ]; then echo "OK   $1 (exit=$3)"; pass=$((pass+1)); else echo "NG   $1 期待=$2 実際=$3"; failn=$((failn+1)); fi
}
newrepo() {
  R="$W/repo-$1"; rm -rf "$R"; mkdir -p "$R/scripts" "$R/.githooks"
  cd "$R" && git init -q && git config user.name t && git config user.email t@example.invalid
  cp "$SRC/scripts/check-pii.sh" scripts/ && cp "$SRC/.githooks/pre-commit" .githooks/ && git config core.hooksPath .githooks
  echo base > a.md && git add -A && git commit -qm base --no-verify
}
direct() { env -u LC_ALL -u LC_CTYPE -u LANG PII_PATTERNS="$1" bash scripts/check-pii.sh >/dev/null 2>&1; echo $?; }

newrepo d
echo "dummyname here" >> a.md; git add a.md
check "D1 直接・ロケール無し・該当あり" 1 "$(direct "$P/hit.txt")"
check "D2 直接・空の表" 0 "$(direct "$P/empty.txt")"
check "D3 直接・末尾に空行（該当あり）" 1 "$(direct "$P/blank.txt")"
check "D4 直接・#の行があっても該当を止める" 1 "$(direct "$P/comment.txt")"
check "D5 直接・CRLFの表" 1 "$(direct "$P/crlf.txt")"
check "D6 直接・表がフォルダ（読めない）→止める" 1 "$(direct "$P/isdir.txt")"
check "D7 直接・表が無い→注意だけ" 0 "$(direct "$P/none.txt")"
git reset -q; git checkout -q -- a.md
echo "unrelated line" > u.md; git add u.md
check "D8 直接・末尾に空行でも無関係な行は通す" 0 "$(direct "$P/blank.txt")"
check "D9 直接・#の行が無関係な行に当たらない" 0 "$(git reset -q; echo '# comment line is documented' > c2.md; git add c2.md; direct "$P/comment.txt")"
git reset -q; rm -f c2.md
echo "dummyname" > "日本語 (1).md"; git add "日本語 (1).md"
check "D10 直接・日本語とスペースのファイル名" 1 "$(direct "$P/hit.txt")"
git reset -q; rm -f "日本語 (1).md"
printf 'keep\ndummyname old\n' > k.md; git add k.md; git commit -qm k --no-verify; printf 'keep\n' > k.md; git add k.md
check "D11 直接・削除だけ" 0 "$(direct "$P/hit.txt")"
git commit -qm k2 --no-verify
echo "dummyname" > h.md; git add h.md
check "D12 直接・HOME無し（表の指定も無し）→注意だけ" 0 "$(env -u HOME -u PII_PATTERNS -u LC_ALL bash scripts/check-pii.sh >/dev/null 2>&1; echo $?)"
cp "$P/hit.txt" "$W/home/.config/rei/pii_patterns.txt"
check "D13 直接・既定の場所（ダミーのHOME）で該当" 1 "$(env -u PII_PATTERNS -u LC_ALL -u LC_CTYPE -u LANG HOME="$W/home" bash scripts/check-pii.sh >/dev/null 2>&1; echo $?)"
git reset -q; rm -f h.md

newrepo f
printf 'line1\ndummyname line2\nline3\nDUMMYNAME line4\n' > m.md; git add m.md
check "F1 ==>の形：左側で検出" 1 "$(direct "$P/arrow.txt")"
check "F2 ==>の右側だけにある語では止めない" 0 "$(direct "$P/rightonly.txt")"
out=$(env -u LC_ALL -u LC_CTYPE -u LANG PII_PATTERNS="$P/arrow.txt" bash scripts/check-pii.sh 2>&1 >/dev/null)
check "F3 行番号の表示（m.mdの2・4行目）" 1 "$(printf '%s' "$out" | grep -c 'm.md（2, 4行目）')"
check "F4 値・行の中身を表示しない" 0 "$(printf '%s' "$out" | grep -a -i -c 'dummyname')"
git commit -qm m --no-verify
printf 'line1\nline2\nnew dummyname\nline3\n' > m2.md; git add m2.md; git commit -qm m2 --no-verify
sed -i 's/^line2$/line2 edited dummyname/' m2.md; git add m2.md
out=$(env -u LC_ALL PII_PATTERNS="$P/hit.txt" bash scripts/check-pii.sh 2>&1 >/dev/null)
check "F5 既存ファイルの途中の変更行の行番号（m2.mdの2行目のみ）" 1 "$(printf '%s' "$out" | grep -c 'm2.md（2行目）')"
git reset -q; git checkout -q -- m2.md
echo "dummyname" > "日本語 (2).md"; git add "日本語 (2).md"
out=$(env -u LC_ALL PII_PATTERNS="$P/hit.txt" bash scripts/check-pii.sh 2>&1 >/dev/null)
check "F6 日本語とスペースのファイル名が表示に出る" 1 "$(printf '%s' "$out" | grep -c '日本語 (2).md（1行目）')"
git reset -q; rm -f "日本語 (2).md"

newrepo e   # 追加の表（PII_PATTERNS_EXTRA）
printf 'otherco==>{{ORGANIZATION}}\n' > "$P/extra.txt"
printf 'otherco2\n' > "$P/extra2.txt"
extra() { env -u LC_ALL PII_PATTERNS="$1" PII_PATTERNS_EXTRA="$2" bash scripts/check-pii.sh >/dev/null 2>&1; echo $?; }
echo "OtherCo is here" > e.md; git add e.md
check "E1 追加の表の語で止める（本体の表は該当なし）" 1 "$(extra "$P/hit.txt" "$P/extra.txt")"
check "E2 本体の表が無くても追加の表で止める" 1 "$(extra "$P/none.txt" "$P/extra.txt")"
check "E3 追加の表が無いときは本体の表だけで判定（該当なし→通す）" 0 "$(extra "$P/hit.txt" "$P/none2.txt")"
check "E4 追加の表が読めない（フォルダ）→止める" 1 "$(extra "$P/hit.txt" "$P/isdir.txt")"
git reset -q; rm -f e.md; echo "otherco2 here" > e2.md; git add e2.md
check "E5 ;区切りの2つ目の表で止める" 1 "$(extra "$P/hit.txt" "$P/extra.txt;$P/extra2.txt")"
check "E6 Windows形式のパスでも読める" 1 "$(extra "$P/hit.txt" "$(cygpath -w "$P/extra2.txt" 2>/dev/null || echo "$P/extra2.txt")")"
git reset -q; rm -f e2.md

newrepo h
echo "dummyname here" >> a.md; git add a.md
check "H1 pre-commit経由・該当あり" 1 "$(PII_PATTERNS="$P/hit.txt" git commit -qm h1 >/dev/null 2>&1; echo $?)"
git checkout -q HEAD -- a.md; echo "fine" >> a.md; git add a.md
check "H2 pre-commit経由・該当なし" 0 "$(PII_PATTERNS="$P/hit.txt" git commit -qm h2 >/dev/null 2>&1; echo $?)"
echo "fine2" >> a.md; git add a.md
check "H3 pre-commit経由・表が読めない→止める" 1 "$(PII_PATTERNS="$P/isdir.txt" git commit -qm h3 >/dev/null 2>&1; echo $?)"

echo "---- 合格 $pass / 不合格 $failn"
[ "$failn" -eq 0 ]
