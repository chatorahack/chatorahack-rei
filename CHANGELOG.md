---
file: CHANGELOG.md
template: REI
title: REI の CHANGELOG（雛形を配るリポジトリの、版ごとの変更）
description: REI の版ごとの変更。一番上の日付付きの見出しが版の正本
---

# CHANGELOG

書式は Keep a Changelog に、版の付け方は Semantic Versioning に沿います。
最初の公開は 0.3.0-beta.38 です。それより前の版は公開せずに作っていました。下の beta.37 までの記録は経緯として残していますが、タグも配布も無く、取り出せません。
版は、このファイルの一番上の日付付きの見出しが正本です。公開した版にはタグ（`v0.3.0-beta.N`）を付けます。

## [0.3.0-beta.43] - 2026-11-14

変更は1つ（一因子：初めて使う人の入口の書類を足した。よくある質問、まず試すチュートリアル、英語の簡単な README、AI に読ませる人向けの欄）。機能 `docs`、重さ 任意。

### Added

- `FAQ.md`：使う前に知りたいことへの短い答え（何をする・しない、ほかの道具との違い、入れると何が変わるか、要るもの、Claude Code 以外の道具、手間、向き不向き、使える量、AI に読ませる、スクリプトの安全、既にあるプロジェクト、記録用のリポジトリ、個人情報と秘密、新しい版、版上げ、外し方）
- `tutorials/`：まず試す5つの場面（初めての分野の相談、決めたことを残して覆す、止める、コミット前の点検、新しい版に気づいて上げる）。試し用のフォルダで試す
- `README.en.md`：英語の簡単な版（日本語の README が正）。雛形の中の文書と、停止の言葉などのきっかけの言葉は日本語のまま
- `README.md`・`README.en.md` の冒頭：AI に URL を渡したときに AI へのお願い（まず説明する、機械で確かめる所と AI への指示だけの所を分けて伝える、AI に話した内容が提供元へ送られることを伝える、人の了承まで手元で何もしない、了承の後も既にあるファイルと git の設定を上書きしない）と、人向けの説明。言語の切り替えと、FAQ・チュートリアルへの入口

### Changed

- `README.md`「先に知っておくこと：自動で動くスクリプト」：スクリプトが動くときを実際の5つ（起動時・人が話しかけたとき・AI が道具を使う前・AI が答え終わったとき・コミットのたび）にした。スクリプトは外へ送らないこと、AI に話した内容は AI の提供元へ送られることを書き分けた

### 上げ方

- 任意の版。足したものは雛形の外なので、プロジェクトには入らない。`.rei/received.cfg` は当てずに版だけ書く

## [0.3.0-beta.42] - 2026-11-14

変更は1つ（一因子：書類の見本と言い回しをそろえた）。機能 `docs`、重さ 任意。

### Changed

- `template/pii_patterns.example.txt`：OS のアカウント名の見本を `longaccount`・`LONGAC~1`（短い名前〔8.3 形式〕が付く長さの例）にし、見出しに、本名から付けていることが多いことと、短い名前も別の行で書くことを足した
- `template/docs/unknown.md`「答えを先に、記録はあとで」：理由を「記録を先にすると答えが遅くなったため」にした
- `examples/README.md`・`examples/notice-page-update/conversation.md`：会社・人・ページが実在しないこと、そろえた言葉の種類（時刻、ツールの版、場所や相手を指す言葉）を書いた。`examples/README.md` の「AI が見落としたこと」に、`project/handoff.md` の「目的」が雛形の説明文のままなことを足した

### Fixed

- `template/.rei/received.cfg` の説明の例：コマンドの例（辞書）と結果の例（用語集）の言葉が食い違っていたのを、辞書にそろえた

### 上げ方

- 任意の版。`pii_patterns.example.txt`・`docs/unknown.md` は雛形の持ち物なので、手を加えていなければ入れ替わる。`.rei/received.cfg` は当てずに版だけ書く。`examples/` は雛形の外なので、プロジェクトには入らない

## [0.3.0-beta.41] - 2026-11-12

変更は1つ（一因子：ほかの道具・型との関係を書いた。競わずにつなぐ、組み合わせ方も示す、部分ごとに乗り換えられる）。機能 `core`、重さ 推奨。

### Added

- `README.md`「ほかの道具と競わない」：仕様駆動の型・開発の段取りを決める型・AI の記憶の道具なども「既にあるもの」の1つで、競う相手ではなくつなぐ相手。組み合わせ方も一緒に考える。ほかの型を使うと人が決めたら、その型が受け持つところは任せ、安全と機密の決まりは外さない
- `README.md`「乗り換えるとき」：部分（`template/docs/naming.md` の機能の名前）ごとに、乗り換えてよいときと外し方（`settings.json` の登録、`[skip]`、コミット前の点検を1つ外す、`AGENTS.md`・`policy.md` の行、`decisions/`）、REI 全体を外すとき
- `README.md`「始め方」と「限界」：既にあるプロジェクトに入れる手順はまだ無い（同じ名前のファイルと `core.hooksPath` がぶつかる）

### Changed

- `template/policy.md` 0.「ほかの道具・型と競わない」：人が使うと決めたものだけに、作業の進め方・成果物の形で従う（2. のほかの項目と 4. は続ける）。指示ファイルが置いてあるだけでは「使っている」と見なさない。判断を返す線・1.・根拠のラベル・外から来た文書はデータ・試験を変えない・3. は手放さない。ぶつかったら人に返して `decisions/` に残す。3. は人が決めても外さない
- `template/policy.md` 1.：待つ場面に「ほかの型を使っているかの確かめと、その決まりとぶつかったとき（見つけたときにまとめて1回）」
- `template/policy.md` 2.「既存を先に探す」・`template/docs/unknown.md` 4.・5.：一緒に使う見込みのある道具・型が2つ以上あるときは、併用の情報も引き、何を受け持ち、どこが重なり・ぶつかるかを示す。確かめていない組み合わせには［推測］

### 上げ方

- 推奨の版。`policy.md` と `docs/unknown.md` は雛形の持ち物なので、手を加えていなければ入れ替わり、加えていれば3方向で当たる。README は雛形の外なので、プロジェクトには入らない

