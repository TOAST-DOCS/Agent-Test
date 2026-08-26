<!-- pre-align:aligned sig=28e448e4e890 -->

<a id="fill-stub-sample"></a>
## 空の翻訳埋めサンプル { #fill-stub-sample }

この文書は**空の翻訳埋め**(`translate/translate_fill_stubs.py`)を検証するためのテストフィクスチャです。
en/ja のコピーには pre-align が残す 2 種類の stub をわざと残してあり、埋め込み実行がその stub だけを正確に
埋め、ほかのセクションをバイト単位で保存するかを確認します。

この文書はユーザーガイドメニュー(`ko/nav.yml`)には登録しません。配布される文書ではなくパイプラインのフィクスチャです。

<a id="fill-stub-untouched"></a>
## すでに翻訳済みのセクション { #fill-stub-untouched }

このセクションは en/ja にすでに翻訳されています。埋め込み実行のあとも**バイト単位で同一**でなければなりません。
1 文字でも変わっていれば、埋め込みが stub の外に触れたということなので欠陥です。

<a id="fill-stub-body"></a>
## 本文だけが空のセクション { #fill-stub-body }

<!-- TODO: translate body -->

<a id="fill-stub-table"></a>
## 表があるセクション { #fill-stub-table }

<!-- TODO: translate body -->

<a id="fill-stub-code"></a>
## コードブロックがあるセクション { #fill-stub-code }

<!-- TODO: translate body -->

<a id="fill-stub-heading"></a>
## 제목까지 비어 있는 섹션 { #fill-stub-heading }

<!-- TODO: translate -->

<a id="fill-stub-heading-child"></a>
### 하위 제목도 비어 있는 경우 { #fill-stub-heading-child }

<!-- TODO: translate -->

## 앵커가 없는 섹션

<!-- TODO: translate -->

<a id="fill-stub-tail"></a>
## 最後のセクション { #fill-stub-tail }

stub のあとに来るセクションです。上のセクションが埋められたあとも、このセクションはバイト単位で保存されなければなりません。
