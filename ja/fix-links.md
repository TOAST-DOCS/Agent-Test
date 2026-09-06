<!-- pre-align:aligned sig=bd7c613fa6f9 -->

<a id="fix-links-overview"></a>
## リンク訂正テスト { #fix-links-overview }

この文書は**リンク訂正**(`dashboard/links/fix.py`、Jenkins `fix-links`)の e2e フィクスチャです。
以下の各セクションは決定的ルールを 1 つずつ狙って**わざと壊したリンク**を持ち、
`scripts/e2e-fix-links.sh` が訂正結果をルールごとに判定します。

この文書はユーザーガイドメニュー(`ko/nav.yml`)には登録しません。配布される文書ではなくパイプラインのフィクスチャです。

<a id="fix-links-self"></a>
## self-link { #fix-links-self }

同じファイルをデプロイ URL 形式のパスで指すリンクです。純粋な in-file `#slug` だけが残るべきです。

* [正常なリンク集](#fix-links-controls)

<a id="fix-links-relativize"></a>
## relativize { #fix-links-relativize }

同じ repo 内のファイルを絶対 URL・repo-rooted パスで指すリンクです。どちらも `./overview.md#pricing` になるべきです。

* [料金 (github blob URL)](./overview/#pricing)
* [料金 (repo-rooted パス)](./overview/#pricing)

<a id="fix-links-langdir"></a>
## lang-dir { #fix-links-langdir }

別の言語フォルダーを指す in-repo リンクです。同じ言語の対応ファイルが実在するので入れ替わるべきです。

* [料金 (別の言語フォルダー)](./overview/#pricing)

<a id="fix-links-nested"></a>
## nested-frag { #fix-links-nested }

デプロイ URL の断片が fragment に入り込み `#a/#b` と重なったリンクです。最後の `/#` 以降だけが残るべきです。

* [料金 (重なった fragment)](./overview.md#pricing)

<a id="fix-links-heading"></a>
## heading-frag { #fix-links-heading }

fragment は死んでいますが、リンクテキストが対象文書の heading と完全に一致するリンクです。
その heading の canonical id になるべきです。

* [キーペア(Key-pair)](./overview.md#key-pair)

<a id="fix-links-langsite"></a>
## lang-site { #fix-links-langsite }

site-root 短縮形が**別の言語**を指しているリンクです。ロケール位置が一つだけ書かれているように
見えますが、デプロイ時に前の位置がこの文書の言語で埋められ `/ja/…/ko/…` になるため、
死んだリンクです。同じ言語の対応文書に置き換えられるべきです。

* [料金 (site-root 別言語)](./overview/#pricing)

<a id="fix-links-absdocs"></a>
## abs-docs · abs-docs-env { #fix-links-absdocs }

同じ repo の文書を**デプロイ絶対 URL** で指しているリンクです。同じソースファイルが
alpha/beta/master のすべてにデプロイされるため、どの host を埋め込んでも最低二つの環境で
誤りになります。どちらも相対パスになるべきで、非本番 host は別の表記コード
(`abs-docs-env`) で判定されます。

* [料金 (本番 host)](./overview/#pricing)
* [料金 (alpha host)](./overview/#pricing)

<a id="fix-links-legacyjp"></a>
## legacy-jp { #fix-links-legacyjp }

2026-08 以前の日本語セグメント `jp` が残っているリンクです。`jp` は両方の位置で死んだ
ロケールなので、この文書の言語に置き換えられるべきです。

* [料金 (レガシー jp)](./overview/#pricing)

<a id="fix-links-report"></a>
## 訂正せず報告だけすべきリンク { #fix-links-report }

訂正結果が実際に resolve するか確認できないリンクです。黙って直すのも黙って飛ばすのもいけません。
PR 本文の「人が直接確認すべき部分」の表に理由付きで載るべきです。

* [存在しない文書](./no-such-doc-e2e.md#nowhere)
* [どの anchor か分からない](./overview.md#anchor-that-does-not-exist-e2e)
* [他の言語にしか存在しない文書](../ko/mermaid-sample.md)
* [![図](/ja/overview.md#key-pair)](/ja/overview.md#key-pair)

上の四件は理由が異なります。後の二件はそれぞれ、**同じ言語の対応文書が repo に無い** ため
言語だけを変えると生きているリンクが 404 になる場合と、一つのスニペットに target スロットが
**二度** 現れる (画像が自分自身を指す形) ため、どちらを書き換えるべきか特定できない場合です。
前者は一つの言語にしか存在しない文書を指す必要があるため (そうでないと「言語を変えると 404 に
なる」という判断が実際に動かない)、対象が言語ごとに異なります。つまりこのフィクスチャには
**意図的な** ko/en/ja リンク不一致があり、`lang-parity` の報告に常に 2 件として現れます。
判定 (8c) がその 2 件を期待値として固定します — 現れなければ比較が動いていないということです。


<a id="fix-links-controls"></a>
## 正常なリンク集 { #fix-links-controls }

**負の対照群です。** 以下のリンクはすべて正常なので、訂正実行のあとも**バイト単位で同一**でなければなりません。
1 つでも変わっていれば、訂正が健全なリンクに触れたということです。

* [この文書の最初のセクション](#fix-links-overview)
* [概要文書](./overview.md)
* [概要文書の料金](./overview.md#pricing)
* [概要文書の料金 (デプロイ URL 形式 — コーパスの支配的な慣行)](./overview/#pricing)
* [他 repo のガイド (site-root — cross-repo の正しい表記)](/Compute/Instance/ja/overview/)
* [NHN Cloud](https://www.nhncloud.com/)

コードフェンス内のリンクはリンクとして扱われないので、こちらもそのまま残るべきです。

```markdown
[フェンス内の壊れたリンク](./no-such-doc-e2e.md#nowhere)
[フェンス内の self-path](./fix-links/#fix-links-controls)
```
