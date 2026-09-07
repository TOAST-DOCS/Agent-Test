<!-- machine_translated: true -->

<!-- pre-align:aligned sig=45e098944fc5 -->

<a id="compute-instance-troubleshooting-guide"></a>
## Compute > Instance > Troubleshooting Guide { #compute-instance-troubleshooting-guide }

The document describes how to resolve issues you may encounter while using NHN Cloud.

<h3>I want to use a different version, other than the default OS version of NHN Cloud. Can I upload my personal images?</h3>

You can only use the OS version provided by NHN Cloud. And uploading personal images is not allowed.
To use personal OS images, create an instance with NHN Cloud image and apply **Create Image**.
<br>

<h3>When I try to access instance, I find "Permissions 0644 for '/Users/username/.ssh/your-key.pem' are too open." and access is not available.</h3>

It happens when the personal key (PEM key) applied to access instance has invalid authority.
Adjust the authority of personal key file like below.

    $ chmod 600 your-key.pem
<br>

<h3>How do I obtain root privileges on a CentOS instance?</h3>

To obtain root privileges on a CentOS instance, use the `sudo` command as follows.

    $ sudo su
<br>

<h3>I created a personal image and created an instance from it, but a mount error occurs during boot.</h3>

You shall encounter with such error, when an image is created with instance using two or more block storages and instance is created and booted with such image.

For instances that use two or more block storages, set disks other than the default disk in the `/etc/fstab` file. Since the file is also replicated when the image is created, when a new instance boots, a mount error occurs because the block storage referenced by the `/etc/fstab` file does not exist.

To resolve this issue, comment out block storage configuration in the `/etc/fstab` file, except for the default disk, before creating an image.
<br>
<br>

<h3>SSH connection is too slow.</h3>

It happens when DNS is blocked in the outbound rules of the security group to which the instance belongs. Adjust the security group to allow outbound DNS.
<br>
<br>

<h3>"Could not resolve the host" appears and I cannot use yum and such.</h3>

It happens when DNS is blocked in the outbound rules of the security group to which the instance belongs. Adjust the security group to allow outbound DNS.
<br>
<br>

<a id="proxy-instance-issue">
<h3>Operations are abnormal on instances using a proxy.</h3>
</a>

Monitoring services (System Monitoring, Service Monitoring, Cloud Monitoring) in NHN Cloud may not operate normally on instances that use a proxy. Additionally, on Windows operating systems, problems such as password reset may occur.

To prevent these issues, on instances that use a proxy, you must configure the settings so that traffic to the `169.254.0.0/16` range does not use a proxy. Generally, you configure this value in the `no_proxy` environment variable, but depending on the proxy used, this environment variable may be ignored. Refer to the guide for the proxy you are using and configure the settings accordingly.
<br>
<br>

<h3>Package updates fail on CentOS instances.</h3>

Use the `yum repository` file after modifying it as follows.
Additional updates are not supported for OS for which official support has ended, so it is recommended that you use a higher version of the OS.

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

<h4>Common</h4>

```
$ sudo yum clean all
$ sudo yum repolist
```

<br>
<br>