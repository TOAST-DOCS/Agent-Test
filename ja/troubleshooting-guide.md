<!-- machine_translated: true -->

<!-- pre-align:aligned sig=45e098944fc5 -->

<a id="compute-instance-troubleshooting-guide"></a>
## Compute > Instance > 問題解決ガイド { #compute-instance-troubleshooting-guide }

NHN Cloud を使用する際に発生する可能性があるさまざまな問題の解決方法を説明します。

<h3>現在 NHN Cloud で提供されている OS バージョン以外のバージョンを使用したいのですが、個人イメージをアップロードして使用することはできますか？</h3>

NHN Cloud で提供されている OS バージョンのみを利用できます。個人イメージのアップロードはサポートされていません。
個人 OS イメージを使用する場合は、NHN Cloud で提供されているイメージを使用してインスタンスを作成してから、**[イメージ作成]** 機能を使用することをお勧めします。
<br>

<h3>インスタンスにアクセスすると「Permissions 0644 for '/Users/username/.ssh/your-key.pem' are too open.」メッセージが表示され、アクセスできません。</h3>

インスタンスへのアクセスに使用するキーペアの秘密鍵（PEM 鍵）のアクセス許可が正しくないために発生する問題です。
以下のように秘密鍵ファイルのアクセス許可を調整します。

    $ chmod 600 your-key.pem
<br>

<h3>CentOS インスタンスで root アクセス許可を取得するにはどうすればよいですか？</h3>

CentOS インスタンスで root アクセス許可を取得するには、以下のように `sudo` コマンドを使用します。

    $ sudo su
<br>

<h3>個人イメージを作成してインスタンスを作成し、起動したのですがマウント（mount）エラーが発生します。</h3>

2 つ以上のブロックストレージを使用するインスタンスからイメージを作成し、作成したイメージを使用してインスタンスを作成し、起動するとこのような問題が発生します。

2 つ以上のブロックストレージを使用するインスタンスは、デフォルトディスク以外のディスクを `/etc/fstab` ファイルで設定します。イメージ作成時にこのファイルも複製されるため、新しいインスタンスが起動する際に `/etc/fstab` ファイルが参照するブロックストレージが存在しないため、マウントエラーが発生します。

この問題を解決するには、`/etc/fstab` ファイルでデフォルトディスク以外のブロックストレージ設定をコメントアウトしてイメージを作成する必要があります。
<br>
<br>

<h3>SSH アクセスが遅すぎます。</h3>

インスタンスが属するセキュリティグループの送信ルールで DNS がブロックされている場合に発生します。DNS の送信ができるようにセキュリティグループを調整します。
<br>
<br>

<h3>「Could not resolve the host」メッセージが表示され、yum などが使用できません。</h3>

インスタンスが属するセキュリティグループの送信ルールで DNS がブロックされている場合に発生します。DNS の送信ができるようにセキュリティグループを調整します。
<br>
<br>

<a id="proxy-instance-issue">
<h3>プロキシを使用するインスタンスの動作が異常です。</h3>
</a>

プロキシを使用するインスタンスでは、NHN Cloud の Monitoring サービス（System Monitoring、Service Monitoring、Cloud Monitoring）が正常に動作しない場合があります。また、Windows オペレーティングシステムの場合、パスワードリセットなどの問題が発生する可能性があります。

このような問題を回避するには、プロキシを使用するインスタンスで `169.254.0.0/16` 範囲に対してはプロキシを使用しないように設定する必要があります。通常は `no_proxy` という環境変数にこの値を設定しますが、使用しているプロキシによってはこの環境変数を無視する場合もあるため、使用しているプロキシのガイドを参照して設定することをお勧めします。
<br>
<br>

<h3>CentOS インスタンスでパッケージ更新に失敗します。</h3>

以下のように `yum repository` ファイルを編集して使用します。
公式サポートが終了した OS は追加の更新がサポートされていないため、より新しいバージョンの OS の使用をお勧めします。

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