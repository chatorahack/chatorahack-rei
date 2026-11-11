---
file: docs/howto/pii-check.md
template: REI
title: 個人情報のチェックを設定する
description: 個人情報の点検の表をリポジトリの外に作り、効いているか確かめる手順
caution: 表の中身は git に入れない
---

# 個人情報のチェックを設定し、効いているか確かめる

- **誰が実行するか**：人間（表に値を書くのは人間だけ。AIは表を開かない）
- **前提**：`git config core.hooksPath .githooks`を実行済み。Git Bashがある（Windows）
- **何が起きるか**：コミットに追加される行に表の語があると、pre-commitが止め、ファイル名と行番号だけを表示する（値は表示しない）

## 手順
1. 見本をコピーする：`pii_patterns.example.txt` → `~/.config/rei/pii_patterns.txt`
   （Windowsでは`C:\Users\<アカウント名>\.config\rei\pii_patterns.txt`。場所は環境変数`PII_PATTERNS`でも変えられる）
2. コピーした方にだけ、値を`元の文字列==>伏せ字`の形で書く（書き方と伏せ字の一覧は見本の先頭）。
   **値はAIとのチャットに貼らず、エディタで直接書く**（貼った時点で外部に送られる）
3. AIに表を読ませない設定を、ユーザー全体の`~/.claude/settings.json`に入れる（このリポジトリの`.claude/settings.json`には入っている）：
   ```json
   { "permissions": { "deny": ["Read(~/.config/rei/**)"] } }
   ```
4. 追加の表を別に置く場合は、環境変数`PII_PATTERNS_EXTRA`にパスを`;`区切りで書く
   （Windows：`setx PII_PATTERNS_EXTRA "<表のパス>"`を実行し、エディタ・ターミナルを開き直す）

## 効いたことの確かめ方
登録した語を1つ入力し、一時フォルダの中だけで試す（入力した語は画面に出ない）。

Git Bash：
```bash
cd "$(mktemp -d)" && git init -q && read -rsp "登録した語を1つ入力: " w && echo && printf '%s\n' "$w" > t.md && git add t.md && bash <このリポジトリの場所>/scripts/check-pii.sh; echo "exit=$?"
```

Windows PowerShell（5.1でも動く形）：
```powershell
$d = Join-Path $env:TEMP ("piitest-" + [guid]::NewGuid()); New-Item -ItemType Directory $d | Out-Null; Set-Location $d; git init -q; $s = Read-Host "登録した語を1つ入力" -AsSecureString; $w = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($s)); [IO.File]::WriteAllText((Join-Path $d "t.md"), $w + "`n", (New-Object Text.UTF8Encoding $false)); git add t.md; & "C:\Program Files\Git\bin\bash.exe" <このリポジトリの場所>/scripts/check-pii.sh; "exit=$LASTEXITCODE"
```

`- t.md（1行目）`と`exit=1`が出れば効いている。終わったら一時フォルダを消す。

## 戻し方
表を消すか空にすると、チェックは注意だけ出して止めなくなる。一時的に回避するなら`git commit --no-verify`（最後の防波堤の1つであり、強制ではない）。