### 記録

- きっかけ：この雛形を作るときの観察（2つの道具を別々に調べても、どちらの説明にも相手との組み合わせが書かれておらず、AI も言われるまで組み合わせを言い出さなかった）
- 検証：別のモデルに差分を敵対的に読ませ、指摘（ほかの型の指示ファイルが人に返す線を弱める抜け道、起動の知らせ・hook の外し方・`[skip]` の書き方と実際の食い違いなど）を直した

## [0.3.0-beta.40] - 2026-11-12

変更は1つ（一因子：README の「名前」の説明を、Relational・Exchange・Interface の意味が分かる形にした）。機能 `docs`、重さ 任意。

### Changed

- `README.md`「名前」：Relational（よく分からない相手どうしをつなぎ、その関係から始める。何と何の関係か）・Exchange（一方的に教えず、調べて渡し、人が判断して試し、分かったことを記録に残して次へ持ち運ぶ）・Interface（雛形。REI 自身が標準になるのではなく、標準と人をつなぐ境界面）を1つずつ書き、「先輩」はこのつなぎ方のたとえだと書いた

### 上げ方

- 任意の版。README だけの変更で、雛形（`template/`）は変わらない

## [0.3.0-beta.39] - 2026-11-12

変更は1つ（一因子：コンセプトの言葉を README と方針に戻した）。機能 `docs`、重さ 任意。

### Changed

- `README.md`：冒頭にキャッチコピー（「分からないところが分からない」から始めよう。気軽に何でも聞けて、危ないときはちゃんと止めてくれる、先輩みたいな枠組み。）、「名前」に Relational Exchange Interface とその意味、「何のためか」に先輩の距離感、「違いは無くさない」、「態度は柔らかく、発火は硬い」、「限界」に「REI はつなぎ」
- `template/policy.md`・`template/docs/glossary.md`・`template/docs/unknown.md`：REI を「先輩」と書く（管理者・上司ではなく、指図する立場でもない）。beta.38 で「案内役」に言い換えていたのを戻した
- `template/.claude/agents/reviewer.md`・`template/docs/unknown.md`・`template/docs/troubleshooting.md`：決まりの理由になっている試験の結果を、この雛形を作るときの検証として戻した
- `template/.claude/hooks/first-time-guide.sh`：コメントに「態度は文書、発火は hook」を戻した

### 上げ方

- 任意の版。文書とコメントだけの変更で、動きは変わらない

## [0.3.0-beta.38] - 2026-11-11（最初の公開）

変更は1つ（一因子：外の決まりの問い 3・5 に、ソフトの入手元・組織の許し・実在の人に似せたもの・人を傷つける使われ方を足した）。機能 `docs`、重さ 任意。動きは変えない。

### Changed

- `template/docs/external-rules.md`：問い 3 に「使うソフト・サービスの入手元が分かっているか」「組織が使うことを認めているか」「実在の人に似せたもの（顔・声・本人が言っていない発言）を作るか、使うか」、気をつけ方に「入手元が分からないもの・組織が認めていない道具は使う前に人間に一言伝える（不正と分かったら線引き）」「似せたものを公開・商用で使うなら、本人の同意か使ってよい根拠を確かめる」。問い 5 の使われ方の例に「人や会社を傷つける文、なりすまし、架空の口コミ、偽の書類」。根拠に JDLA「生成AIの利用ガイドライン」第1.1版を足し、根拠の無いまま足した項目には、その旨を書いた
- `template/START.md`「外の決まり」の表の 3・5：同じ問いを短く

### 上げ方

- 任意の版。`docs/external-rules.md` は入れ替わる。`START.md` はプロジェクトのファイルなので、表の 3・5 を足すなら手で

出典：日本ディープラーニング協会「生成AIの利用ガイドライン【簡易解説付】」第1.1版（https://www.jdla.org/document/ 、2026-11-10 確認）

## [0.3.0-beta.37] - 2026-11-10

変更は1つ（一因子：書類の冒頭に、場所・雛形の名前・書類名・役割・注意点）。機能 `docs`、重さ 任意。中身の決まり・動きは変えない。

### Added

- 雛形の書類とスクリプトの冒頭に `file`（プロジェクトの中での場所）・`template`（どの雛形から来たか。`REI`）・`title`（書類名）・`description`（何のための書類か）・`caution`（注意点、要るものだけ）。ファイルを1つだけ取り出して読んでも、どこの何の書類かが分かるように。Markdown は front matter（冒頭の `---`）、スクリプト・設定は先頭のコメント、`_about.txt` は先頭の行。このリポジトリの `SECURITY.md`・`CHANGELOG.md`・`changes.cfg`・`examples/` の説明にも（`README.md` には入れない。GitHub がいちばん上に表で出すため）
- `template/docs/naming.md`「書類の冒頭（file・template・title・description・caution）」：項目とその順、書き方、書かないもの（作った人・日付と履歴）、入れない書類（`settings.json`・`SKILL.md`・`.claude/agents/*.md`・リポジトリの `README.md`・`LICENSE`・使用例の中身）、写して使う雛形の扱い

### Changed

- `template/decisions/0000-template.md`・`template/ledger/worklog/_template.md`：写した先の書類の冒頭の雛形（`file`・`title`・`description` を書き換える）

### 上げ方

- 任意の版。プロジェクトのファイル（`GOAL.md`・`START.md`・`handoff.md`・台帳・`CHANGELOG.md`）は「見る」に出るので、冒頭を足すなら手で。雛形の持ち物（hook・scripts・docs）は入れ替え、`AGENTS.md` などは3方向で入る

出典：Jekyll の front matter（https://jekyllrb.com/docs/front-matter/ ）

## [0.3.0-beta.36] - 2026-11-09

変更は1つ（一因子：Claude Code の会話の記録が消えることの知らせ。文書だけ）。機能 `docs`、重さ 任意。

### Added

