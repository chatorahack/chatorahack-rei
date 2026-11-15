---
file: docs/howto/plugins.md
template: REI
title: プラグインで機能を足す・外す
description: 便利な機能を Claude Code のプラグインとして、.claude/settings.json の一覧で出し入れする手順
---

# プラグインで機能を足す・外す

- **誰が実行するか**：入れる・外すのは人（コマンドを打つか、`/plugin` の画面で選ぶ）。AI は手順を示し、入れる前に何が入るかを一緒に読む
- **何が起きるか**：REI の基本の仕組み（決まり・記録・止める仕組み・コミット前の点検）は、このプロジェクトのファイルとして最初から入っている。プラグインを入れなくても動く。便利な機能は、Claude Code のプラグインとして足したり外したりできる
- **一覧はどこか**：`.claude/settings.json` の `enabledPlugins`（使うプラグイン）と `extraKnownMarketplaces`（プラグインの入手先＝マーケットプレイス）。Node の `package.json` の依存の一覧に当たる。プラグインの中身はこのプロジェクトの外（Claude Code のプラグインの置き場）に入り、git には入らない
- 仕組みは Claude Code のもの（公式 https://code.claude.com/docs/en/plugins/install 、https://code.claude.com/docs/en/plugins/loading ）。REI は一覧の欄と、下の見張りだけを持つ

## 概要（言葉と、Node との対応）

| 言葉 | Node で言えば | 例 |
|---|---|---|
| プラグイン | パッケージ（機能のまとまり。スキル・hook・エージェント・MCP を入れられる） | 見本の `rei-hello` |
| マーケットプレイス | レジストリ（入手先。プラグインの一覧を載せたカタログ） | 見本の `rei-samples`、Claude Code が最初から登録している `claude-plugins-official` |
| ID | パッケージ名 | `<プラグイン名>@<マーケットプレイス名>`（例：`rei-hello@rei-samples`）。一覧に書くのも、入れる・外すときに指すのも、この ID |
| 一覧（`.claude/settings.json`） | `package.json` | `extraKnownMarketplaces`＝どの入手先を使うか、`enabledPlugins`＝どのプラグインを使うか。git に入れて、ほかの人と分け合う |
| プラグインの置き場（`~/.claude/plugins/`） | `node_modules` | 各 PC に入る実物。git には入らない |

雛形の一覧は、最初は空。「最初から入れておく」は、中身ではなく一覧に何を書いておくかのこと。書いたものは、各 PC で入れてから動く（下の「足す」「ほかの人・別の PC で使う」）。

探す・入れる・外す・作る・確かめる・配るは、どれも Claude Code の道具でできる。REI は新しい仕組みを作らない。

| すること | 道具 |
|---|---|
| 探す | `/plugin` の Discover、`claude plugin list --available --json`（`--json` が無いと `--available` は効かない） |
| 何を足すかを読む | 入れる前：`/plugin` の詳細（Will install）と、プラグインのソース（`hooks/hooks.json`・`.mcp.json`・`bin/`）。入れた後：`claude plugin details <名前>` |
| 入れる | `claude plugin install <ID> --scope project`（一覧に書かれる） |
| 外す | `claude plugin uninstall <ID> --scope project`、自分だけなら `/plugin` の Installed で Disable |
| 作る | `.claude-plugin/plugin.json` と `skills/〈名前〉/SKILL.md`（下の「見本」） |
| 形を確かめる | `claude plugin validate <フォルダ>`（形だけ。中身が安全かは人が読む） |
| 配る | 自分のリポジトリのいちばん上に `.claude-plugin/marketplace.json` を置く |

## 選び方の目安

入れる前に、`/plugin` の詳細（Will install）と、プラグインの README・`hooks/hooks.json`・`.mcp.json` を読む（`claude plugin details` は入れた後でないと使えない）。次に当たるものは、入れないか、確かめてから入れる。

