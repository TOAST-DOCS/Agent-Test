<!-- pre-align:aligned sig=7e09fc5b0570 -->

<a id="fix-links-overview"></a>
## リンク訂正テスト { #fix-links-overview }

この文書は**リンク訂正**(`dashboard/viewer/link_fix.py`、Jenkins `fix-links`)の e2e フィクスチャです。
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

* [料金 (github blob URL)](./overview.md#pricing)
* [料金 (repo-rooted パス)](./overview.md#pricing)

<a id="fix-links-langdir"></a>
## lang-dir { #fix-links-langdir }

別の言語フォルダーを指す in-repo リンクです。同じ言語の対応ファイルが実在するので入れ替わるべきです。

* [料金 (別の言語フォルダー)](./overview.md#pricing)

<a id="fix-links-nested"></a>
## nested-frag { #fix-links-nested }

デプロイ URL の断片が fragment に入り込み `#a/#b` と重なったリンクです。最後の `/#` 以降だけが残るべきです。

* [料金 (重なった fragment)](./overview.md#pricing)

<a id="fix-links-heading"></a>
## heading-frag { #fix-links-heading }

fragment は死んでいますが、リンクテキストが対象文書の heading と完全に一致するリンクです。
その heading の canonical id になるべきです。

* [キーペア(Key-pair)](./overview.md#key-pair)

<a id="fix-links-report"></a>
## 訂正せず報告だけすべきリンク { #fix-links-report }

訂正結果が実際に resolve するか確認できないリンクです。黙って直すのも黙って飛ばすのもいけません。
PR 本文の「人が直接確認すべき部分」の表に理由付きで載るべきです。

* [存在しない文書](./no-such-doc-e2e.md#nowhere)
* [どの anchor か分からない](./overview.md#anchor-that-does-not-exist-e2e)

<a id="fix-links-controls"></a>
## 正常なリンク集 { #fix-links-controls }

**負の対照群です。** 以下のリンクはすべて正常なので、訂正実行のあとも**バイト単位で同一**でなければなりません。
1 つでも変わっていれば、訂正が健全なリンクに触れたということです。

* [この文書の最初のセクション](#fix-links-overview)
* [概要文書](./overview.md)
* [概要文書の料金](./overview.md#pricing)
* [概要文書の料金 (デプロイ URL 形式 — コーパスの支配的な慣行)](./overview/#pricing)
* [NHN Cloud](https://www.nhncloud.com/)

コードフェンス内のリンクはリンクとして扱われないので、こちらもそのまま残るべきです。

```markdown
[フェンス内の壊れたリンク](./no-such-doc-e2e.md#nowhere)
[フェンス内の self-path](./fix-links/#fix-links-controls)
```
