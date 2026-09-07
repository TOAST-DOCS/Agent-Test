<!-- machine_translated: true -->

<!-- pre-align:aligned sig=73ceeadcb5ee -->

<a id="compute-instance-kernel-version-upgrade-guide"></a>
## Compute > Instance > カーネルバージョンアップガイド { #compute-instance-kernel-version-upgrade-guide }

> [注意]
> カーネル更新時に OS が破損したり、起動に失敗したりする可能性があり、その結果についての責任はユーザーにあります。

<a id="rocky-linux-8"></a>
## Rocky Linux 8 { #rocky-linux-8 }

<a id="check-the-kernel-version"></a>
### カーネルバージョン確認 { #check-the-kernel-version }

現在インストールされているカーネルバージョンを確認します。

```
[root@rocky810 ~]# uname -r
4.18.0-553.8.1.el8_10.x86_64
```

<a id="default-storage-settings"></a>
### デフォルトリポジトリ設定 { #default-storage-settings }

システムアーキテクチャと Rocky Linux バージョンに合わせてデフォルトリポジトリを変更します。

```
[baseos]
name=Rocky Linux $releasever - BaseOS
mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=$basearch&repo=BaseOS-$releasever
#baseurl=http://dl.rockylinux.org/$contentdir/$releasever/BaseOS/$basearch/os/
gpgcheck=1
enabled=1
countme=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rockyofficial
```

* **名前**
  * リポジトリの名前で、変更しても問題ありません。
* **mirrorlist**
  * パッケージをダウンロードできるミラーサーバーリストを提供する URL を指定します。
  * システムのアーキテクチャ(`$basearch`)と Rocky Linux バージョン(`$releasever`)に合わせてミラーサーバーリストを取得します。
* **baseurl**
  * パッケージをダウンロードするためのベース URL を指定します。この URL は単一のサーバーを指し、そのサーバーから直接パッケージをダウンロードします。
* **gpgcheck**
  * GPG(GNU Privacy Guard) キーが含まれているリポジトリの URL またはパスを設定します。GPG キーは rpm パッケージを認証するために使用される暗号化署名です。

> [注記]
> **mirrorlist** と **baseurl** の両方が設定されている場合、**mirrorlist** が優先的に適用され、**baseurl** はフォールバックオプションとして機能します。

<a id="clear-the-cache-before-updating"></a>
### 更新前のキャッシュ削除 { #clear-the-cache-before-updating }

既存のダウンロード済みパッケージのメタデータが保存されたキャッシュを削除します。

```
[root@rocky810 ~]# rm -rf /var/cache/dnf
```

<a id="install-the-kernel"></a>
### カーネルインストール { #install-the-kernel }

<a id="install-the-kernel-by-specifying-a-version"></a>
#### バージョンを指定してカーネルをインストール

> [注記]
> Rocky Linux パッケージ 8.8 以下のバージョンはサポートされていません。

```
[root@rocky810 ~]# dnf --releasever=8.10 list kernel*

Installed Packages
kernel.x86_64                                                                                4.18.0-477.27.1.el8_8                                                             @baseos
kernel-core.x86_64                                                                           4.18.0-477.27.1.el8_8                                                             @baseos
kernel-modules.x86_64                                                                        4.18.0-477.27.1.el8_8                                                             @baseos
kernel-tools.x86_64                                                                          4.18.0-477.27.1.el8_8                                                             @baseos
kernel-tools-libs.x86_64                                                                     4.18.0-477.27.1.el8_8                                                             @baseos
Available Packages
kernel.x86_64                                                                                4.18.0-553.16.1.el8_10                                                            baseos
kernel-abi-stablelists.noarch                                                                4.18.0-553.16.1.el8_10                                                            baseos
kernel-core.x86_64                                                                           4.18.0-553.16.1.el8_10                                                            baseos
kernel-cross-headers.x86_64                                                                  4.18.0-553.16.1.el8_10                                                            baseos
kernel-debug.x86_64                                                                          4.18.0-553.16.1.el8_10                                                            baseos
kernel-debug-core.x86_64                                                                     4.18.0-553.16.1.el8_10                                                            baseos
kernel-debug-devel.x86_64                                                                    4.18.0-553.16.1.el8_10                                                            baseos
kernel-debug-modules.x86_64                                                                  4.18.0-553.16.1.el8_10                                                            baseos
kernel-debug-modules-extra.x86_64                                                            4.18.0-553.16.1.el8_10                                                            baseos
kernel-devel.x86_64                                                                          4.18.0-553.16.1.el8_10                                                            baseos
kernel-doc.noarch                                                                            4.18.0-553.16.1.el8_10                                                            baseos
kernel-headers.x86_64                                                                        4.18.0-553.16.1.el8_10                                                            baseos
kernel-modules.x86_64                                                                        4.18.0-553.16.1.el8_10                                                            baseos
kernel-modules-extra.x86_64                                                                  4.18.0-553.16.1.el8_10                                                            baseos
kernel-rpm-macros.noarch                                                                     131-1.el8                                                                         appstream
kernel-tools.x86_64                                                                          4.18.0-553.16.1.el8_10                                                            baseos
kernel-tools-libs.x86_64                                                                     4.18.0-553.16.1.el8_10                                                            baseos
kernelshark.x86_64
```

