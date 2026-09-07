<!-- machine_translated: true -->

<!-- pre-align:aligned sig=45e098944fc5 -->

<a id="compute-instance-troubleshooting-guide"></a>
## Compute > Instance > Troubleshooting Guide { #compute-instance-troubleshooting-guide }

The document describes how to resolve issues you may encounter while using NHN Cloud.

<h3>I want to use a different version, other than the default OS version of NHN Cloud. Can I upload my personal images?</h3>

You can only use the OS version provided by NHN Cloud. Uploading personal images is not allowed.
To use personal OS images, create an instance with NHN Cloud image and apply **Create Image**.
<br>

<h3>When I try to access an instance, I find "Permissions 0644 for '/Users/username/.ssh/your-key.pem' are too open." and access is not available.</h3>

This issue occurs when the personal key (PEM key) used to access the instance has invalid permissions.
Adjust the permissions of the personal key file as follows.

    $ chmod 600 your-key.pem
<br>

<h3>How do I get root privileges on a CentOS instance?</h3>

To get root privileges on a CentOS instance, use the `sudo` command as follows.

    $ sudo su
<br>

<h3>I created a personal image and launched an instance, but I get a mount error.</h3>

This issue occurs when you create an image from an instance that uses two or more block storages, and then create and boot a new instance from that image.

For instances that use more than two block storages, set disks other than the default disk in the `/etc/fstab` file. Since this file is also replicated when the image is created, when the new instance boots, a mount error occurs because the block storage referenced by the `/etc/fstab` file does not exist.

To resolve this issue, comment out the block storage settings other than the default disk in the `/etc/fstab` file before creating an image.
<br>
<br>

<h3>SSH access is too slow.</h3>

This issue occurs when DNS is blocked in the outbound section of the security group to which the instance belongs. Adjust the security group to allow DNS outbound traffic.
<br>
<br>

<h3>"Could not resolve the host" error appears and I cannot use yum.</h3>

This issue occurs when DNS is blocked in the outbound section of the security group to which the instance belongs. Adjust the security group to allow DNS outbound traffic.
<br>
<br>

<a id="proxy-instance-issue">
<h3>Instances configured with a proxy are not working properly.</h3>
</a>

The Monitoring services (System Monitoring, Service Monitoring, Cloud Monitoring) of NHN Cloud may not work properly on instances that use a proxy. Additionally, Windows instances may encounter issues such as password reset failures.

To prevent these issues, configure the instance to bypass the proxy for the `169.254.0.0/16` address range. Typically, you set this value in the `no_proxy` environment variable, but some proxies ignore this environment variable. Refer to the documentation of your proxy for configuration details.
<br>
<br>

<h3>Package update fails on a CentOS instance.</h3>

Use the `yum repository` file after modifying the file as follows.
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