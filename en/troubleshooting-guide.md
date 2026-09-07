<!-- machine_translated: true -->

<!-- pre-align:aligned sig=45e098944fc5 -->

<a id="compute-instance-troubleshooting-guide"></a>
## Compute > Instance > Troubleshooting Guide { #compute-instance-troubleshooting-guide }

This guide describes how to resolve issues you may encounter while using NHN Cloud.

<h3>Can I use a different OS version than what NHN Cloud provides by default? Can I upload my personal images?</h3>

You can only use the OS version provided by NHN Cloud. Uploading personal images is not supported.
To use personal OS images, create an instance with an image provided by NHN Cloud, then use the **Create Image** feature.
<br>

<h3>When I try to access an instance, I get a "Permissions 0644 for '/Users/username/.ssh/your-key.pem' are too open." message and cannot access the instance.</h3>

This issue occurs when the personal key (PEM key) used to access the instance has invalid permissions.
Adjust the permissions of the personal key file as follows:

    $ chmod 600 your-key.pem
<br>

<h3>How do I obtain root privileges on a CentOS instance?</h3>

To obtain root access on a CentOS instance, use the `sudo` command as follows:

    $ sudo su
<br>

<h3>When I create an instance from a personal image and boot it, I get a mount error.</h3>

This issue occurs when you create an image from an instance using two or more block storages, and then create and boot a new instance from that image.

For instances using two or more block storages, other disks besides the default disk are configured in the `/etc/fstab` file. Since this file is replicated when an image is created, when a new instance is booted from that image, a mount error occurs because the block storage referenced by the `/etc/fstab` file does not exist.

To resolve this issue, comment out the block storage settings (except the default disk) in the `/etc/fstab` file before creating an image.
<br>
<br>

<h3>SSH connection is very slow.</h3>

This occurs when DNS is blocked in the outbound rules of the security group to which the instance belongs. Adjust the security group to allow outbound DNS traffic.
<br>
<br>

<h3>I get a "Could not resolve the host" message and cannot use yum and other tools.</h3>

This occurs when DNS is blocked in the outbound rules of the security group to which the instance belongs. Adjust the security group to allow outbound DNS traffic.
<br>
<br>

<a id="proxy-instance-issue">
<h3>Instances using a proxy are not functioning correctly.</h3>
</a>

NHN Cloud's Monitoring services (System Monitoring, Service Monitoring, Cloud Monitoring) may not work properly on instances using a proxy. Additionally, on Windows operating systems, issues such as password reset failures may occur.

To prevent these issues, on instances using a proxy, configure the `169.254.0.0/16` range to bypass the proxy. This is typically configured using the `no_proxy` environment variable; however, depending on your proxy, this variable may be ignored. Refer to your proxy's documentation for configuration instructions.
<br>
<br>

<h3>Package updates fail on CentOS instances.</h3>

Modify the `yum repository` file as follows:
Additional updates are not supported for operating systems whose official support has ended. We recommend that you use a higher version of the OS.

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