<a id="install-the-kernel-without-specifying-a-version"></a>
#### バージョンを指定せずにカーネルをインストール
バージョンを指定しない場合、major バージョンの最新バージョンを基準としてパッケージを検索します。

```
[root@rocky810 ~]# dnf list kernel*

kernel.x86_64                                                                                4.18.0-477.27.1.el8_8                                                             @baseos
kernel-core.x86_64                                                                           4.18.0-477.27.1.el8_8                                                             @baseos
kernel-modules.x86_64                                                                        4.18.0-477.27.1.el8_8                                                             @baseos
kernel-tools.x86_64                                                                          4.18.0-477.27.1.el8_8                                                             @baseos
kernel-tools-libs.x86_64                                                                     4.18.0-477.27.1.el8_8                                                             @baseos
Available Packages
kernel.x86_64                                                                                4.18.0-553.16.1.el8_10                                                            baseos
kernel-abi-stablelists.noarch                                                                4.18.0-553.16.1.el8_10                                                            baseos
kernel-core.x86_64                                                                           4.18.0-553.16.1.el8_10                                                            baseos
kernel-cross-headers.x86_64                                                                  4.18.0-553.16.1.el8_10                                                            baseos
kernel-debug.x86_64                                                                          4.18.0-553.16.1.el8_10                                                            baseos
kernel-debug-core.x86_64                                                                     4.18.0-553.16.1.el8_10                                                            baseos
kernel-debug-devel.x86_64                                                                    4.18.0-553.16.1.el8_10                                                            baseos
kernel-debug-modules.x86_64                                                                  4.18.0-553.16.1.el8_10                                                            baseos
kernel-debug-modules-extra.x86_64                                                            4.18.0-553.16.1.el8_10                                                            baseos
kernel-devel.x86_64                                                                          4.18.0-553.16.1.el8_10                                                            baseos
kernel-doc.noarch                                                                            4.18.0-553.16.1.el8_10                                                            baseos
kernel-headers.x86_64                                                                        4.18.0-553.16.1.el8_10                                                            baseos
kernel-modules.x86_64                                                                        4.18.0-553.16.1.el8_10                                                            baseos
kernel-modules-extra.x86_64                                                                  4.18.0-553.16.1.el8_10                                                            baseos
kernel-rpm-macros.noarch                                                                     131-1.el8                                                                         appstream
kernel-tools.x86_64                                                                          4.18.0-553.16.1.el8_10                                                            baseos
kernel-tools-libs.x86_64                                                                     4.18.0-553.16.1.el8_10                                                            baseos
kernelshark.x86_64
```


<a id="install-the-kernel-install-the-latest-kernel"></a>
#### 最新カーネルをインストール
別途のバージョンを指定しない場合、最新バージョンでインストールします。

カーネルをインストールすると、依存パッケージの **kernel-core** と **kernel-modules** も一緒にインストールします。

