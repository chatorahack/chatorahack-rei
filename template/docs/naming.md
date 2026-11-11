---
file: docs/naming.md
template: REI
title: リポジトリの分け方とブランチの名前
description: リポジトリ・ブランチ・REI の機能の名前の決まりと、hook の書き方・書類の冒頭の決まり
---

# リポジトリの分け方とブランチの名前

リポジトリやブランチの名前を決めるときに見る。独自の名前を作る前に、ここの言葉を使う。

このファイルは2段に分かれている。

- **1. 定番**：出典で確かめた、広く使われている決まり。そのまま使う
- **2. この雛形の決まり（例）**：決まりの一例。自分のプロジェクトに合わせて変えてよい。採るなら、そのプロジェクトの `decisions/` に書き写して「決めたこと」にする

---

## 1. 定番

### ブランチ

**ブランチの種類と流れは Git Flow、名前の形は Conventional Branch** に合わせる。

| ブランチ | 役割 | どこから → どこへ（Git Flow） |
|---|---|---|
| main | 正式版。直接書き込まない。公開のたびに版の印（annotated tag）を付ける | ― |
| develop | 開発の本線 | ― |
| feature/〇〇（feat/ でもよい） | 新しい機能 | develop → develop |
| bugfix/〇〇（fix/ でもよい） | 不具合の修正 | develop → develop |
| hotfix/〇〇 | 公開中の版の急ぎの修正 | main → main と develop（release/ のブランチがあるときは、develop ではなくそちらへ） |
| release/〇〇 | 公開の準備（版の番号・最後の確認） | develop → main と develop |
| chore/〇〇 | コード以外の作業（依存の更新・文書など） | develop → develop |

- 名前は、小文字・数字・ハイフンだけ（Conventional Branch）。版の番号の点は使ってよい（`release/v1.2.0`）
- Git Flow の原典では `release-*`・`hotfix-*` とハイフンで書き、`bugfix`・`chore` の種類は無い。ここではスラッシュの形と種類を Conventional Branch に合わせた
- 小さいリポジトリや、こまめに公開するものは、develop を置かず main と短い feature/・bugfix/ だけで回してよい（Git Flow の原典の作者も、継続的に届けるなら簡単な流れを勧めている）

### 版の番号

Semantic Versioning に合わせる。試験版は正式版の番号の後ろにハイフンで付ける：`1.0.0-alpha.1` → `1.0.0-beta.1` → `1.0.0-rc.1` → `1.0.0`（この順に並ぶ）。

### 使い終わったリポジトリ

GitHub の「アーカイブ」にすると、全員にとって読み取り専用になる。設定から元に戻せる（unarchive）。公開か非公開かの扱いは、使っているサービスで確かめる。

### 何のために試すか（言葉）

| 言葉 | 意味 |
|---|---|
| spike | 分からないことを調べる、短い使い捨ての試作 |
| PoC（概念実証） | 考え方が成り立つかを、作る前に確かめる |
| prototype | 形にして触って確かめる |
| MVP | 実際に使える最小の形で出して、反応を見る |
| pilot | 本格的に使う前に、実際の使い方で小さく使う |
| smoke test | とりあえず動くかだけを手早く確かめる |
| UAT（受け入れテスト） | 使う人が「これで使える」と確かめる |
| canary | 新しい版を、一部の人にだけ先に出して様子を見る |

---

## 2. この雛形の決まり（例）

### リポジトリの分け方は2つ

| 形 | 例 | 無印 | -test・-pilot |
|---|---|---|---|
| サービス型（自分で動かして公開する） | -api・-web・-docs・無印 | 公開用（例：ビルドした成果物を置く） | 公開の前に、同じものを置いて確かめる場所 |
| テンプレート型（人が写して使う） | 無印・-docs | 配る雛形そのもの | 雛形から作った試しの実例。中身はデータで、雛形のコードは直さない |

### 名前の末尾

