---
file: docs/howto/backup.md
template: REI
title: 退避先を設定し、復元を試す
description: 記録の退避先の選び方と、復元できるかの試し方。Claude Code の会話の記録の残し方
---

# 退避先を設定し、復元を試す

- **誰が実行するか**：人間（外部サービスに出す操作を含むため）
- **前提**：このリポジトリにコミットがある
- **なぜ**：同じディスク上のcommitは退避にならない。定番は3-2-1ルール（3つ持つ・2種類の媒体・1つは別の場所）

## 手順（どれか1つ、できれば2つ）
| 退避先 | 向いている人 | やり方 |
|---|---|---|
| gitのホスティング（GitHub などの非公開リポジトリ） | まずはこれ。更新も復元も一番楽 | `git remote add origin <URL>` → `git push -u origin --all`。2段階認証を有効にする |
| クラウドストレージ（ファイル共有・同期のサービス） | gitのホスティングを使いたくない人 | **作業中のフォルダを同期フォルダの中に置かない**（同期で`.git`が壊れる）。`git bundle create <同期フォルダ>/<名前>.bundle --all`で1つのファイルにして置く。人に見せたくない内容は暗号化してから置く |
| 外付けのドライブ | 外部のサービスに一切出したくない人 | 最初に`git clone --mirror . <ドライブ>/<名前>.git`、以後は`git push --mirror <ドライブ>/<名前>.git`。同じ場所の災害には弱い |

選んだものと頻度を`handoff.md`の「承認済み」に書く（次のセッションの AI が、退避先を知って動けるように）。
`*.local.*`・`.env` は git に入らないので、別に退避する（秘密は暗号化してから）。

## 効いたことの確かめ方（一度は必ず）
- ホスティング：別の場所に`git clone <URL>`
- bundle：`git bundle verify <名前>.bundle`で確かめてから`git clone <名前>.bundle`
- 外付けドライブ：`git clone <ドライブ>/<名前>.git`

全ブランチと最新のコミットが戻ることを確かめる。**復元できない退避は退避ではない**。

## 戻し方
ホスティングは`git remote remove origin`、bundle・外付けドライブはファイルを消す（元のリポジトリには影響しない）。

## Claude Code の会話の記録

リポジトリとは別に、Claude Code は会話の全文を手元に置く（`~/.claude/projects/<作業フォルダから作られる名前>/` の `.jsonl`）。`/resume` で前の会話に戻れるのは、この記録があるから。

- **既定で30日で消える**：最後に動いてから30日たった記録は、Claude Code の起動のときに黙って消える（公式 https://code.claude.com/docs/en/data-usage 「Local caching」、2026-11-09 確認）。消えたものは戻らない（Claude Code に戻す機能は無い。OS のバックアップが無ければ戻らない）
- **残すなら、個人の設定に日数を書く**：`~/.claude/settings.json` に `"cleanupPeriodDays": 9999` のように書く。**`0` は使わない**（全部消える、または設定のエラー）。効いているかは `/status` で見る
  - プロジェクトの `.claude/settings.json` には書かない。プロジェクトの設定は個人の設定より優先されるので、使う人が決めた日数を上書きする（公式 https://code.claude.com/docs/en/settings 「Settings precedence」）
- **写しを取るなら**：`~/.claude/projects` を、増えた・新しくなったファイルだけ写す（元で消えたものは写し先から消さない）。Windows なら `robocopy "%USERPROFILE%\.claude\projects" "<写し先>" /E /XO`（`/MIR` は使わない。元で消えると写しからも消える）を、タスクスケジューラで毎日1回
- **写し先の扱い**：会話の全文（貼った文・道具の出力）が入る。クラウドの同期と git に入れない。秘密を貼ったことがあれば、その写しも秘密として扱う
- 大事なことは会話にだけ残さず、決まったら台帳・`decisions/`・`handoff.md` に書く（会話の記録は消えうる。REI の記録は git に入る）