```
[root@rocky810 ~]# dnf install kernel
Last metadata expiration check: 0:21:59 ago on Tue 10 Sep 2024 04:44:04 PM KST.
Dependencies resolved.
========================================================================================================================================================================================
 Package                                       Architecture                          Version                                                Repository                             Size
========================================================================================================================================================================================
Installing:
 kernel                                        x86_64                                4.18.0-553.16.1.el8_10                                 baseos                                 10 M
Installing dependencies:
 kernel-core                                   x86_64                                4.18.0-553.16.1.el8_10                                 baseos                                 43 M
 kernel-modules                                x86_64                                4.18.0-553.16.1.el8_10                                 baseos                                 36 M

Transaction Summary
========================================================================================================================================================================================
Install  3 Packages

Total download size: 90 M
Installed size: 96 M
Is this ok [y/N]: y

...
...
...

Installed:
  kernel-4.18.0-553.16.1.el8_10.x86_64            kernel-core-4.18.0-553.16.1.el8_10.x86_64            kernel-modules-4.18.0-553.16.1.el8_10.x86_64

Complete!
```


<a id="install-the-kernel-check-package-installation"></a>
#### パッケージのインストール確認

カーネルパッケージが正常にインストールされたかどうかを確認します。

```
[root@rocky810 ~]# dnf list installed | grep -iE "kernel.*4.18.0-553.16"
kernel.x86_64                         4.18.0-553.16.1.el8_10                    @baseos
kernel-core.x86_64                    4.18.0-553.16.1.el8_10                    @baseos
kernel-modules.x86_64                 4.18.0-553.16.1.el8_10                    @baseos
```

<a id="reboot-the-os"></a>
### OS 再起動 { #reboot-the-os }

カーネルアップデートを適用するために、OS を再起動します。

```
[root@rocky810 ~]# sync; reboot
```

<a id="select-create-a-configuration-file-for-the-grub2-bootloader"></a>
### <span style="color:#e11d21;">**[選択]**</span> GRUB2 ブートローダーの設定ファイルの生成 { #select-create-a-configuration-file-for-the-grub2-bootloader }
システムのブートメニューを更新して、新しくインストールされたカーネルやその他のブート項目を反映します。

dnf、yum は自動的に GRUB2 設定ファイルを更新します。

```
[root@rocky810 ~]# grub2-mkconfig -o /etc/grub2.cfg
```

<a id="select-create-a-configuration-file-for-the-grub2-bootloader-check-for-kernel-updates"></a>
#### カーネルアップデートの確認

カーネルバージョンが正常に更新されたかどうかを確認します。

```
[root@rocky810 ~]# uname -r
4.18.0-553.16.1.el8_10.x86_64
```

<a id="change-the-kernel-boot-order"></a>
### カーネルのブート順序を変更する { #change-the-kernel-boot-order }

複数のカーネルがインストールされている場合、目的のカーネルでブートできるようにブート順序を変更します。

<a id="change-the-kernel-boot-order-rocky-versions-below-810"></a>
#### Rocky 8.10 より前のバージョン

##### デフォルトカーネルの確認

現在のデフォルト設定されたカーネルを確認します。

```
[root@rocky810 ~]# grubby --default-kernel
/boot/vmlinuz-4.18.0-553.16.1.el8_10.x86_64
```

##### 現在インストールされているカーネルの一覧

現在インストールされているカーネルの一覧を確認します。

```
[root@rocky810 ~]# grubby --info=ALL | grep ^kernel | grep -v rescue
kernel="/boot/vmlinuz-4.18.0-553.el8_10.x86_64"
kernel="/boot/vmlinuz-4.18.0-553.16.1.el8_10.x86_64"
kernel="/boot/vmlinuz-4.18.0-553.8.1.el8_10.x86_64"
```

##### デフォルトカーネルを変更する

現在インストールされているカーネルの一覧からいずれかを選択して、デフォルトカーネルを変更します。

```
[root@rocky810 ~]# grubby --set-default="/boot/vmlinuz-4.18.0-553.8.1.el8_10.x86_64"
The default is /boot/loader/entries/ea5b6e1e7bc09da25505ebb3a26a8bf4-4.18.0-553.8.1.el8_10.x86_64.conf with index 4 and kernel /boot/vmlinuz-4.18.0-553.8.1.el8_10.x86_64
[root@rocky810 ~]# grubby --default-kernel
/boot/vmlinuz-4.18.0-553.8.1.el8_10.x86_64
```

