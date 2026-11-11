---
file: docs/troubleshooting.md
template: REI
title: 困ったとき
description: REI のスクリプト・hook でよくある症状と、原因・直し方の表
---

# 困ったとき（症状 → 原因 → 直し方）

REIのスクリプト・hookでよくある症状を載せる。新しい症状に出会ったら、確認した日付と一緒に足す。

| 症状 | 原因 | 直し方 |
|---|---|---|
| hookが1つも動かない（セッション開始の表示が出ない） | Claude Codeを、このプロジェクト以外のフォルダを作業フォルダにして起動している。hookは作業フォルダのプロジェクトの設定でしか動かない | このプロジェクトのフォルダで起動し直す |
| コミットしても決定の書き換えや個人情報のチェックが動かない | `core.hooksPath`を設定していない | `git config core.hooksPath .githooks`（先に`.githooks/`の中身を読む。`docs/security.md`） |
| AIが`AGENTS.md`の決まりを知らない様子 | `CLAUDE.md`の`@AGENTS.md`の行が消えている、または別のフォルダを作業フォルダにして起動している | `CLAUDE.md`に`@GOAL.md`・`@policy.md`・`@AGENTS.md`の3行があるか確かめる。このプロジェクトのフォルダで起動し直す |
| 個人情報のチェックで、日本語の語が検出されない | Windows PowerShell 5.1の`Set-Content`がUTF-8で書かない（試験用のファイルが別の文字コードになる） | `docs/howto/pii-check.md`のPowerShellの例（`[IO.File]::WriteAllText`でUTF-8にする）を使う |
| cmd・PowerShell・Pythonから`bash …`を実行すると、Linux（WSL）のエラーが出る・動きが違う | Windowsでは`bash`がWSLのbashを指すことがある | Git Bashを使うか、`C:\Program Files\Git\bin\bash.exe`を明示する |
| PowerShellの`Read-Host -MaskInput`がエラーになる | Windows PowerShell 5.1にはこのオプションが無い | `Read-Host -AsSecureString`を使う（`docs/howto/pii-check.md`の例） |
| 個人情報のチェックが「チェック自体が失敗した」と言って止まる | 表がフォルダになっている・読めない等で、照合できなかった（「該当なし」とはしない設計） | 表のパス（`~/.config/rei/pii_patterns.txt`・`PII_PATTERNS`・`PII_PATTERNS_EXTRA`）が読めるファイルか確かめる |
| `claude -p --allowedTools …`で道具を絞ったのに、AIが Bash を使う | `--allowedTools`は「確認なしで動かしてよい道具」を決めるだけで、使える道具を絞らない。読むだけの Bash（`ls`・`cat`等）はどの設定でも動き、acceptEdits では作業フォルダの中の`cp`・`mv`・`>`も通る（Claude Code 公式の CLI reference・Configure permissions、2026-10-25 確認） | 使える道具を絞るときは`--tools Read,Glob,Grep,Edit,Write`のように`--tools`を使う |
| プロジェクトの中のファイルなのに「このプロジェクトの外への書き込み」と確認を求められる | Windows で、同じフォルダが短い名前（`ABCDEF~1`のような8.3 形式）と長い名前の2通りで表されている | この雛形の`scope-guard.sh`はそろえてから比べる。それでも出るなら、作業フォルダを長い名前の場所で開き直す |
| AIがどの道具も使えず、「[REI stop-guard]」で断られ続ける | 「止めて」「やめて」「ストップ」を含む言葉（「やめておいた方がいい？」なども）を受けて、止めた印`.claude/stop-requested`が置かれた。印は自動では消えない | 本当に止めたかったのでなければ、エクスプローラーか`rm .claude/stop-requested`で印を消す（AIは消せない） |
| 初めての`git add`で`LF will be replaced by CRLF`の警告がたくさん出る | Windows の Git の既定の設定（`core.autocrlf=true`）で、改行の扱いを知らせているだけ | 無害。そのまま進めてよい |
| スクリプトやhookが`$'\r': command not found`などで動かない | Windows で改行が CRLF になった | `.gitattributes`（`*.sh text eol=lf`）があるか確かめ、そのファイルを LF で保存し直す |
| AI が書いた記録の Windows のパス（`C:\path\to\rei\…` など）が化ける・コミット前の点検（check-control-chars）が制御文字で止まる | Python の文字列・`printf`・`echo -e`・`sed` の置き換え・`awk -v` に、バックスラッシュを含むパスを書いた。`\a`・`\r`・`\v`・`\t` などが制御文字として解釈される（ヒアドキュメントを `<<'EOF'` で囲んでも、その中の Python の文字列では解釈される） | バックスラッシュを1つでも含む文字列は、AI のファイルを直す道具（Edit）で書く。どうしても Python で書くなら `chr(92)` で組み立てる。シェルなら `<<'EOF'` のヒアドキュメントを cat でそのまま書く |
| 前の会話が `/resume` の一覧に無い・消えた | (1) 別のフォルダで Claude Code を開いた（一覧は、開いたフォルダの会話だけを出す。記録は消えていない）(2) 最後に動いてから30日たち、起動のときに消えた（Claude Code の既定の片付け） | (1) 前の会話をしたフォルダで開き直す (2) 戻らない。これから残すなら個人の設定に `cleanupPeriodDays`（`docs/howto/backup.md`「Claude Code の会話の記録」）。 |
