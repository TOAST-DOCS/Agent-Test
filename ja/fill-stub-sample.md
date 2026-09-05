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

本文にテーブルが含まれるボディ スタブです。入力された後でも、テーブルの列数と行数が ko と同じである必要があります。

| 項目 | 説明 | デフォルト値 |
|---|---|---|
| インスタンス タイプ | 作成するインスタンスの CPU/メモリ 仕様 | m2.c1m2 |
| ブロックストレージ | ルート ボリュームのサイズ(GB) | 20 |
| ブート スクリプト | インスタンスの初回起動時に実行するスクリプト | なし |

<a id="fill-stub-code"></a>
## コードブロックがあるセクション { #fill-stub-code }

コードブロックは翻訳対象ではありません。下記のブロックは入力後も内容がそのままである必要があります。

```bash
# fill-stub-test: this line must be copied verbatim
curl -X GET "https://api.example.com/v2.0/servers" \
  -H "X-Auth-Token: ${TOKEN}"
```

ブロック外のこの文のみが翻訳対象であり、コマンドと注釈行は変更しません。

<a id="fill-stub-heading"></a>
## 見出しまでスタブのセクション { #fill-stub-heading }

en/ja 内の同じセクションは、見出しがまだ韓国語のままの見出しスタブです。
埋め込み実行時は見出しと本文をともに翻訳しますが、見出しのレベルと `{ #id }` は韓国語を正本として従う必要があります。

<a id="fill-stub-heading-child"></a>
### 下位の見出しも空の場合 { #fill-stub-heading-child }

見出しスタブが連続して現れる場合です。親セクションとは独立して、それぞれが埋められる必要があり、
`###` レベルが `##` に昇格したり降格したりしてはいけません。

## 앵커가 없는 섹션

<!-- TODO: translate -->

<a id="fill-stub-tail"></a>
## 最後のセクション { #fill-stub-tail }

stub のあとに来るセクションです。上のセクションが埋められたあとも、このセクションはバイト単位で保存されなければなりません。