##### OS の再起動

ブート順序の変更を適用するために OS を再起動します。

```
[root@rocky810 ~]# sync; reboot
```

<a id="change-the-kernel-boot-order-rocky-810-and-later-versions"></a>
#### Rocky 8.10 以降のバージョン

現在、Rocky 8.10 公式イメージでは grubby コマンドでカーネルの変更ができない問題があるため、以下のシェルスクリプトを使用します。

```bash
#!/bin/bash

result=1
kernel_list=(` rpm -qa | grep ^kernel-[0-9] | sort `)

echo -e "\n# Choose the kernel you want from the list below. #"
echo "------------------------------------------------"
for index in ${!kernel_list[@]}; do
    echo "Num: $index,  ${kernel_list[$index]}"
done
echo "------------------------------------------------"
read -p "index: " kernel_index

for index in ${!kernel_list[@]}; do
    if [[ "$index" -eq "$kernel_index" ]]; then
        sed -i "s/GRUB_DEFAULT=[^ ]*/GRUB_DEFAULT=$kernel_index/" /etc/default/grub && result=0
        grub2-mkconfig -o /etc/grub2.cfg
    fi
done

if [[ "$result" -eq "1" ]]; then
    echo "[Error] Please choose only from the indexes in the list"
fi
```

##### スクリプト使用方法

シェルスクリプト実行後に出力されるカーネルの一覧からブートするカーネルの番号を入力します。

```
[root@rocky810 ~]# bash kernel_select.sh

# Choose the kernel you want from the list below. #
------------------------------------------------
Num: 0,  kernel-4.18.0-553.16.1.el8_10.x86_64
Num: 1,  kernel-4.18.0-553.8.1.el8_10.x86_64
Num: 2,  kernel-4.18.0-553.el8_10.x86_64
------------------------------------------------
index: 0
Generating grub configuration file ...
done
```

##### OS の再起動

ブート順序の変更を適用するために OS を再起動します。

```
[root@rocky810 ~]# sync; reboot
```

<a id="rocky-linux-9"></a>
## Rocky Linux 9 { #rocky-linux-9 }

<a id="rocky-linux-9-check-the-kernel-version"></a>
### カーネルバージョンの確認 { #rocky-linux-9-check-the-kernel-version }

現在インストールされているカーネルバージョンを確認します。

```
[rocky@rocky95 ~]$ uname -r
5.14.0-503.14.1.el9_5.x86_64
```

<a id="rocky-linux-9-default-storage-settings"></a>
### デフォルトリポジトリ設定 { #rocky-linux-9-default-storage-settings }

システムアーキテクチャと Rocky Linux バージョンに合わせてデフォルトリポジトリを変更します。

```
[baseos]
name=Rocky Linux $releasever - BaseOS
mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=$basearch&repo=BaseOS-$releasever$rltype
#baseurl=http://dl.rockylinux.org/$contentdir/$releasever/BaseOS/$basearch/os/
gpgcheck=1
enabled=1
countme=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-9
```

* **name**
  * リポジトリの名前です。変更しても問題ありません。
* **mirrorlist**
  * パッケージをダウンロードできるミラーサーバーの一覧を提供する URL を指定します。
  * システムのアーキテクチャ（`$basearch`）と Rocky Linux バージョン（`$releasever`）に合わせてミラーサーバーの一覧を取得します。
* **baseurl**
  * パッケージをダウンロードするベース URL を指定します。この URL は単一のサーバーを指し、そのサーバーから直接パッケージをダウンロードします。
* **gpgcheck**
  * GPG (GNU Privacy Guard) キーを含むリポジトリの URL またはパスを設定します。GPG キーは rpm パッケージを認証するために使用される暗号化署名です。
* **enabled**
  * このリポジトリを有効にするかどうかを設定します。
  * 値が 1 の場合は有効、0 の場合は無効です。
* **countme**
  * Rocky Linux の使用統計を収集する機能です。
  * 値が 1 の場合、Rocky Linux プロジェクトのユーザーがどのくらい多いかを把握できます。
