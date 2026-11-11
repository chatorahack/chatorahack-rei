---
file: docs/repos.md
template: REI
title: 記録と実装のリポジトリに分けるとき
description: 1つのプロジェクトを -docs と -web・-api に分けるとき、REI の何をどちらに置くか
---

# 記録のリポジトリ（-docs）と実装のリポジトリ（-web・-api）に分けるとき

1つのプロジェクトを、記録のリポジトリ（`-docs`）と実装のリポジトリ（`-web`・`-api` など）に分けるときの、REI の置き方。名前の末尾の意味は `docs/naming.md`、雛形の版を上げるときは `docs/howto/upgrade.md`。

## 1. 定番

- 1つのリポジトリにまとめる（モノレポ）か、分ける（ポリレポ）かは、どちらも定番。まとめれば Claude Code の指示や hook が1か所で効く。分けると公開の範囲を分けやすい（`-docs` は非公開のまま、実装だけを公開するなど）
- Claude Code が読む場所（公式の手引き、下の「出典」）：
  - CLAUDE.md：起動したフォルダと、その上の階層のものを最初に読む。下の階層のものは、そこのファイルに触れたときに読む。**隣のリポジトリ（`../<名前>-web`）は下の階層ではないので読まない**。`--add-dir` で足したフォルダも、既定では読まない（環境変数 `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1` で読む）
  - CLAUDE.md の `@パス` の読み込み：プロジェクトの外を指すと、初めてのときに承認の画面が出る。断ると読み込まない
  - hook：起動したプロジェクトの `.claude/settings.json`（と `settings.local.json`）、ユーザーの設定、プラグインから読む。**書き込んだ先のリポジトリの hook は動かない**
  - `.claude/settings.json`：CLAUDE.md と違い、上の階層のものを受け継がない。起動したフォルダのものだけを読む
  - 隣のリポジトリを読み書きする：`.claude/settings.json` の `permissions.additionalDirectories`（例：`["../<名前>-web"]`）か、起動のときの `--add-dir`。`additionalDirectories` で足したフォルダの CLAUDE.md・スキルは読まない
  - git の pre-commit：Claude Code とは別に、コミットしたリポジトリの `.githooks/`（`core.hooksPath` を設定したもの）が動く

## 2. この雛形の決まり（例）

方針・手順・記録の正本は `-docs` の1か所に置く。実装のリポジトリには、コミット前の点検と、秘密を読まない設定だけを置く。例：`shop-docs`（記録）と `shop-web`（実装）に分ける。

| 置くもの | `-docs` | 実装のリポジトリ |
|---|---|---|
| `policy.md`・`AGENTS.md`・`GOAL.md`・`START.md`・`handoff.md` | 置く（正本） | 置かない。`CLAUDE.md` に「方針・手順は `../<名前>-docs` に従う」と書く（写すと2か所がずれる） |
| `ledger/`・`decisions/` | 置く | 置かない。実装の設計の記録（ADR）を実装のリポジトリに置くかは、プロジェクトで決める |
| コミット前の点検（`.githooks/pre-commit`・`scripts/check-*.sh`） | 置く | 写しを置く。**どの版から写したか**を `CLAUDE.md` に書く（例：「REI v0.3.0-beta.38 から写した」）。clone したら1回 `git config core.hooksPath .githooks` |
| `.claude/settings.json`（秘密を読まない設定・hook） | 置く | 置く（実装のリポジトリで起動したときのため） |
| `.claude/hooks/`（止める・決定・外への書き込み） | 置く | 実装のリポジトリで起動して作業するなら置く。`-docs` で起動して作業するだけなら要らない（動かないため） |

## 3. どこで起動すると、何が効くか

| 起動した場所 | 効く Claude Code の hook | 読まれる CLAUDE.md | git の pre-commit |
|---|---|---|---|
| `-docs` で起動して、実装のリポジトリに書く | `-docs` のもの。実装のリポジトリに書くたびに、scope-guard が「このプロジェクトの外への書き込み」として確認を求める | `-docs` のもの。実装のリポジトリの `CLAUDE.md` は読まれない | コミットしたリポジトリのもの |
| 実装のリポジトリで起動する | 実装のリポジトリの `.claude/settings.json` に入れたもの | 実装のリポジトリのもの。そこから `@../<名前>-docs/...` で読み込むなら、初めてのときに承認が要る | 同上 |
| 両方の親のフォルダで起動する | 親のフォルダのもの（各リポジトリの hook は動かない） | 親のもの。各リポジトリの `CLAUDE.md` は、そこのファイルに触れたときに読む | 同上 |

- どれで起動しても、git の pre-commit は効く。Claude Code の hook に頼らない点検（決定ファイルの書き換え・見えない制御文字・個人情報）は、実装のリポジトリにも写しておく
- `-docs` で起動して実装のリポジトリに書くなら、`-docs` の `.claude/settings.json` の `additionalDirectories` に実装のリポジトリを足す（Claude Code の定番の方法）。それでも scope-guard は、起動したプロジェクトの外への書き込みとして確認を求める。毎回の確認が多すぎるかは、使ってみて決める（この雛形の scope-guard には、隣のリポジトリだけを許す設定は無い）

## 4. 雛形の版を上げるとき

実装のリポジトリに写した点検も、雛形の一部として一緒に上げる。`docs/howto/upgrade.md` の 2. で、`.githooks/pre-commit`・`scripts/check-*.sh` が「入れ替え」「3方向」に出たら、実装のリポジトリも同じように上げ、`CLAUDE.md` の「どの版から写したか」を直す。

## 出典

- Claude Code「How Claude remembers your project」（CLAUDE.md の読まれ方・`--add-dir`・外の読み込みの承認）：https://code.claude.com/docs/en/memory （2026-11-08 確認）
- Claude Code「Hooks reference」（hook を読む場所、`CLAUDE_PROJECT_DIR` は起動したプロジェクト）：https://code.claude.com/docs/en/hooks （2026-11-08 確認）
- Claude Code「Set up Claude Code in a monorepo or large codebase」（起動する場所で読まれるもの、settings.json は受け継がない、`additionalDirectories`・`--add-dir` で読まれるもの）：https://code.claude.com/docs/en/large-codebases （2026-11-08 確認）
