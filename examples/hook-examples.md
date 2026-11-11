---
file: examples/hook-examples.md
template: REI
title: hook が止める場面
description: 雛形の hook とコミット前の点検が、どんな場面で何を出すかの例
---

# hook が止める場面

REI の雛形に入っている hook とコミット前の関門が、どんな場面で、何を出すかの例です。hook を実際に動かして書き出しました（REI 0.3.0-beta.9 の雛形）。文言は版によって変わることがあります。雛形と違うときは雛形が正です。

決定ファイルの名前（`0001-alt-text.md`）は、hook を動かすために別に作ったもので、`notice-page-update/project/` の決定ファイルとは別です。

止め方は2種類あります。

- **断る（deny）**：その道具を使わせない。人が「止めて」と言ったとき
- **確かめる（ask）**：Claude Code が人に「許しますか」と聞く。人が許せば進む。決定ファイルの書き換え、プロジェクトの外への書き込み

hook は Claude Code の中でしか効きません。人が直接コミットするときや、ほかの AI の道具を使ったときのために、git のコミット前の関門（`.githooks/pre-commit`）があります。

## 1. 人が「止めて」と言う

人の言葉に「止めて」が入ると、`stop-request.sh`（UserPromptSubmit）が止めた印を置き、AI に次のように伝えます。

AI に届く文：

```text
[REI] 人間が「止めて」と言いました。止めた印（.claude/stop-requested）を置きました。人間が印を消すまで、すべての道具は止まります。何をしていたかを短く伝えてください（何もしていなければ「何もしていません」）。謝るのは、頼まれていないことをした場合と、間違えた場合だけです。頼まれたことをしていただけなら謝りません。そのあと、次の指示を待ってください。
```

印がある間に AI が道具を使おうとすると、`stop-guard.sh`（PreToolUse）が断ります：

```text
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"[REI stop-guard] 人間が「止めて」と言ったため、すべての道具を止めています。再開するには、人間がClaude Codeの外（普通のターミナル等）で .claude/stop-requested を消してください（例：rm .claude/stop-requested）。"}}
```


## 2. 既存の決定ファイルを書き換えようとする

`decisions/` にある決定は書き換えず、覆すときは新しい番号で足します。AI が編集の道具で既存のファイルを直そうとすると、`decisions-guard.sh` が人に確認を求めます（止めるのではなく、人が許すかを選びます）。

出るもの（Claude Code が確認の画面に理由として出します）：

```text
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"[REI decisions-guard] 既存の決定ファイル（decisions/0001-alt-text.md）への直接編集です。Forward-only原則により、既存ファイルは書き換えません。覆す場合は新しい番号のファイルを追加してください。"}}
```

コマンドで書き換えようとしたとき（`decisions-bash-guard.sh`）：

```text
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"[REI decisions-bash-guard] Bash のコマンドで decisions/（または docs/adr/）に書き込もうとしています。既存の決定ファイルは書き換えません（Forward-only）。新しい決定は、編集の道具で新しい番号のファイルとして作ってください。"}}
```


## 3. プロジェクトの外に書こうとする

AI がこのプロジェクトのフォルダの外にファイルを書こうとすると、`scope-guard.sh` が人に確認を求めます。

出るもの：

```text
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"[REI scope-guard] このプロジェクトの外への書き込みです。別のプロジェクト・共有のフォルダに書く前に、何を・どこに・なぜ書くかを人に確かめてください。"}}
```


## 4. コミットの前の関門（pre-commit）

Claude Code の外で人が直接コミットするときも効きます。使い始めに1回 `git config core.hooksPath .githooks` を実行しておきます。

見えない制御文字（ここでは BEL）が入った行をコミットしようとしたとき：

```text
OK   decisions/・docs/adr/の既存ファイルへの書き換え・削除・リネームなし
[制御文字] site-note.txt：足した行に、見えない制御文字が 1 文字入っています
パスの \a・\r・\v などが化けていないか確かめ、エディタ（AI なら編集の道具）で直してからコミットしてください。
```

個人情報の表（リポジトリの外に置く）にある名前が入った行をコミットしようとしたとき（この例の表には作り話の名前「見本 花子」だけを入れています）：

```text
OK   decisions/・docs/adr/の既存ファイルへの書き換え・削除・リネームなし
[REI] 個人を特定できる情報（パターン表の語）を含む行が、このコミットに追加されています（値・行の中身は表示しません）:
- site-note.txt（1行目）
伏せ字（{{PERSON}}・{{EMAIL_ADDRESS}}等。一覧は pii_patterns.example.txt）に置き換えてからコミットしてください。
```

既存の決定ファイルを書き換えてコミットしようとしたとき：

```text
FAIL 既存のdecisions/・docs/adr/が書き換え・削除・リネームされています（新しい番号のファイルで上書き宣言する）:
M  decisions/0001-alt-text.md

[REI pre-commit] decisions/・docs/adr/ の既存のファイルが書き換えられています。
新しい番号のファイルで上書きを宣言してください。回避する場合は git commit --no-verify
```

