# rei-hello（プラグインの見本）

世界のあいさつと、ただ励ますだけの言葉を返す、いちばん小さな Claude Code のプラグイン。役に立つことは何もしない。自分でプラグインを作るときに、形を写すための見本。

- `/rei-hello:hello`：世界のどこかの言葉で、あいさつを1つ返す
- `/rei-hello:cheer`：ただ励ます（助言も評価もしない）

どちらも、人が打ったときだけ動く（AI が勝手に呼ばない）。スキルの中身は AI への指示だけで、ファイルの読み書き・コマンドの実行・外への送信を指示する内容は無い（AI がそのとおりに振る舞うことまでは保証できない。会話そのものは、いつもどおり AI の提供元に送られる）。hook・MCP・実行ファイルは入っていないので、外せば何も残らない。

## 形（これだけ）

```
（リポジトリのいちばん上）
├─ .claude-plugin/marketplace.json     ← 入手先（マーケットプレイス）の名前と、プラグインの一覧
└─ plugins/rei-hello/
   ├─ .claude-plugin/plugin.json      ← プラグインの名前と説明（name だけが必須）
   ├─ skills/hello/SKILL.md           ← /rei-hello:hello の中身（AI への指示を文で書く）
   ├─ skills/cheer/SKILL.md           ← /rei-hello:cheer の中身
   └─ README.md                       ← このファイル
```

- `SKILL.md` の頭の `disable-model-invocation: true` で、人が打ったときだけ動く
- プラグインには、ほかに hook（出来事のたびに動くスクリプト）・エージェント・MCP も入れられる。入れると、コマンドを動かしたり外とつながったりできるようになるので、見本には入れていない
- 名前は英小文字と `-` だけ。`claude-`・`anthropic-` で始めない（公式 https://code.claude.com/docs/en/plugins/manifest-reference ）

## 試す（何も入れずに、1回の起動だけ）

プロジェクトのフォルダで：

```
claude --plugin-dir <この README のあるフォルダ>
```

起動したら `/rei-hello:hello` と打つ。終われば消える（自分の PC の設定に何も書かない）。

## 入れる・外す（公開のリポジトリから）

```
# 入手先を足す（自分の PC の設定に書かれる。プロジェクトに書くなら --scope project を付ける）
claude plugin marketplace add chatorahack/chatorahack-rei
# このプロジェクトの一覧に入れる
claude plugin install rei-hello@rei-samples --scope project
# 外す
claude plugin uninstall rei-hello@rei-samples --scope project
# 入手先も消す（この入手先から入れたプラグインは、ほかのプロジェクトのものも全部外れる）
claude plugin marketplace remove rei-samples
```

入れ方・外し方の詳しいことと、一覧にあるのに入っていないときの知らせは、雛形の `docs/howto/plugins.md`。

## 自分のプラグインを作るとき

1. このフォルダを写して、名前（フォルダ名・`plugin.json` の `name`・`marketplace.json` の `name`）を変える
2. `skills/〈名前〉/SKILL.md` に、AI にしてほしいことを書く
3. `claude plugin validate <フォルダ>` で形を確かめ、`--plugin-dir` で試す
4. 配るなら、自分のリポジトリのいちばん上に `.claude-plugin/marketplace.json` を置く

作る前に、同じ用事の既存のプラグインが無いかを先に探す（`/plugin` の Discover）。