* **metadata_expire**
  * dnf がリポジトリのメタデータ（パッケージリストなど）を特定の期間（例では 6 時間）で更新するように設定します。
* **gpgkey**
  * パッケージ署名を検証する GPG キーファイルのパスです。

> [注記]
> **mirrorlist** と **baseurl** が両方設定されている場合、**mirrorlist** が優先適用され、**baseurl** は代替オプションとして機能します。

<a id="rocky-linux-9-clear-the-cache-before-updating"></a>
### 更新前のキャッシュ削除 { #rocky-linux-9-clear-the-cache-before-updating }

既にダウンロードされたパッケージのメタデータが保存されたキャッシュを削除します。


```
[root@rocky95 ~]# rm -rf /var/cache/dnf
```

<a id="rocky-linux-9-install-the-kernel"></a>
### カーネルのインストール { #rocky-linux-9-install-the-kernel }

<a id="rocky-linux-9-install-the-kernel-install-the-kernel-by-specifying-a-version"></a>
#### バージョンを指定してカーネルをインストール

> [注記]
> 現在、Rocky Linux 9 パッケージは バージョン 9.5 のみ利用可能です。


```
[root@rocky95 ~]# dnf --releasever=9.5 list kernel*

Rocky Linux 9.5 - BaseOS                                                                                           1.7 MB/s | 2.3 MB     00:01
Rocky Linux 9.5 - AppStream                                                                                        7.2 MB/s | 8.6 MB     00:01
Rocky Linux 9.5 - Extras                                                                                            12 kB/s |  16 kB     00:01
Installed Packages
kernel.x86_64                                                              5.14.0-503.14.1.el9_5                                          @baseos
kernel.x86_64                                                              5.14.0-503.22.1.el9_5                                          @baseos
kernel-core.x86_64                                                         5.14.0-503.14.1.el9_5                                          @baseos
kernel-core.x86_64                                                         5.14.0-503.22.1.el9_5                                          @baseos
kernel-modules.x86_64                                                      5.14.0-503.14.1.el9_5                                          @baseos
kernel-modules.x86_64                                                      5.14.0-503.22.1.el9_5                                          @baseos
kernel-modules-core.x86_64                                                 5.14.0-503.14.1.el9_5                                          @baseos
kernel-modules-core.x86_64                                                 5.14.0-503.22.1.el9_5                                          @baseos
kernel-tools.x86_64                                                        5.14.0-503.22.1.el9_5                                          @baseos
kernel-tools-libs.x86_64                                                   5.14.0-503.22.1.el9_5                                          @baseos
Available Packages
kernel.x86_64                                                              5.14.0-503.23.2.el9_5                                          baseos
kernel-abi-stablelists.noarch                                              5.14.0-503.23.2.el9_5                                          baseos
kernel-core.x86_64                                                         5.14.0-503.23.2.el9_5                                          baseos
kernel-debug.x86_64                                                        5.14.0-503.23.2.el9_5                                          baseos
kernel-debug-core.x86_64                                                   5.14.0-503.23.2.el9_5                                          baseos
kernel-debug-devel.x86_64                                                  5.14.0-503.23.2.el9_5                                          appstream
kernel-debug-devel-matched.x86_64                                          5.14.0-503.23.2.el9_5                                          appstream
kernel-debug-modules.x86_64                                                5.14.0-503.23.2.el9_5                                          baseos
kernel-debug-modules-core.x86_64                                           5.14.0-503.23.2.el9_5                                          baseos
kernel-debug-modules-extra.x86_64                                          5.14.0-503.23.2.el9_5                                          baseos
kernel-debug-uki-virt.x86_64                                               5.14.0-503.23.2.el9_5                                          baseos
kernel-devel.x86_64                                                        5.14.0-503.23.2.el9_5                                          appstream
kernel-devel-matched.x86_64                                                5.14.0-503.23.2.el9_5                                          appstream
kernel-doc.noarch                                                          5.14.0-503.23.2.el9_5                                          appstream
kernel-headers.x86_64                                                      5.14.0-503.23.2.el9_5                                          appstream
kernel-modules.x86_64                                                      5.14.0-503.23.2.el9_5                                          baseos
kernel-modules-core.x86_64                                                 5.14.0-503.23.2.el9_5                                          baseos
kernel-modules-extra.x86_64                                                5.14.0-503.23.2.el9_5                                          baseos
kernel-rpm-macros.noarch                                                   185-13.el9                                                     appstream
kernel-srpm-macros.noarch                                                  1.0-13.el9                                                     appstream
kernel-tools.x86_64                                                        5.14.0-503.23.2.el9_5                                          baseos
kernel-tools-libs.x86_64                                                   5.14.0-503.23.2.el9_5                                          baseos
kernel-uki-virt.x86_64                                                     5.14.0-503.23.2.el9_5                                          baseos
kernel-uki-virt-addons.x86_64                                              5.14.0-503.23.2.el9_5                                          baseos
kernelshark.x86_64                                                         1:1.2-10.el9                                                   appstream
```

