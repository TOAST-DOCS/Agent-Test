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

本文にテーブルがあるbody stubです。埋めた後も、テーブルの列数と行数がkoと同じである必要があります。

| 項目 | 説明 | デフォルト値 |
|---|---|---|
| インスタンスタイプ | 作成するインスタンスのCPU/メモリ仕様 | m2.c1m2 |
| ブロックストレージ | ルートボリュームのサイズ(GB) | 20 |
| ブートスクリプト | インスタンスの初回ブート時に実行するスクリプト | なし |

<a id="fill-stub-code"></a>
## コードブロックがあるセクション { #fill-stub-code }

コードブロックは翻訳対象ではありません。以下のブロックは入力後でも、内容がそのままである必要があります。

```bash
# fill-stub-test: this line must be copied verbatim
curl -X GET "https://api.example.com/v2.0/servers" \
  -H "X-Auth-Token: ${TOKEN}"
```

ブロック外のこの文のみが翻訳対象であり、コマンドとコメント行は変更しません。

<a id="fill-stub-heading"></a>
## 見出しまで空のままのセクション { #fill-stub-heading }

en/ja の同じセクションの見出しは、まだ韓国語のままのスタブです。
埋め込み処理では、見出しと本文を合わせて翻訳します。見出しレベルと `{ #id }` は、韓国語を正本として従う必要があります。

<a id="fill-stub-heading-child"></a>
### 下位見出しも空である場合 { #fill-stub-heading-child }

見出しスタブが連続して現れるケースです。親セクションとは独立して、それぞれ埋める必要があり、
`###` レベルが `##` に昇格したり降格したりしてはいけません。

## 앵커가 없는 섹션

<!-- TODO: translate -->

<a id="fill-stub-tail"></a>
## 最後のセクション { #fill-stub-tail }

stub のあとに来るセクションです。上のセクションが埋められたあとも、このセクションはバイト単位で保存されなければなりません。