名前は `<サービス>-<種類>`。種類が無いものが「無印」。頭にアカウント名や組織名を付けるかは、その組織の決まりに従う（GitHub は `<持ち主>/<リポジトリ>` で既に分かれているので、付けなくても見分けはつく。名前がほかの人と重なると困る場面では、付けておく）。

| 末尾 | 意味 | 公開か（この例の決まり） | いつまで |
|---|---|---|---|
| 無印 | 正式版 | 公開するときに公開。それまで非公開 | ずっと |
| -docs | 構想・設計・決定・台帳・会話の記録 | 非公開（公開を前提にしない記録が入るため） | ずっと |
| -api | 裏側の実装 | 非公開（OSS にすると決めたら公開） | ずっと |
| -web | 画面の実装 | 非公開（OSS にすると決めたら公開） | ずっと |
| -test | 動作の確認。試験用のデータだけ | 非公開 | 確かめたら消す |
| -pilot | 実際の使い方で小さく運用する | 非公開 | 終えたらアーカイブ（下） |
| -lab | 実験の結果をまとめて発表する | 非公開（発表するときに公開） | ずっと |

- 最初はすべて非公開。公開するのは、無印と、公開すると決めたものだけ
- 本物のデータは開発用のリポジトリに入れない（テンプレート型では -pilot か各自の手元だけ）

### -pilot を終えたとき

1. 結果（何が分かったか・正式版に何を移したか）を -docs の決定か台帳に書く
2. アーカイブにする（上の「使い終わったリポジトリ」）
3. リモートを持たない -pilot は、`git bundle create <名前>.bundle --all` で1つのファイルにして、退避先に置く（`docs/howto/backup.md`）

### 流れ

着想 → -docs（構想・設計・記録）→ -api／-web（実装）→ -test（動作の確認、使い捨て）→ -pilot（小さく運用）→ 無印（正式版）

---

## REI の機能の名前

REI の雛形を機能に分けて呼ぶときの名前。REI の変更の索引（`changes.cfg`）、受け取りの記録（`.rei/received.cfg`）、将来プラグインに分けるときのプラグイン名で、同じ名前を使う。

| 名前 | 中身 |
|---|---|
| `core` | `CLAUDE.md`・`AGENTS.md`・`policy.md`・`GOAL.md`・`START.md`・`handoff.md`、台帳と決定の書式 |
| `stop-guard` | 「止めて」で道具を止める hook（`stop-request.sh`・`stop-guard.sh`・`lib/relayed-prompt.sh`） |
| `decisions-guard` | 決定の記録の書き換えを確かめる hook |
| `scope-guard` | プロジェクトの外への書き込みを確かめる hook |
| `first-time-guide` | 初めての分野の相談で、先に地図を見せる hook |
| `session-notices` | 起動のときの知らせ（`session-start.sh`）、依頼の始まりと終わりの記録（`turn-log.sh`）、状態の窓口（`/rei`＝`.claude/skills/rei/`・`scripts/rei-status.sh`、ステータスライン＝`.claude/statusline.sh`） |
| `reviewer` | 審査役（`.claude/agents/reviewer.md`） |
| `commit-checks` | コミット前の点検（`.githooks/`・`scripts/check-*.sh`） |
| `upgrade` | 版上げ（`scripts/upgrade-plan.sh`・`scripts/upgrade-try.sh`・`docs/howto/upgrade.md`・`.rei/`） |
| `docs` | そのほかの文書（`docs/`） |

- 英小文字と `-` だけ（kebab-case）。`claude-`・`anthropic-`・`anthropics-`・`cc-plugin-` で始めない、`claude`・`anthropic` を1語として含めない（Claude Code がプラグイン名として受け付けない・警告する。公式 https://code.claude.com/docs/en/plugins/manifest-reference の `name`、2026-11-08 確認）
- 名前は変えない。変えるときは、REI の `CHANGELOG.md` と `changes.cfg` に古い名前と新しい名前を書く

### hook の書き方の決まり（あとで機能ごとにプラグインに分けられるように）

