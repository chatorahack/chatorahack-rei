---
file: CLAUDE.md
template: REI
title: このプロジェクトは REI で動いている
description: Claude Code が起動のときに読む入口。GOAL.md・policy.md・AGENTS.md を読み込む
---

# このプロジェクトはREIで動いている

起動時に次の3つを読む（Claude Codeの`@`による読み込み）。
ほかのツールで使うときは、この3つのファイルを最初に開く。

@GOAL.md
@policy.md
@AGENTS.md