<a id="rocky-linux-9-install-the-kernel-install-the-kernel-without-specifying-a-version"></a>
#### バージョン指定なしでカーネルをインストール
バージョンを指定しないと、メジャーバージョンの最新バージョンを基準にパッケージを検索します。

```
[root@rocky95 ~]# dnf list kernel*

Rocky Linux 9 - BaseOS                                                                                             2.2 MB/s | 2.3 MB     00:01
Rocky Linux 9 - AppStream                                                                                          7.8 MB/s | 8.6 MB     00:01
Rocky Linux 9 - Extras                                                                                              12 kB/s |  16 kB     00:01
Installed Packages
kernel.x86_64                                                              5.14.0-503.14.1.el9_5                                          @baseos
kernel.x86_64                                                              5.14.0-503.22.1.el9_5                                          @baseos
kernel-core.x86_64                                                         5.14.0-503.14.1.el9_5                                          @baseos
kernel-core.x86_64                                                         5.14.0-503.22.1.el9_5                                          @baseos
kernel-modules.x86_64                                                      5.14.0-503.14.1.el9_5                                          @baseos
kernel-modules.x86_64                                                      5.14.0-503.22.1.el9_5                                          @baseos
kernel-modules-core.x86_64                                                 5.14.0-503.14.1.el9_5                                          @baseos
kernel-modules-core.x86_64                                                 5.14.0-503.22.1.el9_5                                          @baseos
kernel-tools.x86_64                                                        5.14.0-503.22.1.el9_5                                          @baseos
kernel-tools-libs.x86_64                                                   5.14.0-503.22.1.el9_5                                          @baseos
Available Packages
kernel.x86_64                                                              5.14.0-503.23.2.el9_5                                          baseos
kernel-abi-stablelists.noarch                                              5.14.0-503.23.2.el9_5                                          baseos
kernel-core.x86_64                                                         5.14.0-503.23.2.el9_5                                          baseos
kernel-debug.x86_64                                                        5.14.0-503.23.2.el9_5                                          baseos
kernel-debug-core.x86_64                                                   5.14.0-503.23.2.el9_5                                          baseos
kernel-debug-devel.x86_64                                                  5.14.0-503.23.2.el9_5                                          appstream
kernel-debug-devel-matched.x86_64                                          5.14.0-503.23.2.el9_5                                          appstream
kernel-debug-modules.x86_64                                                5.14.0-503.23.2.el9_5                                          baseos
kernel-debug-modules-core.x86_64                                           5.14.0-503.23.2.el9_5                                          baseos
kernel-debug-modules-extra.x86_64                                          5.14.0-503.23.2.el9_5                                          baseos
kernel-debug-uki-virt.x86_64                                               5.14.0-503.23.2.el9_5                                          baseos
kernel-devel.x86_64                                                        5.14.0-503.23.2.el9_5                                          appstream
kernel-devel-matched.x86_64                                                5.14.0-503.23.2.el9_5                                          appstream
kernel-doc.noarch                                                          5.14.0-503.23.2.el9_5                                          appstream
kernel-headers.x86_64                                                      5.14.0-503.23.2.el9_5                                          appstream
kernel-modules.x86_64                                                      5.14.0-503.23.2.el9_5                                          baseos
kernel-modules-core.x86_64                                                 5.14.0-503.23.2.el9_5                                          baseos
kernel-modules-extra.x86_64                                                5.14.0-503.23.2.el9_5                                          baseos
kernel-rpm-macros.noarch                                                   185-13.el9                                                     appstream
kernel-srpm-macros.noarch                                                  1.0-13.el9                                                     appstream
kernel-tools.x86_64                                                        5.14.0-503.23.2.el9_5                                          baseos
kernel-tools-libs.x86_64                                                   5.14.0-503.23.2.el9_5                                          baseos
kernel-uki-virt.x86_64                                                     5.14.0-503.23.2.el9_5                                          baseos
kernel-uki-virt-addons.x86_64                                              5.14.0-503.23.2.el9_5                                          baseos
kernelshark.x86_64                                                         1:1.2-10.el9                                                   appstream
```