- `template/docs/howto/backup.md`「Claude Code の会話の記録」：既定で30日で消えること（起動のときに黙って消え、戻らない）、残すなら個人の設定に `cleanupPeriodDays`（`0` は使わない。プロジェクトの設定には書かない＝使う人の決めた日数を上書きするため）、写しの取り方（増えた・新しくなったファイルだけを写し、`/MIR` は使わない）、写し先の扱い（クラウドの同期と git に入れない）、大事なことは会話にだけ残さない
- `template/docs/troubleshooting.md`：「前の会話が /resume の一覧に無い・消えた」（別のフォルダで開いただけのときと、片付けで本当に消えたときを分ける）

出典：Claude Code 公式 https://code.claude.com/docs/en/data-usage 「Local caching」、https://code.claude.com/docs/en/settings 「Settings precedence」（2026-11-09 確認）

## [0.3.0-beta.35] - 2026-11-08

変更は1つ（一因子：起動のときの「人が渡したもの」の一覧で、空白を含む名前を1つとして数える）。機能 `session-notices`、重さ 推奨。

### Fixed

- `template/.claude/hooks/session-start.sh`：「人が渡したもの」の一覧で、空白を含むファイル名・フォルダ名が2つに割れていた（`for e in $(ls -A)`。「my notes.md」が「my」と「notes.md」になり、AI が無い名前を開こうとしうる）→ `_inbox` の一覧と同じく1行ずつ読む。空白を含む名前は「」で囲んで出す（記録の `handed=` も同じ）。空白の無い名前は前と同じ形

## [0.3.0-beta.34] - 2026-11-08

変更は1つ（一因子：版上げの直し。報告の書き方と、記録の無いプロジェクトの言葉）。機能 `upgrade`、重さ 推奨。

### Changed

- `template/scripts/rei-status.sh`：記録が無いときを3つに分ける。REI から作ったものでない（記録も起動の hook も無い）なら1行で言って終える／記録の無い古い版（beta.23 まで）なら `rei=` の版と「この版の起動の hook は比べない」・上げ方（本当の親を使う）／版も分からない古い雛形なら「作り直すとき」の案内／記録が壊れているなら「壊れていて読めない」と、どの行かの見方。前は全部「記録が読めない」「起動し直すと比べる」で、REI でないプロジェクトでは案内が当たらなかった
- `template/scripts/upgrade-try.sh` の報告：
  - 入れ替え・足す・3方向の意味（入れ替えはプロジェクトの書き足しが無いもの）
  - `core.autocrlf=true` のとき、試しのフォルダの行末が CRLF なので手で直すときの注意
  - ぶつかりの中身の抜粋（1ファイル 40 行まで）
  - 「見る」のファイルの差分のコマンド（`diff -u`）
  - 実行権限の要るファイルを、そのまま流せる1行（`git update-index --chmod=+x -- …`）
  - 採る手順：手作業の版を確かめる項目（当たらなければ何もしない）として並べる、decisions/ を先に書く、受け取りの記録の applied・decision・claude-code を書くコマンド、新しい雛形が REI の clone でなければ commit は空のまま
- `template/scripts/upgrade-try.sh --discard`：採ったあと（試しのフォルダに変更が無く、そのコミットが本体に入っている）は「採った試しのフォルダを片付けました（中身は本体に入っています）」。作ったときのコミットを git の管理フォルダの中に控える（`rei-try-base`）
- `template/docs/howto/upgrade.md`：「古い雛形には本当の親を使う」（代わりの親では3方向とぶつかりが増える。親が2つ混ざっているときの見え方）、「作り直すとき」（引き継ぐもの・引き継がないもの・退避・decisions/）
- `template/docs/troubleshooting.md`：Windows のパスを Python・printf・sed などの文字列に書くと制御文字に化ける（Edit で書く、`chr(92)`、`<<'EOF'`）

### 限界

- 手作業の版が当たるかは機械では判定しない（版ごとに確かめ方が違う。確かめる項目として並べるまで）

## [0.3.0-beta.33] - 2026-11-08

変更は1つ（一因子：状態の窓口の直し）。機能 `session-notices`、重さ 推奨。

### Fixed

- `template/.claude/statusline.sh`・`template/scripts/rei-status.sh`：版を上げた直後に、ステータスラインが古い版と「新しい版がある」を、`/rei` が「新しい版がある」を出し続けた（控えは起動のときだけ書くため）→ 版は受け取りの記録（`[template]` の `version`）からその場で読み、控えが今の版のときに書かれたものでなければ、新しい版を出さない（rei-status は「版を上げたあと、まだ比べていない」）。ステータスラインは bash だけで読む（1回 約0.1秒のまま）

### Changed

- `template/.claude/skills/rei/SKILL.md`：ステータスラインを付ける前に「画面の下の操作の案内（`esc to interrupt` など）が出なくなる」と伝える（公式 https://code.claude.com/docs/en/statusline の冒頭）、ボタンの推奨の先頭にしない。状態を伝えるだけなら台帳にも worklog にも書かない。版を選んで取り込むは「実験的」、受け取りの記録があるときだけ出す
- `template/AGENTS.md` 2.：人が `/rei` で状態を見ただけのときは起票しない（`/rei` から試す・捨てる・設定を変えるをしたときは起票する）（`/rei` を開いただけで台帳に1行増えるのを防ぐ）
- `template/START.md` の冒頭：Claude Code は、プロジェクトのいちばん上のフォルダで起動する（下のフォルダで起動すると、REI の hook と設定が読まれない。公式 https://code.claude.com/docs/en/settings 「start Claude Code there」）
- `template/docs/howto/upgrade.md`「状態とメニュー（/rei）とステータスライン」に、上の3つ

### 上げ方

- `START.md` はプロジェクトのファイルなので「見る」に出る。冒頭の1行を手で足す
- `AGENTS.md` は3方向

## [0.3.0-beta.32] - 2026-11-08

変更は1つ（一因子：版上げの道具の直し）。機能 `upgrade`、重さ 推奨。

### Fixed

