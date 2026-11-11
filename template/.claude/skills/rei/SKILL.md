---
description: REI の状態（版・新しい版・版上げの試し・止めた印・ステータスライン）とメニューを出す。人が /rei と打ったときだけ使う
argument-hint: "[status | statusline-on | statusline-off]"
disable-model-invocation: true
allowed-tools: Bash(bash "${CLAUDE_PROJECT_DIR}/scripts/rei-status.sh")
---

# /rei：REI の状態とメニュー

## 今の状態（scripts/rei-status.sh の出力）

!`bash "${CLAUDE_PROJECT_DIR}/scripts/rei-status.sh"`

## すること

引数：$ARGUMENTS

1. 上の状態を、人に短く伝える（版、新しい版と必須の数、試しが残っているか、止めた印、ステータスライン）。言葉は `docs/glossary.md` に合わせ、パスは書かない。**状態を伝えるだけなら、台帳にも worklog にも書かない**（AGENTS.md 2.。このあと試す・捨てる・設定を変える、をしたときだけ、その作業を書く）
2. 引数が `status` なら、ここで終える。`statusline-on`・`statusline-off` なら、下の「ステータスライン」だけをする
3. 引数が無ければ、次にすることを**ボタンで**聞く（AskUserQuestion）。今の状態に合うものだけを、多くて4つ出す。推奨を1つ選び、先頭に置く
   - 新しい版で何が変わるかを見る（`docs/howto/upgrade.md`「用意するもの」「流れ」の 2.。見るだけ）：新しい版があるとき
   - 別の作業フォルダで試す（`bash scripts/upgrade-try.sh <古い雛形> <新しい雛形>`。本体には触らない）：新しい版があるとき
   - 版を選んで取り込む（実験的。`bash scripts/upgrade-try.sh --only <版> <REI の写し>`。必須は飛ばせない）：新しい版が2つ以上あり、受け取りの記録があるとき（写しに版ごとのタグが要る。無ければ道具がそう言って止まる）
   - 残っている試しを見る・捨てる（`.rei/reports/` の報告、`bash scripts/upgrade-try.sh --discard`）：試しが残っているとき
   - ステータスラインを付ける・外す（推奨の先頭にはしない。付けると画面の下の操作の案内が消えるため）
   - 写しのフォルダを書く（`git config --file .rei/local.cfg copy.path <フォルダ>`。人がフォルダを教える）：新しい版を見ていないとき
4. 選ばれたことをする。版を上げる・試しを捨てる・設定を変えるのは、人が選んでからだけ。結果を見せてから、コミットするかを聞く

## ステータスライン

画面の下に「REI <版>・新しい版 <版>（必須 N）・/rei」のような1行を出す（`.claude/statusline.sh`）。

- **付ける前に伝える**：付けると、画面の下の操作の案内（`esc to interrupt` など）が出なくなる（公式 https://code.claude.com/docs/en/statusline の冒頭）。止めたいときは、案内が無くても Esc で止まる。要らなくなったら外せる。それでも付けるかを聞く
- **付ける**：自分だけの設定 `.claude/settings.local.json`（git に入れない）に、次の項目を足す。ファイルが無ければ作る。JSON の書式を崩さない（崩れると Claude Code はファイルごと読み飛ばす）
  値は `.claude/statusline.sh` の冒頭の「付けるときの値」を、そのまま写す（この SKILL.md の中に書くと、Claude Code が `${…}` の一部を手元のパスに置き換えてしまうので、ここには書かない）
  - 既に `statusLine` があれば（人が作ったもの）、上書きしない。中身を見せ、置き換えるかを人に聞く
  - 個人の設定（`~/.claude/settings.json`）と共有の設定（`.claude/settings.json`）には書かない。共有の設定に書くと、ほかの人が自分で作ったステータスラインが消える（プロジェクトの設定は個人の設定より優先される）
  - 付けたあと：`.gitignore` に `.claude/settings.local.json` があるか確かめる。表示は次の応答から（フォルダを信頼していないと出ない）
- **外す**：`.claude/settings.local.json` から、REI の `statusLine`（`statusline.sh` を指すもの）だけを消す
- 表示の中身は起動のときの控え（`.claude/rei-state`）から。写しを新しくしたら、起動し直すと変わる
