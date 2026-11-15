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