- `.claude/settings.json` の hook の登録は、1つの機能に1つのエントリ（`{"matcher": …, "hooks": [1つ]}`）。同じ出来事の hook は並んで同時に動くので、分けても動きは変わらない（公式 https://code.claude.com/docs/en/hooks 「its matching hooks run in parallel」、2026-11-08 確認）。分けておくと、ある機能をプラグインに移すとき、そのエントリだけを消せばよい（プラグインの hook と settings.json の hook は、同じ中身でも別々に動くので、消し忘れると2回動く）
- hook のスクリプトは、ほかのスクリプトを自分の場所から見て読む（`SCRIPT_DIR`）。プロジェクトのファイル（止めた印・記録など）は `CLAUDE_PROJECT_DIR` の下に置く。プラグインに移したときも、`CLAUDE_PROJECT_DIR` はそのまま渡される
- プラグインの場所（`CLAUDE_PLUGIN_ROOT`・`CLAUDE_PLUGIN_DATA`）は、記録にも出力にも書かない（アカウント名を含む）
- プロジェクトで hook を足すときも、エントリを分けて足す（版を上げるときの3方向で、雛形のエントリとぶつかりにくい）

---

## 書類の冒頭（file・template・title・description・caution）

雛形の書類とスクリプトは、冒頭に次の項目を、この順で書く。ファイルを1つだけ取り出して読んでも、どこの何の書類かが分かるように。

| 項目 | 中身 |
|---|---|
| `file` | プロジェクトの中での場所（`docs/howto/upgrade.md`）。手元の場所（ドライブ名・ユーザーのフォルダ）は書かない。写しても変わらない書き方にする |
| `template` | どの雛形から来た書類か（`REI`）。別の雛形の同じ名前の書類（`AGENTS.md` など）と見分ける。写したあとも「その雛形から来た」という意味で正しいので、書き換えない。雛形の見本（下の「写して使う雛形」）から作った書類にも残してよい。見本を使わずに一から作った書類には書かない |
| `title` | 書類名 |
| `description` | 何のための書類か（1文。front matter の定番の語） |
| `caution` | 注意点（要る書類だけ。例：AI に渡さない、値を入れない） |

- 書き方：Markdown は冒頭の `---` で囲む（front matter）。スクリプト・設定は先頭のコメント（`#`、スクリプトは `#!` の次の行から）。`_about.txt` は先頭の行
- 書かないもの：作った人の名前（写すと使う人の書類になる）、日付と履歴（git と `CHANGELOG.md` が正本。冒頭に日付を書くと、版を上げるたびに3方向で冒頭がぶつかる）
- 入れない書類：`.claude/settings.json`（JSON はコメントを書けない）、`SKILL.md`・`.claude/agents/*.md`（Claude Code の決まった front matter がある。項目を足さない）、REI のリポジトリの `README.md`（GitHub がいちばん上に表で出すため）と `LICENSE`（書き換えると GitHub がライセンスを見分けられない）、使用例の中身（`examples/notice-page-update/project/`。AI が作った見本そのもの）
- 写して使う雛形（`decisions/0000-template.md`・`ledger/worklog/_template.md`）は、写した先の書類の冒頭の雛形になっている。写したら `file`・`title`・`description` を書き換える（`template` はそのまま）
- プロジェクトで足す書類も、同じ形にしてよい（決まりではない）

---

## 出典

- Git Flow：https://nvie.com/posts/a-successful-git-branching-model/ （2026-10-31 確認）
- Conventional Branch 1.1.0：https://conventionalbranch.org/ （2026-10-31 確認）
- Semantic Versioning：https://semver.org/ （2026-10-30 確認）
- GitHub のアーカイブ：https://docs.github.com/en/repositories/archiving-a-github-repository/archiving-repositories （2026-10-30 確認）
- spike・PoC・MVP などの言葉は、一般に使われている意味で書いた（特定の出典では確かめていない）
- front matter：Jekyll https://jekyllrb.com/docs/front-matter/ （冒頭の `---` で囲む YAML。Hugo・Docusaurus なども同じ形）
