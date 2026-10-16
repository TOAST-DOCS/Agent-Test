# リスト吸収フィクスチャ — 空行の先の別種のリスト

python-markdown はリストの後に空行を挟んで**リスト項目**が来ると、種類(箇条書き・番号)が違っても前のリストに
つなげる。そのため作成者が書いた `2.` が箇条書き `•` に、メモの `- …` が `8.` に見える。GitHub プレビュー(CommonMark)は
種類が変わると新しいリストを始めるので、ソースレビューでは見えない。

各節は**実際の alpha 文書の抜粋**である(出典は節ごとのコメント)。判定は `scripts/check_list_absorb.py` がサイトと同じ
レンダラーで行う — 作成者が書いた記号・番号と読者に見える記号・番号が違う項目を数える。

<a id="c1-numbered-after-bullets"></a>
## C1 箇条書きの後の新しい番号リスト { #c1-numbered-after-bullets }

<!-- 원본: TOAST-DOCS/Log-Crash-Search ja/console-guide.md L347-L361 @ e6bc510c -->

ログ外部保管情報を設定します。

![lcs_25_202312](https://static.toastoven.net/prod_logncrash/lcs_25_202312_ja.png)

- 外部OBSにログを保管できます。

<!-- -->

1. [AWS S3 API](/Storage/Object%20Storage/ja/s3-api-guide/#s3-api-credential)を利用して認証情報の登録および照会でアクセスキー(accessKey)と秘密鍵(secretKey)を取得します。
2. **ログ外部保管設定**で**保管設定**をクリックします。
3. アクセスキーと秘密鍵をはじめとするデータを入力します。
4. 外部ログ改ざん通知に関する情報は、設定の追加/修正/削除時に全て必要です。
5. すべてのOBS情報を入力した後、**保存**をクリックします。
    - 連動検証のために設定したバケットに一時ファイルが作成されます。

<!-- -->

- 設定したOBSでログが保存されます。
- [NHN Cloud OBS API案内ガイド](/Storage/Object%20Storage/ja/s3-api-guide/)

<a id="c2-fence-between-steps"></a>
## C2 手順の間の0字下げコードブロック + 確認の箇条書き { #c2-fence-between-steps }

<!-- 원본: TOAST-DOCS/PrivateCA ja/cert-manager-guide.md L656-L688 @ a658294d -->

1. **Issuer状態確認**

    ```bash
    kubectl describe issuer my-acme-issuer-example-com -n default
    ```

    - `Ready`ステータスが`True`か確認します。
    - ACMEアカウント登録が成功したか確認します。

2. **Certificate状態確認**

    ```bash
    kubectl describe certificate test-server-cert-example-com -n default
    ```

    - Eventsセクションでエラーメッセージを確認します。

3. **CertificateRequest確認**

    ```bash
    kubectl get certificaterequest -n default
    kubectl describe certificaterequest <request-name> -n default
    ```

4. **Challenge確認**

```bash
kubectl get challenge -n default
kubectl describe challenge <challenge-name> -n default
```

- HTTP-01 Challengeの場合、Ingressが正しく設定されているか確認します。
- Challenge URLにアクセス可能か確認します。

<a id="c3-note-bullets-after-steps"></a>
## C3 手順の後のメモの箇条書き { #c3-note-bullets-after-steps }

<!-- 원본: TOAST-DOCS/E-mail ja/console-guide.md L14-L30 @ 4a31def4 -->

受信者、件名、内容、添付ファイルなどを入力してメールを送信できます。
一般メール送信の場合受信者を直接入力する必要があります。

![email_01_20231023](https://static.toastoven.net/prod_email/email_01_20231023_en.png)

1. **メール送信**タブの**テンプレートの使用有無**で**未使用**を選択します。
2. **メール区分**で**一般メール**を選択します。
3. **送信メール**アドレスを入力します。名前形式で作成すると、送信者名とメールアドレスを入力できます。
    - "送信者名<送信メール>"の形式で送信すると、メールを受け取る人に送信者名とメールアドレスの形式で表示されます。
4. 送信したい時間があれば、**予約送信**欄に入力します。
5. **添付ファイルのアップロード**ボタンをクリックして添付ファイルをアップロードします。
6. **件名とメッセージ内容**を入力します。
7. **受信者**と**CC**にメールアドレスを入力します。

<!-- -->

- 添付ファイルは最大10個までアップロード可能で、30MB以下のファイルのみ可能です。
- 添付ファイルの合計は30MBを超えることはできません。
- 最大30MBまで添付可能ですが、受信するメールシステム（gmail.com、naver.comなど）の添付ファイル制限ポリシーにより「制限超過」で拒否されたり、スパム判定率が高くなる可能性があるため、10MB以内で添付することを推奨します。

<a id="c4-image-bullets-between-steps"></a>
## C4 手順の間の画像 + 箇条書き { #c4-image-bullets-between-steps }

<!-- 원본: TOAST-DOCS/Deploy ja/reference.md L151-L172 @ ea5b4fec -->

1. 個別追加

    ![deploy_ref_08_ja_20200527.png](https://static.toastoven.net/prod_tcdeploy/ja/deploy_ref_08_ja_20200527.png)

    * ホスト名(必須)、IPアドレス(必須)、OS(任意)を入力し、**追加**ボタンをクリックします。
    * 下にあるサーバーリストに追加された内容を確認します。左にあるチェックボックスを選択したサーバーのみ登録されます。
    * **作成**ボタンをクリックします。修正する時は**修正**ボタンをクリックします。

2. 大量追加

![deploy_ref_09_ja_20200527.png](https://static.toastoven.net/prod_tcdeploy/ja/deploy_ref_09_ja_20200527.png)

* **大量入力**チェックボックスを選択します。
* 下記のような形式でサーバー情報を入力します。
    ```
    test.host.name1;1.1.1.1;CentOS7.9;
    test.host.name2;2.2.2.2;
    ```

* **追加**ボタンをクリックします。
* サーバー情報が2個追加されたことを確認します。
* **作成**ボタンをクリックします。修正する時は**修正**ボタンをクリックします。

<a id="c5-sub-bullets-3-spaces"></a>
## C5 番号項目の下に3字下げで付けた箇条書き { #c5-sub-bullets-3-spaces }

<!-- 원본: TOAST-DOCS/Private-DNS ja/console-guide.md L57-L62 @ 576922ad -->

1. 修正するPrivate DNS Zoneを選択した後、**Private DNS Zone修正**ボタンをクリックします。
   
2. VPCを追加または削除できます。画面右側の**+**ボタンをクリックしてVPCを追加することができ、追加したVPCの**-**ボタンをクリックしてVPCを削除できます。
    - Private DNS ZoneのVPCの最小接続数は1つでなければならないため、最後のVPCは削除できません。

3. **説明**を修正し、**確認**ボタンをクリックします。

<a id="c6-bullets-under-step"></a>
## C6 番号項目のすぐ下の0字下げ箇条書き { #c6-bullets-under-step }

<!-- 원본: TOAST-DOCS/API-Gateway ja/console-guide.md L50-L64 @ 230a077f -->

1. リソースを作成するには**リソース作成**ボタンを押すか、左側リソースツリー画面で右クリックすると表示されるメニューから**リソース作成**を押します。
2. **リソースパス**を作成します。作成されたリソースパスを含めてフルパスは255文字以内で作成する必要があります。
    - 例：/products/, /products/{productsId}, /{proxy+}
3. **パス変数**：リソースパスには中括弧を使用して**パス変数**を作成できます。
    - **パス変数**は**{variable}**、下位パスを含むパス変数は**{variable+}**と宣言できます。 
        - **パス変数**はプラグインとバックエンドエンドポイント設定で活用できます。
        - **{variable}**はパス変数が位置するパスの値を変数で宣言します。
            - 例：/members/{memberId} 
                - /members/id1リクエストの**{memberId}**パス変数値は**id1**になります。
        - **{variable+}**はパス変数が位置する下位パスを含めて変数で宣言します。下位パスを含む変数には下位リソースパスを作成できません。
            - 例：/{proxy+} 
                - **/members/id1**リクエストの**{proxy+}**パス変数値は**members/id1**になります。

<!-- -->

- **プラグイン**：選択されたパスに追加されたプラグインを作成されたメソッドにも追加するにはチェックします。
- リソースを作成する時にメソッドも一緒に登録するにはHTTPメソッドを選択します。
- 登録していないリソースパスでAPI Gatewayにリクエストすると404 Not Foundレスポンスを返します。

<a id="k1-bullets-after-bullets"></a>
## 対照群 K1 箇条書きの後の箇条書き { #k1-bullets-after-bullets }

<!-- 합성 대조군 -->

- 最初の箇条書きリストの項目です。
- 同じリストの2番目の項目です。

- 空行の後の箇条書き項目です。前のリストとつながっても記号はそのままです。

<a id="k2-loose-numbered-steps"></a>
## 対照群 K2 空行を挟んだ番号手順 { #k2-loose-numbered-steps }

<!-- 합성 대조군 -->

1. 最初の手順です。

2. 2番目の手順です。

3. 3番目の手順です。

<a id="k3-sub-bullets-4-spaces"></a>
## 対照群 K3 4字下げの下位箇条書き { #k3-sub-bullets-4-spaces }

<!-- 합성 대조군 -->

1. 設定方式を選択します。
    * **全体**:すべての対象に同じ値を使います。
    * **個別**:対象ごとに値を入力します。
2. **確認**をクリックします。