- **REI と同じ出来事で動く hook を持つ**（起動のとき・話しかけたとき・道具を使う直前・答え終わったとき）：REI の知らせ・記録・止める仕組みと二重に動く。止める判断がぶつかることがある
- **REI と同じ役目を持つ**（引き継ぎ・決めたことの記録・記憶）：記録の置き場が2つになり、どちらが正本か分からなくなる
- **確かめずに外に効く操作をする**（push・PR の作成・コメントの投稿・削除）：REI の「外に効く操作は人の了承の後」とぶつかる
- **外のサービスやアカウントにつなぐ**：何を送るかを先に読む。会話やファイルの中身を送るものは、個人情報・秘密の扱い（`docs/security.md`）と照らす
- **ステータスラインを書き換える**：ステータスラインは1つしか持てない。REI のものと取り合う
- **会話を別の所に溜める・要約のために AI を呼ぶ**：費用がかかり、個人情報が残る場所が増える
- **更新が止まっている・作者や中身が確かめられない**：入手元が消えていることもある

どこから入れても、プラグインはあなたの PC でコードを動かせる。公式のマーケットプレイスでも、Anthropic が中身を保証しているわけではない（公式 https://code.claude.com/docs/en/plugins/security ）。

## 見本

REI の公開のリポジトリに、いちばん小さな見本のプラグイン `rei-hello`（世界のあいさつと、ただ励ますだけの言葉を返す）と、その入手先 `rei-samples` がある（リポジトリの `plugins/rei-hello/README.md`）。スキルだけで、ファイルの読み書き・コマンドの実行・外への送信を指示する内容が無いので、入れ方・外し方を試すのと、自分のプラグインを作るときに形を写すのに使う。作る前に、同じ用事の既存のプラグインを先に探す（`/plugin` の Discover）

## 何をプラグインにするか

- **プラグインにしない**：止める仕組み（`stop-guard`）、決定の書き換えの確認（`decisions-guard`）、プロジェクトの外への書き込みの確認（`scope-guard`）、コミット前の点検（`commit-checks`）。外れても誰にも知らされないので、雛形のファイルとして残す
- **プラグインにしてよい**：外れても危なくない、便利な機能（知らせ・状態の窓口・レビュー役・手順のスキル・点検の道具など）

## 足す

1. 入手先（マーケットプレイス）を足す：プロジェクトのフォルダで `claude plugin marketplace add <入手先> --scope project`（GitHub なら `持ち主/リポジトリ`）。`.claude/settings.json` の `extraKnownMarketplaces` に書かれ、ほかの人にも入手先が分かる。自分だけで使うなら `--scope project` を付けない（自分の PC の設定に書かれる）
2. プロジェクトの一覧に入れる：プロジェクトのフォルダで `claude plugin install <プラグイン>@<マーケットプレイス> --scope project`。`.claude/settings.json` の `enabledPlugins` に書かれる
3. Claude Code を起動し直すか、`/reload-plugins` を打つ
4. `.claude/settings.json` の変わったところを見てからコミットする（一覧も、ほかの人と分け合うプロジェクトのファイル）

入れる前に、`/plugin` の画面でそのプラグインが何を足すか（hook・スキル・エージェント・MCP）を読む。プラグインは hook やコマンドを動かせる（公式 https://code.claude.com/docs/en/plugins/security ）。

## ほかの人・別の PC で使う

一覧をコミットしても、プラグインの中身は配られない。

- 入手先：`extraKnownMarketplaces` に書いてあれば、clone した人がフォルダを信頼した後、Claude Code が裏で取ってくる（公式 https://code.claude.com/docs/en/plugins/loading ）。書いてなければ、その人が `claude plugin marketplace add <入手先>` を打つ
- プラグイン：clone した人は、それぞれの PC で一度だけ `claude plugin install <プラグイン>@<マーケットプレイス> --scope project` を打つ

## 外す

- 自分だけ使わない：`/plugin` の Installed で「Disable for me」（`.claude/settings.local.json` に false が書かれる）
- プロジェクトから外す：`claude plugin uninstall <プラグイン>@<マーケットプレイス> --scope project`（`.claude/settings.json` の一覧から消える）

## 入っていないとき（見張り）

一覧に書いてあるのに、その PC に入っていないプラグインは、何も言わずに動かない（Claude Code が知らせるのは `/plugin` の Errors タブだけ）。そこで REI の `.claude/hooks/plugin-check.sh` が、起動のときに `claude plugin list --json` と一覧を比べ、入っていないものがあれば名前を知らせる。

- 一覧が空なら何もしない（起動は遅くならない）
- 見るのは `.claude/settings.json` だけ。`settings.local.json` や自分の PC の設定で足したものは見ない
- 入っているかだけを見る。入っていても読み込めなかったものは、`/plugin` の Errors タブで見る
- `claude plugin list` が動かないときは、「確かめられなかった」と知らせる