<a id="rocky-linux-9-install-the-kernel-install-the-latest-kernel"></a>
#### 最新カーネルをインストール
バージョンを指定しない場合、最新バージョンをインストールします。

カーネルをインストールすると、依存パッケージの **kernel-core** と **kernel-modules** も一緒にインストールされます。

```
[root@rocky95 ~]# dnf install kernel
Last metadata expiration check: 0:00:47 ago on Wed 19 Feb 2025 02:26:50 PM KST.
Dependencies resolved.
===================================================================================================================================================
 Package                                  Architecture                Version                                    Repository                   Size
===================================================================================================================================================
Installing:
 kernel                                   x86_64                      5.14.0-503.23.2.el9_5                      baseos                      2.0 M
 kernel-core                              x86_64                      5.14.0-503.23.2.el9_5                      baseos                       18 M
Installing dependencies:
 kernel-modules                           x86_64                      5.14.0-503.23.2.el9_5                      baseos                       36 M
 kernel-modules-core                      x86_64                      5.14.0-503.23.2.el9_5                      baseos                       30 M

Transaction Summary
===================================================================================================================================================
Install  4 Packages

Total download size: 86 M
Installed size: 126 M
Is this ok [y/N]: y
Downloading Packages:
(1/4): kernel-core-5.14.0-503.23.2.el9_5.x86_64.rpm                                                                 14 MB/s |  18 MB     00:01
(2/4): kernel-5.14.0-503.23.2.el9_5.x86_64.rpm                                                                      32 MB/s | 2.0 MB     00:00
(3/4): kernel-modules-core-5.14.0-503.23.2.el9_5.x86_64.rpm                                                         14 MB/s |  30 MB     00:02
(4/4): kernel-modules-5.14.0-503.23.2.el9_5.x86_64.rpm                                                              12 MB/s |  36 MB     00:03
---------------------------------------------------------------------------------------------------------------------------------------------------
Total                                                                                                               24 MB/s |  86 MB     00:03
Running transaction check
Transaction check succeeded.
Running transaction test
Transaction test succeeded.
Running transaction
  Preparing        :                                                                                                                           1/1
  Installing       : kernel-core-5.14.0-503.23.2.el9_5.x86_64                                                                                  1/4
  Running scriptlet: kernel-core-5.14.0-503.23.2.el9_5.x86_64                                                                                  1/4
  Installing       : kernel-modules-core-5.14.0-503.23.2.el9_5.x86_64                                                                          2/4
  Installing       : kernel-modules-5.14.0-503.23.2.el9_5.x86_64                                                                               3/4
  Running scriptlet: kernel-modules-5.14.0-503.23.2.el9_5.x86_64                                                                               3/4
  Installing       : kernel-5.14.0-503.23.2.el9_5.x86_64                                                                                       4/4
  Running scriptlet: kernel-core-5.14.0-503.23.2.el9_5.x86_64                                                                                  4/4
  Running scriptlet: kernel-modules-core-5.14.0-503.23.2.el9_5.x86_64                                                                          4/4
  Running scriptlet: kernel-modules-5.14.0-503.23.2.el9_5.x86_64                                                                               4/4
  Running scriptlet: kernel-5.14.0-503.23.2.el9_5.x86_64                                                                                       4/4
  Verifying        : kernel-modules-core-5.14.0-503.23.2.el9_5.x86_64                                                                          1/4
  Verifying        : kernel-modules-5.14.0-503.23.2.el9_5.x86_64                                                                               2/4
  Verifying        : kernel-core-5.14.0-503.23.2.el9_5.x86_64                                                                                  3/4
  Verifying        : kernel-5.14.0-503.23.2.el9_5.x86_64                                                                                       4/4

Installed:
  kernel-5.14.0-503.23.2.el9_5.x86_64                  kernel-core-5.14.0-503.23.2.el9_5.x86_64     kernel-modules-5.14.0-503.23.2.el9_5.x86_64
  kernel-modules-core-5.14.0-503.23.2.el9_5.x86_64

Complete!
```