- `template/scripts/upgrade-plan.sh`：beta.23 までの雛形（受け取りの記録が無い）からの上げで、「間の版」（必須・手作業）が黙って出なかった → 古い版を、プロジェクトか古い雛形の `session-start.sh` の `rei=` から読む。古い版が分からないとき、新しい雛形の隣に `changes.cfg` が無いときは、出せないことを1行出す
- `template/scripts/upgrade-plan.sh`・`upgrade-try.sh`：ふつうの上げ方で、受け取りの記録（`.rei/received.cfg`）を3方向に当てていた。記録に `commit` があると、雛形の `version` の行と隣り合ってぶつかり、記録が読めなくなる → 記録は当てずに「残す」と出し、`upgrade-try.sh` は試しのフォルダの記録に `version`（と、新しい雛形が REI の clone ならその `commit`。違えば空）だけを書く。記録の無いプロジェクトには「足す」
- `template/scripts/upgrade-try.sh`：当てている途中で止めた試しを `--discard` すると「だれかが中を直しています」と誤った理由で止まった → 試しのフォルダを作った直後に「途中」の印を控え、途中で止まった試しは当てた分を戻してから消す。控えが無いときは、その理由で止める。git の出力・ロックファイルの場所の手元のパスを伏せる
- `template/scripts/upgrade-try.sh`：試しのフォルダ（git worktree）の中から流すと、別の答えになった → 止める

### Changed

- `template/.rei/owners.cfg`：受け取りの記録を shared から外した（表に書かず、当てない）
- `template/docs/howto/upgrade.md`：雛形の取り出し方をタグ全体に（`template` だけだと `changes.cfg` が無い）、受け取りの記録は当てない、`--only` は実験的（記録のあるプロジェクトで、写しに版ごとのタグがあるときだけ）

## [0.3.0-beta.31] - 2026-11-08

変更は1つ（一因子：REI の状態を見る窓口。`/rei` のメニューと、選んで付けるステータスライン）。機能 `session-notices`、重さ 推奨。

### Added

- `template/.claude/skills/rei/SKILL.md`（`/rei`）：REI の状態（版、新しい版と必須の数、版上げの試し、止めた印、ステータスライン）を出し、次にすること（新しい版を見る・試す・版を選ぶ・試しを捨てる・ステータスラインを付ける／外す・写しのフォルダを書く）をボタンで聞く。`/rei status`・`statusline-on`・`statusline-off`。人が打ったときだけ（`disable-model-invocation: true`）。先に流すコマンドは `allowed-tools` で同じ文字列だけを許す
- `template/scripts/rei-status.sh`：状態を数行で出す（見るだけ。パスは出さない）。`/rei` が最初に流す
- `template/.claude/statusline.sh`：画面の下に「REI <版>・新しい版 <版>（必須 N）・停止中・版上げの試しが残っています・/rei」を1行で出す。**付けるかは人が選ぶ**。付けるときは自分だけの設定 `.claude/settings.local.json` に書く（付けるときの値はスクリプトの冒頭）。bash だけで控えを読み、ほかのプログラムを起こさない（1回 約0.1秒）
- `template/.claude/hooks/session-start.sh`：状態の控え `.claude/rei-state`（版、新しい版、間の版の数、必須の数、写しの有無、日付。パスは書かない）。AI には最初の一度だけ `/rei` を伝え、人の画面に知らせを出すときは「状態とメニューは /rei」と添える
- `template/docs/howto/upgrade.md`「状態とメニュー（/rei）とステータスライン」、`template/docs/naming.md` の `session-notices` に3つのファイル、`template/.gitignore` に `.claude/rei-state`

### 決めたこと

- ステータスラインはプロジェクトの共有の設定には書かない。共有の設定は個人の設定より優先され、使う人が自分で作ったステータスラインがそのプロジェクトで消えるため（Claude Code 公式 https://code.claude.com/docs/en/settings 「Settings precedence」）。版の比べは起動のときだけ（`session-start.sh`）にし、ステータスラインは控えを読むだけ

## [0.3.0-beta.30] - 2026-11-08

変更は1つ（一因子：版を選んで取り込む。必須の版は飛ばせない）。機能 `upgrade`、重さ 推奨。

### Added

- `template/scripts/upgrade-plan.sh --only <版>[,<版>…] <REI の写し>`：選んだ版の変更だけ（その版の雛形と1つ前の版の雛形の差分）を、版の古い順に出す。記録の版より後で、選んだいちばん新しい版より前の、まだ取り込んでいない必須の版（`changes.cfg` の `severity = required`）は自動で足す。版の雛形は写しのタグ `v<版>` から `git archive` で、git の管理フォルダの中（`rei-versions/<版>/template`）に取り出す。最後に「記録の書き方」（記録の版は途切れずに取り込んだところまで、先に取り込んだ版は `[picked "<版>"]`、記録の版に含まれた印は消す）。機械の形では版ごとに `step<TAB><版><TAB><前の版>`
- `template/scripts/upgrade-try.sh --only <版>[,<版>…] <REI の写し>`：試しのフォルダで、版を1つ当ててから次の版の一覧を出して当てる（前の版で足したファイルを次の版が直していても当たる）。受け取りの記録は当てず、報告に「記録の書き方」を流せる形で出す
- 受け取りの記録の節 `[picked "<版>"] applied = YYYY-MM-DD`（`template/.rei/received.cfg` の説明、`docs/howto/upgrade.md`「版を選んで取り込む」）

### Changed

- `template/.claude/hooks/session-start.sh`：新しい版の知らせで、`[picked]` の版を数えない（「先に取り込んだ N 版は数えていない」）。数える版が0なら知らせない
- `template/scripts/check-received.sh`：8. `[picked]` の版の形・`applied` の日付・記録の版に含まれた印が残っていないか
- `template/scripts/upgrade-plan.sh`（ふつうの上げ方）：間の版の一覧に「済（前に --only で取り込んだ）」、終わりに、記録の版に含まれる印を消すコマンド
- 受け取りの記録（`.rei/received.cfg`）は、`--only` の版ごとの差分では当てない（版の行がぶつかるため）

### 上げ方

- ふつうに上げる（`upgrade-plan.sh <古い雛形> <新しい雛形>`）のでよい。`--only` を使うには、REI の写し（clone）に版ごとのタグがあること

### 限界

- 選んだ版が、取り込んでいない前の版を前提にしている（前の版で足したファイルを直す等）ときは「確かめる」に出るだけで、前の版を自動では足さない（必須でなければ）。`requires`（版の前提）は予約のまま

