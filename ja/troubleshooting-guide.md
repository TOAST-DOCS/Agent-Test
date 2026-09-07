<!-- machine_translated: true -->

<!-- pre-align:aligned sig=45e098944fc5 -->

<a id="compute-instance-troubleshooting-guide"></a>
## Compute > Instance > トラブルシューティング ガイド { #compute-instance-troubleshooting-guide }

NHN Cloud を使用する際に発生する可能性のあるさまざまな問題の解決方法を説明します。

<h3>NHN Cloud で提供されている OS バージョン以外を使用したいです。個人イメージをアップロードして使用することはできませんか?</h3>

NHN Cloud で提供されている OS バージョンのみを利用できます。個人イメージのアップロードはサポートされていません。
個人 OS イメージを使用する場合は、NHN Cloud で提供されているイメージを使用してインスタンスを作成してから、**イメージの作成**機能を使用してください。
<br>

<h3>インスタンスに接続するときに「Permissions 0644 for '/Users/username/.ssh/your-key.pem' are too open.」メッセージが表示され、接続できません。</h3>

インスタンス接続に使用するキー ペアの秘密鍵 (PEM キー) の権限が正しくないために発生する問題です。
次のように秘密鍵ファイルの権限を調整します。

    $ chmod 600 your-key.pem
<br>

<h3>CentOS インスタンスで root 権限を取得するにはどうすればよいですか?</h3>

CentOS インスタンスで root 権限を取得するには、次のように `sudo` コマンドを使用します。

    $ sudo su
<br>

<h3>個人イメージを作成してインスタンスを作成し、起動しましたがマウント エラーが発生します。</h3>

2 つ以上のブロックストレージを使用するインスタンスからイメージを作成し、そのイメージを使用してインスタンスを作成して起動すると、このような問題が発生します。

2 つ以上のブロックストレージを使用するインスタンスは、基本ディスク以外のディスクを `/etc/fstab` ファイルに設定します。イメージ作成時にこのファイルも複製されるため、新しいインスタンスが起動するとき、`/etc/fstab` ファイルが参照するブロックストレージが存在しないため、マウント エラーが発生します。

この問題を解決するには、`/etc/fstab` ファイルで基本ディスク以外のブロックストレージ設定をコメント アウトしてからイメージを作成する必要があります。
<br>
<br>

<h3>SSH 接続が非常に遅いです。</h3>

インスタンスが属するセキュリティ グループの送信部分で DNS がブロックされている場合に発生します。DNS 送信ができるようにセキュリティ グループを調整します。
<br>
<br>

<h3>「Could not resolve the host」メッセージが表示され、yum などが使用できません。</h3>

インスタンスが属するセキュリティ グループの送信部分で DNS がブロックされている場合に発生します。DNS 送信ができるようにセキュリティ グループを調整します。
<br>
<br>

<a id="proxy-instance-issue">
<h3>プロキシを使用するインスタンスでの動作が異常です。</h3>
</a>

プロキシを使用するインスタンスでは、NHN Cloud のモニタリング サービス (System Monitoring、Service Monitoring、Cloud Monitoring) が正常に機能しない場合があります。また、Windows オペレーティング システムの場合、パスワード リセットなどの問題が発生する可能性があります。

このような問題を回避するには、プロキシを使用するインスタンスで `169.254.0.0/16` 範囲に対してプロキシを使用しないように設定する必要があります。通常、`no_proxy` という環境変数にこの値を設定しますが、使用するプロキシによってはこの環境変数を無視する場合もあるため、使用するプロキシのガイドを参照して設定してください。
<br>
<br>

<h3>CentOS インスタンスでパッケージ アップデートが失敗します。</h3>

次のように `yum repository` ファイルを変更して使用します。
公式サポートが終了した OS は追加アップデートがサポートされていないため、上位バージョンの OS の使用をお勧めします。

<h4>CentOS 6.x</h4>

```
$ sudo vi /etc/yum.repos.d/CentOS-Base.repo

[base]
...
#mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=os&infra=$infra&cc=$cc
#baseurl=http://mirror.centos.org/centos/$releasever/os/$basearch/
baseurl=https://vault.centos.org/6.10/os/$basearch/
...

[updates]
...
#mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=updates&infra=$infra&cc=$cc
#baseurl=http://mirror.centos.org/centos/$releasever/updates/$basearch/
baseurl=https://vault.centos.org/6.10/updates/$basearch/
...

[extras]
...
#mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=extras&infra=$infra&cc=$cc
#baseurl=http://mirror.centos.org/centos/$releasever/extras/$basearch/
baseurl=https://vault.centos.org/6.10/extras/$basearch/
...

```

<h4>CentOS 7.x</h4>

```

$ sudo vi /etc/yum.repos.d/CentOS-Base.repo

[base]
...
#mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=os&infra=$infra&cc=$cc
#baseurl=http://mirror.centos.org/centos/$releasever/os/$basearch/
baseurl=https://vault.centos.org/7.9.2009/os/$basearch/
...

[updates]
...
#mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=updates&infra=$infra&cc=$cc
#baseurl=http://mirror.centos.org/centos/$releasever/updates/$basearch/
baseurl=https://vault.centos.org/7.9.2009/updates/$basearch/
...

[extras]
...
#mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=extras&infra=$infra&cc=$cc
#baseurl=http://mirror.centos.org/centos/$releasever/extras/$basearch/
baseurl=https://vault.centos.org/7.9.2009/extras/$basearch/
...

[centosplus]
...
#mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=centosplus&infra=$infra&cc=$cc
#baseurl=http://mirror.centos.org/centos/$releasever/centosplus/$basearch/
baseurl=https://vault.centos.org/7.9.2009/centosplus/$basearch/
...
```

<h4>共通</h4>

```
$ sudo yum clean all
$ sudo yum repolist
```

<br>
<br>