<a id="rocky-linux-9-install-the-kernel-check-package-installation"></a>
#### パッケージ インストールの確認

カーネル パッケージが正常にインストールされたことを確認します。

```
[root@rocky95 ~]# dnf list installed | grep -i "5.14.0-503.23.2"
kernel.x86_64                          5.14.0-503.23.2.el9_5          @baseos
kernel-core.x86_64                     5.14.0-503.23.2.el9_5          @baseos
kernel-modules.x86_64                  5.14.0-503.23.2.el9_5          @baseos
kernel-modules-core.x86_64             5.14.0-503.23.2.el9_5          @baseos
```

<a id="rocky-linux-9-reboot-the-os"></a>
### OS を再起動 { #rocky-linux-9-reboot-the-os }

カーネル更新を適用するために OS を再起動します。

```
[root@rocky95 ~]# sync; reboot
```

<a id="rocky-linux-9-select-create-a-configuration-file-for-the-grub2-bootloader"></a>
### <span style="color:#e11d21;">**[オプション]**</span> GRUB2 ブートローダーの設定ファイルを作成 { #rocky-linux-9-select-create-a-configuration-file-for-the-grub2-bootloader }
システムのブート メニューを更新して、新しくインストールされたカーネルまたは他のブート項目を反映します。

dnf と yum は GRUB2 設定ファイルを自動的に更新します。

```
[root@rocky95 ~]# grub2-mkconfig -o /etc/grub2.cfg
```

<a id="rocky-linux-9-select-create-a-configuration-file-for-the-grub2-bootloader-check-for-kernel-updates"></a>
#### カーネル更新の確認

カーネル バージョンが正常に更新されたことを確認します。

```
[root@rocky810 ~]# uname -r
4.18.0-553.16.1.el8_10.x86_64
```


<a id="rocky-linux-9-change-the-kernel-boot-order"></a>
### カーネル ブート順序を変更 { #rocky-linux-9-change-the-kernel-boot-order }

複数のカーネルがインストールされている場合、希望するカーネルでブートするようにブート順序を変更します。

##### デフォルト カーネルを確認

現在設定されているデフォルト カーネルを確認します。

```
[root@rocky95 ~]# grubby --default-kernel
/boot/vmlinuz-5.14.0-503.22.1.el9_5.x86_64
```

##### 現在インストール済みのカーネル一覧

現在インストール済みのカーネル一覧を確認します。

```
[root@rocky95 ~]# grubby --info=ALL | grep ^kernel | grep -v rescue
kernel="/boot/vmlinuz-5.14.0-503.14.1.el9_5.x86_64"
kernel="/boot/vmlinuz-5.14.0-503.22.1.el9_5.x86_64"
```

##### デフォルト カーネルを変更

現在インストール済みのカーネル一覧から 1 つを選択して、デフォルト カーネルを変更します。

```
[root@rocky95 ~]# grubby --set-default="/boot/vmlinuz-5.14.0-503.14.1.el9_5.x86_64"
The default is /boot/loader/entries/858382f092494811bf89e090de079ab1-5.14.0-503.14.1.el9_5.x86_64.conf with index 0 and kernel /boot/vmlinuz-5.14.0-503.14.1.el9_5.x86_64
[root@rocky95 ~]# grubby --default-kernel
/boot/vmlinuz-5.14.0-503.14.1.el9_5.x86_64
[root@rocky95 ~]# sync; reboot
```

##### OS を再起動

ブート順序の変更を適用するために OS を再起動します。

```
[root@rocky810 ~]# sync; reboot
```