## [0.3.0-beta.29] - 2026-11-08

変更は1つ（一因子：版上げを、別の作業フォルダで試してから入れる）。機能 `upgrade`、重さ 推奨。

### Added

- `template/scripts/upgrade-try.sh`：git worktree（ブランチを作らない detached）を本体の隣に作り、新しい雛形の一覧どおりに機械で当てて確かめ、報告を `.rei/reports/` に書く。`--status`（試しが残っているか）、`--discard`（捨てる。試しを作ってからだれも手を加えていなければ戻して普通に消す。人が直していたら止めて、強制は人に返す）。止める条件：未コミットの変更・前の試しの残り・git のロックファイル（消さない）。3方向は行末をそろえてから当てる（`core.autocrlf=true` で全部の行がぶつかるのを防ぐ）。確かめる：ぶつかりの印・bash の構文・JSON の書式（python があれば）・`check-received.sh`・点検の試験・本体の HEAD と状態・git の設定4つ。Claude Code は起動しない
- `template/scripts/upgrade-plan.sh`：機械が読む形（`REI_PLAN_FORMAT=tsv`：1ファイル1行「言葉<TAB>ファイル<TAB>x」。言葉は replace・merge・add・remove・look・check・keep・skip・done・uptodate）。upgrade-try.sh と、将来の画面が読む。この形は変えない
- `template/.claude/hooks/session-start.sh`：版上げの試しが残っていれば、人の画面と AI に知らせる（パスは出さない）
- `template/docs/howto/upgrade.md`「まず試す」
- `template/.gitignore`：`.rei/reports/`

### 限界

- 途中で止めたとき（Ctrl+C）の後始末は、残ったフォルダを知らせて止まるだけ（`--discard` で捨てる）。電源断などで残ったものは、起動のときの知らせと `--status` で気づく

## [0.3.0-beta.28] - 2026-11-08

変更は1つ（一因子：受け取りの記録と変更の索引の点検）。機能 `commit-checks`、重さ 推奨。

### Added

- `template/scripts/check-received.sh`：受け取りの記録（`.rei/received.cfg`）が git の設定ファイルとして読めるか、`rei.format` が 1 か、`template.version` が1つだけで版の形か、`commit`・`applied` の形、`[template]` の項目の重複。`.rei/local.cfg` を git に入れていないか。`AGENTS.md` にアカウント名を含みうるパス（`…\Users\…`・`/Users/…`・`/home/…`）が無いか
- `template/.githooks/pre-commit`：4. として `check-received.sh` を呼び、違っていたら止める
- `template/scripts/upgrade-plan.sh`：冒頭に「間の版」（版ごとの重さ・機能・必須の理由・手作業）。終わりに、受け取ったコミットの書き方（新しい雛形が REI を clone したフォルダの中なら値まで）と、「この一覧には手元のパスが入る。記録に貼るときは消す」
- `template/.claude/hooks/session-start.sh`：知らせに「手作業あり N」（`changes.cfg` の `manual` がある版の数）
- `changes.cfg`：`reason`（必須の理由）と `manual`（上げるときの手作業）。必須の3つ（beta.2・14・21）に reason、手作業の要る4つ（beta.11・12・26・27）に manual

### Changed

- `changes.cfg`：beta.1〜23 の重さを確かめ直した。beta.13・16 を required から recommended に（誤って止まりすぎる不具合の直しで、決まりの「止まらない・見逃す」に当たらない）、beta.2 を recommended から required に（見えない制御文字で記録の見た目と中身をずらす攻撃＝Trojan Source、CVE-2021-42574）
- `template/scripts/upgrade-plan.sh`：project のファイルが雛形から無くなったとき、無いファイルとの差分を出していた → 「残す」と出し、数えない
- 版の形を決めた（この CHANGELOG の冒頭）

### 上げ方

- `.githooks/pre-commit` を3方向で当てたら、`scripts/check-received.sh` も足す（足さないと pre-commit は呼ばずに通る）

## [0.3.0-beta.27] - 2026-11-08

変更は1つ（一因子：知らせの届け方。人の画面に出し、写しのパスを git の外に置く）。機能 `session-notices`、重さ 推奨。

### Changed

- `template/.claude/hooks/session-start.sh`：出力を1つの JSON にした。AI に渡す文脈は `hookSpecificOutput.additionalContext`（前の版までの [REI] の行と同じ中身）、人の画面に出す知らせは `systemMessage`（新しい版があるとき・止めた印が残っているとき・記録が読めないとき・写しのフォルダに CHANGELOG が無いとき・写しが未設定のとき〔一度だけ〕）。知らせに「手元の写しを見ています（写しの最後のコミットの日）」を書き添える
- 写しのフォルダを、`AGENTS.md` の行から `.rei/local.cfg` の `copy.path` に移した（機械ごとの設定。git に入れない）。最後に比べた日を `copy.last-checked` に書く（git に入る `received.cfg` は起動のたびに書き換えない）
- `template/AGENTS.md`：「REI本体の手元の写し：」の行を外した。「REI本体の場所：」の記入例から「手元のフォルダでもよい」を外し、手元のパスは書かない（git に入るので、アカウント名を含むパスが履歴に残る）と書いた
- `template/.gitignore`：`.rei/local.cfg`
- `template/docs/howto/upgrade.md`「新しい版の知らせ」：写しの書き方（`git config --file .rei/local.cfg copy.path '<フォルダ>'`。手で書くなら `\` を `/` に）、人の画面と AI の2つに出すこと、写し基準であること

### 上げ方

- beta.24〜26 の雛形で「REI本体の手元の写し：」を書いていたら、その値を `git config --file .rei/local.cfg copy.path '<値>'` に移し、AGENTS.md の行は消す（AGENTS.md は3方向で行が消える）

## [0.3.0-beta.26] - 2026-11-08

変更は1つ（一因子：settings.json の hook の登録を、1つの機能に1つのエントリに分けた）。機能 `core`、重さ 任意。動きは変わらない。

### Changed

- `template/.claude/settings.json`：`UserPromptSubmit` の3つ（turn-log・stop-request・first-time-guide）と、`PreToolUse` の `Edit|Write|MultiEdit` の2つ（scope-guard・decisions-guard）を、それぞれ別のエントリにした。動く hook の組（出来事・matcher・コマンド）と並びは前と同じ

### Added

- `template/docs/naming.md`「hook の書き方の決まり」：1機能1エントリ、スクリプトは自分の場所から見てほかを読む、プロジェクトのファイルは `CLAUDE_PROJECT_DIR` の下、プラグインの場所は記録に書かない、プロジェクトで足す hook もエントリを分ける

### 上げ方

- 任意の版。プロジェクトで settings.json に hook を足していると、3方向でぶつかりやすい（並べ方を変えたため）。そのときは、雛形の新しい並べ方にプロジェクトの hook を別のエントリとして足し直す。上げないと決めたら、受け取りの記録に `[skip ".claude/settings.json"]` を書いてよい

## [0.3.0-beta.25] - 2026-11-08

変更は1つ（一因子：版を上げるときの、ファイルの持ち主と受け取らないファイル）。機能 `upgrade`、重さ 推奨。

### Added

- `template/.rei/owners.cfg`：ファイルの持ち主の表（`project`＝プロジェクトが書いていくファイル、`shared`＝両方が書くファイル、表に無いもの＝雛形の持ち物）。雛形の持ち物で、プロジェクトでは書き換えない
- `template/scripts/upgrade-plan.sh`：「見る」（project のファイルが雛形で変わった。上書きも3方向もせず、差分のコマンドを出す）、「受け取らない」（受け取りの記録の `[skip "<パス>"]`。理由と一緒に出し、数えない）。JSON の3方向には書式を確かめる一言
- `template/docs/howto/upgrade.md`「ファイルの持ち主」「受け取らないファイル」

### Changed

- `template/scripts/upgrade-plan.sh`：受け取りの記録の版がもう新しい雛形の版なら、何もせずに「済」と出す（2回流しても同じ結果）。「何かすることがあるファイル」の数に「済」を入れていたのを直した（beta.17 から）。終わりに、記録の版を最後に直すよう出す
- `template/.rei/received.cfg`：`[skip]` を予約から使えるものに移し、書き方の例を足した
- `template/docs/howto/upgrade.md` 3.：「見る」「受け取らない」と、記録の版は最後に直すこと

## [0.3.0-beta.24] - 2026-11-08

変更は1つ（一因子：版の記録と、新しい版の知らせ）。機能 `upgrade`、重さ 推奨。

### Added

- `template/.rei/received.cfg`：受け取りの記録。何を・どの版で・どこから受け取ったか（`[template]` の `version`・`commit`・`source`・`applied`・`decision`・`claude-code`）。書式は git の設定ファイルと同じで、`git config --file` で読み書きする。後の版で使う節（`skip`・`vendor`・`feature`）を予約し、知らない節は読み飛ばす
- `template/.claude/hooks/session-start.sh`：新しい版の知らせ。`AGENTS.md`「REI本体の手元の写し：」のフォルダの `CHANGELOG.md` の一番上の版が新しければ、間の版の重さ（写しの `changes.cfg` から）と一緒に1行出す。上げはしない。ネットには出ない。写しが空なら一度だけ「見ていません」と出す
- `changes.cfg`（リポジトリのルート。利用者に配る雛形の外）：変更の索引。版ごとに `feature`・`severity`。beta.1〜beta.23 も付けた
- `template/docs/naming.md`「REI の機能の名前」：10 の機能の名前と決まり（kebab-case、Claude Code のプラグイン名として受け付けられない名前を避ける）
- `template/docs/howto/upgrade.md`：「受け取りの記録」「新しい版の知らせ」（必須の版は飛ばさない）「古い雛形を手に入れる」（タグは消さない・付け直さない）「外から入れるもの（プラグインなど）を上げるとき」（自動更新は入れない）

### Changed

- `template/.claude/hooks/session-start.sh`：版を hook の中に書かず、受け取りの記録から読んで記録の `rei=` に書く（読めなければ `unknown`）。人が渡したものの一覧から `.rei` を外した
- `template/AGENTS.md`「REI本体（親）とフィードバックの送り先」：「REI本体の手元の写し：」の行を足した
- `template/docs/howto/upgrade.md`：古い版の見方を、受け取りの記録に（beta.23 までの雛形は `rei=`）
- `template/.gitattributes`：`.rei/*` の行末を LF に

## [0.3.0-beta.23] - 2026-11-08

### Added

- `template/policy.md` 2.「人の時間を守る」：段階がいくつもある作業・本番への書き込みの前に、ゴールから逆算して、段階の数・人の確認が要る段階のおおよその時間・不確かなところ・止めやすい節目・足りないものを示す。問題が出たら続ける／回り道する／止めるを人に選ばせる。本番への書き込みの順番（読むだけの確認→結果を見る場所→前提を2回確かめる→書く→結果を確かめる）。節目ごとの経過時間と、長く続いたときの止める提案（トークン・費用は推測で言わない）。モデルの割り振り

### Changed

- `template/.claude/hooks/session-start.sh`：版の表記

## [0.3.0-beta.22] - 2026-11-08

### Added

- `template/docs/repos.md`：1つのプロジェクトを記録のリポジトリ（`-docs`）と実装のリポジトリ（`-web`・`-api`）に分けるとき、REI の何をどちらに置くか。どこで起動すると、どの hook・CLAUDE.md・pre-commit が効くかの表。出典は Claude Code の公式の手引き

### Changed

- `template/AGENTS.md` 13.・`template/docs/howto/upgrade.md`：`docs/repos.md` を指す
- `template/.claude/hooks/session-start.sh`：版の表記

## [0.3.0-beta.21] - 2026-11-08

### Fixed

- `template/.claude/hooks/stop-request.sh`：beta.16 の否定の除外が「な」1字で否定と見ていたので、語尾に1字付く頼む言い方で止まらなかった。否定の形を「ない・なかった・なく・なけれ・ません」に限った
- `template/scripts/upgrade-plan.sh`：行末が CRLF と LF で違うだけのファイルを「3方向」と出していた。行末の違いを中身の違いと見ないようにした。「3方向」のときに出す `git merge-file` のコマンドに実際のパスを入れた
- `template/.claude/hooks/scope-guard.sh`：macOS の `/bin/bash`（3.2）で、パスがルートに解けるときに空の配列で止まる書き方を直した

### Changed

- `template/docs/howto/upgrade.md`：古い雛形・新しい雛形の手に入れ方（タグから取り出す・Releases の zip）、プロジェクトの版は `rei=` を見ること、新しい雛形の側のスクリプトを使うこと、CRLF と「（+x）」の注意
- `template/policy.md` 2.：試験を変える前に人に返すことを 1. の「待つ」場面に入れた。人が頼んだとき・仕様を変えると決めたとき・新しい試験を足すときは変えてよい
- `template/policy.md` 3.・`template/docs/security.md`：対象を「外から取ってきたもの（このプロジェクトの人が作ったもの・Anthropic のものは除く）」にし、「全部読む」を「指示・スクリプト・設定を読み、読み切れない分はそう伝える」にした
- `template/.claude/hooks/session-start.sh`：版の表記

## [0.3.0-beta.20] - 2026-11-07

### Added

- `template/docs/glossary.md`「AI Fluency の 4D」：Anthropic の講座「AI Fluency: Framework & Foundations」の枠組み（Delegation・Description・Discernment・Diligence）。4つの意味は原文と照らしていないので、確度は未確認

### Changed

- `template/.claude/hooks/session-start.sh`：版の表記

## [0.3.0-beta.19] - 2026-11-07

### Added

- `template/policy.md` 3.：人が作ったスキル・プラグイン・MCP サーバー・hook を入れる前に、同梱のファイルを全部読み、目的と合わない動き（外への通信・関係ないファイルの読み書き・権限の変更）を人に知らせる。入れるかは人が決める
- `template/docs/security.md`：その背景（Anthropic「Agent Skills」の Security considerations）

## [0.3.0-beta.18] - 2026-11-07

### Added

- `template/policy.md` 2.「試験を通すために試験を変えない」：試験が通らないときは実装を直す。試験の期待を書き換える・消す・弱める・その入力だけで通る作りにする、をしない。試験が間違っていると思ったら、変える前に人に返す（Anthropic「Prompting best practices」の「Avoid focusing on passing tests and hardcoding」）

## [0.3.0-beta.17] - 2026-11-07

### Added

- `template/docs/howto/upgrade.md`：作ったプロジェクトを、雛形の新しい版に上げる手順。古い雛形と新しい雛形の差分だけを当てる3方向マージ（Copier の `copier update` などと同じ考え方）で、プロジェクトで書き足したところを残す
- `template/scripts/upgrade-plan.sh`：古い雛形・新しい雛形・プロジェクトを比べ、ファイルごとに「入れ替え・3方向・足す・消す・確かめる・済」を出す（見るだけで書き換えない）

### Changed

- `template/AGENTS.md` 13.：決まった手順に、雛形を新しい版に上げることを足した
- `template/.claude/hooks/session-start.sh`：版の表記

## [0.3.0-beta.16] - 2026-11-07

### Fixed

- `template/.claude/hooks/stop-request.sh`：「止めていない」「止めてない」「やめていません」「ストップしていない」などの否定の形で、止めた印を置かないようにした。「〜を止めていない件を直して」のように打つと、すべての道具が止まっていた。「止めておいて」「止めてしまって」は頼む言い方なので、今までどおり拾う

### Changed

- `template/.claude/hooks/session-start.sh`：版の表記

## [0.3.0-beta.15] - 2026-11-07

### Changed

- 版の表記をそろえた（版の正本はこの CHANGELOG の一番上）。中身の動きは beta.14 と同じ
- `template/.claude/hooks/session-start.sh`：版の表記

## [0.3.0-beta.14] - 2026-11-07

### Fixed

- `template/.claude/hooks/scope-guard.sh`：`..` を含むパス（例：`<プロジェクト>/../shared/memo.md`）を、プロジェクトの中と判定して通していた。比べる前に「.」と「..」を文字の上で解くようにした（まだ無いファイルにも効く）。相対パスも、プロジェクトの場所から解くようにした（`../x.md` は外）

### Changed

- `template/.claude/hooks/session-start.sh`：版の表記

## [0.3.0-beta.13] - 2026-11-06

### Fixed

- `template/.claude/hooks/stop-request.sh`・`first-time-guide.sh`：別のセッションからのメッセージ、サブエージェントの報告、バックグラウンドの作業の知らせの中の言葉（「止めて」「初めて」など）で動かないようにした。Claude Code はこれらを人の入力と同じ通り道で渡すので、人が言っていないのに止めた印が置かれ、すべての道具が止まりうる

### Added

- `template/.claude/hooks/lib/relayed-prompt.sh`：入力が、Claude Code がこれらに付ける決まった書き出しで始まるかを見る（書き出しは Claude Code の版で変わりうる）

### Changed

- `template/.claude/hooks/session-start.sh`：版の表記

### Known issues

- `template/.claude/hooks/scope-guard.sh`：`..` を含むパスを、プロジェクトの外と見分けられない。次の版で直す

## [0.3.0-beta.12] - 2026-11-06

### Changed

- ファイル名・フォルダ名を英語に揃えた（中身の文は日本語のまま）。`template/_inbox/`・`template/_archive/` の置き札は `_about.txt`、使用例は `examples/hook-examples.md`・`examples/notice-page-update/`（`conversation.md`・`project/`）
- `template/.claude/hooks/session-start.sh`・`template/.gitignore`・`template/docs/howto/inbox.md`：置き札の新しい名前に合わせた。版の表記

### Known issues

- `template/.claude/hooks/scope-guard.sh`：`..` を含むパスを、プロジェクトの外と見分けられない。次の版で直す

## [0.3.0-beta.11] - 2026-11-04

### Added

- `template/START.md`「外の決まり（始める前に一度見る）」：7つの問いの表（外の AI に渡すもの・個人情報・権利・秘密保持と公開・法令と規約・AI の利用の開示・出力を人が確かめる）。全部に答えなくても始められる
- `template/docs/external-rules.md`：線引き（契約・規約・組織の決まりは、守れないと分かったら黙って進めず、進めるかは人が決めて `decisions/` に残す／法令に反すること・人を害することは止めて人に返す）、問いごとの気をつけ方、守れないときの残し方の例、AI の知らせ方、根拠の資料。法的な助言ではない

### Changed

- `template/policy.md` 2.・`template/AGENTS.md` 1.：始めるときに「外の決まり」を見る
- `template/.claude/hooks/session-start.sh`：版の表記

### 出典（確認日 2026-11-04）

- 総務省・経済産業省「AI事業者ガイドライン」第1.2版（AI 利用者に関する事項）：https://www.soumu.go.jp/main_sosiki/kenkyu/ai_network/02ryutsu20_04000019.html
- 個人情報保護委員会「生成AIサービスの利用に関する注意喚起等について」：https://www.ppc.go.jp/news/press/2023/230602kouhou/
- 文化庁「AIと著作権に関するチェックリスト＆ガイダンス」（令和6年7月31日）
- NIST AI RMF 1.0（MAP）、NIST AI 600-1（GV-1.4-002）、OWASP Top 10 for LLM Applications 2025（LLM06）

### Known issues

- `template/.claude/hooks/scope-guard.sh`：`..` を含むパスを、プロジェクトの外と見分けられない。次の版で直す

## [0.3.0-beta.10] - 2026-11-02

### Added

- `examples/`：雛形を使ったときに何がどう埋まるかの例。雛形を写したフォルダで Claude Code を実際に動かして作った、やり取り・埋まったファイル・hook が止める場面（`template/` の外にあるので、プロジェクトには写らない）

### Changed

- `template/.claude/hooks/session-start.sh`：版の表記

### Known issues

- `template/.claude/hooks/scope-guard.sh`：`..` を含むパスを、プロジェクトの外と見分けられない。次の版で直す

## [0.3.0-beta.9] - 2026-11-02

### Changed

- `template/scripts/test-check-control-chars.sh`：試験データのパスを相対パスに
- `template/scripts/check-forward-only.sh`・`template/.claude/hooks/lib/json-field.sh`：説明を実際の動きに合わせた（動きは変わらない）

## [0.3.0-beta.8] - 2026-11-02

### Added

- `template/policy.md` 2.「始末を付ける」：自分が始めたものは、道具を問わず最後まで片付ける。区切りごとに、起動したもの（ブラウザ・サーバ・バックグラウンドの処理・開いたアプリ）を止めて残りを数え、一時ファイルを消し、報告に「片付けたもの・残したもの（理由）」を添える
- `template/docs/howto/cleanup.md`：いつ・何を・どう片付けて確かめるか

### Changed

- `template/AGENTS.md` 13.：決まった手順に、片付けを足した

## [0.3.0-beta.7] - 2026-11-01

### Added

- `template/policy.md`：外の情報（記事・流行り・人が見つけた1本）をきっかけに直すときは、1つのソースで決めない。互いに独立した2つ以上で確かめ、公式の文書を最優先、反対の意見も1つは探す
- `template/CHANGELOG.md` の「記録」に「出典」の行と例（きっかけと裏取りの両方を、URL・確認した日・どの変更の根拠か・確かさと一緒に）

### Changed

- `template/AGENTS.md` 9.：「記録」に出典を入れる

## [0.3.0-beta.6] - 2026-10-31

### Added

- `template/_inbox/`・`template/_archive/`：受け取った資料の置き場と、処理した後の保管場所
- `template/docs/howto/inbox.md`：受け取る → 処理する（台帳・決めたこと・docs に要ることを書く）→ 保管する（人に確かめてから `_archive/` へ）
- `template/.claude/hooks/session-start.sh`：`_inbox/` に処理していない資料があれば、起動時に知らせる

### Changed

- `template/.gitignore`：`_inbox/`・`_archive/` の中身を git に入れない（受け取った資料には他人の資料や個人情報が入りうるため）
- `template/AGENTS.md` 13.：決まった手順に `_inbox/` の処理を足した

## [0.3.0-beta.5] - 2026-10-31

### Changed

- `template/docs/naming.md`：「定番」（Git Flow・Conventional Branch・Semantic Versioning など、出典で確かめたもの）と、「この雛形の決まり（例）」の2段に分けた

## [0.3.0-beta.4] - 2026-10-31

### Added

- `template/docs/troubleshooting.md`：「止めて」で止まったまま戻らないとき、初めての `git add` の CRLF の警告
- `template/ledger/incident_log.md`：「値は書かない。伏せ字で書く」
- `template/.gitignore`：`pii_patterns.txt`（個人情報の表を誤って写したときの二重の防ぎ）

### Changed

- `template/AGENTS.md`「REI本体（親）とフィードバックの送り先」：書き方の例を、空欄の次の行に足した
- スクリプトと hook に実行権限を付けた（macOS・Linux で pre-commit が無視されないように）

## [0.3.0-beta.3] - 2026-10-30

### Added

- `template/docs/naming.md`：リポジトリの分け方と名前の末尾（`-docs`・`-api` など）、ブランチの名前

### Changed

- `template/AGENTS.md` 13.：名前を決めるときは `docs/naming.md` の言葉を使う

## [0.3.0-beta.2] - 2026-10-25

### Added

- `template/scripts/check-control-chars.sh`：コミットで足す行に、見えない制御文字が入っていたら止める（行末の CRLF は止めない）。`.githooks/pre-commit` から呼ぶ
- `template/scripts/test-check-control-chars.sh`

## [0.3.0-beta.1] - 2026-10-25

最初の beta。中に入っているもの：

- 台帳（作業・問題・出来事）、決めたことの記録（書き換えず、覆すときは新しい番号で）、引き継ぎのメモ
- Claude Code の hook：「止めて」で道具を止める、決定ファイルの書き換え（Bash を含む）とプロジェクトの外への書き込みに確認を求める
- コミットの最後の関門（`.githooks/pre-commit`）：決定ファイルの書き換えと、個人情報の混入を止める
- 手順書（`docs/howto/`）・困ったとき（`docs/troubleshooting.md`）・セキュリティの考え方（`docs/security.md`）
- 審査役（`.claude/agents/reviewer.md`）
