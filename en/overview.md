<a id="compute-instance-overview"></a>
## Compute > Instance > Overview { #compute-instance-overview }

An instance is a virtual server composed of virtual CPUs, memory, and root block storage. You can install your services and applications on this server and use it in combination with the various services provided by NHN Cloud. An instance can be created in a few minutes and can be scaled up or down at any time as needed.

<a id="components"></a>
## Instance components { #components }

The components that make up an instance are as follows:

- **Image**: A virtual disk containing the operating system of the instance
- **Flavor**: The virtual hardware performance of the instance
- **Availability zone** (AZ): The physical location where the instance will be created
- **Key pair**: A key used to access the instance
- **Security groups**: Network security settings for the instance
- **Network**: The virtual network to which the instance will be connected
- **Tags**: User-defined labels for classifying and searching instances

Instance properties and usage change depending on these components. While settings for these components, with the exception of image and availability zone, can be modified after the creation of an instance, some flavors cannot be modified after an instance has been created. For more details on modifying instance flavors, see [Modify Flavor in the Console Guide](./console-guide/#modify-flavor).

<a id="image"></a>
### Image { #image }

An image is a virtual disk containing an operating system. NHN Cloud currently supports Debian, Ubuntu, Rocky, and Windows.

All images are configured to run optimally on an instance's virtual hardware and are safe to use as they have undergone security inspection by NHN Cloud. For more details on images, see [Image Overview](/Compute/Image/en/overview/).

<a id="flavor"></a>
### Instance flavor { #flavor }

NHN Cloud provides various instance flavors to support a wide range of use cases. Instances can be created with flavors that best match the requirements of your services or applications. Flavors can be easily modified from the web console, even after an instance has been created.

| Flavor | Description |
| ------- |--------------------------------------------------------------------------------------------------------------------------------------------------|
| m2 | A balanced type with equal CPU and memory configuration. Use this when the performance requirements of your service or application are not clearly defined. |
| c2 | An instance type with high CPU performance. Use this for web application servers or analytics systems that require high-performance computing. |
| r2 | Use this when memory usage is significantly higher compared to other resources. Typically used for in-memory databases or cache servers. |
| t2 | A low-cost instance. Use this for servers with low workloads. |
| u2 | The most affordable instance. Use this for servers with low workloads.<br>Because it uses local block storage, it is relatively less reliable than other instances, but available at a lower price.<br>This type does not guarantee I/O performance. |
| x1 | A type that supports high-spec CPUs and memory. Use this for services or applications that require high performance. |

<a id="availability-zone"></a>
### Availability zone { #availability-zone }

NHN Cloud has divided the entire system into multiple availability zones to prepare for potential failures caused by physical hardware issues. Each availability zone has its own storage system, network switch, data center space, and power supply units. A failure that occurs within one availability zone does not affect other zones, thereby increasing the availability of the whole service. You can ensure increased service availability by creating instances across multiple availability zones.

The following characteristics apply between different availability zones:

- Instances created across different availability zones can communicate with each other over the network, and no network usage fees are charged for this communication.
- Block storage can be shared between instances created in the same availability zone, but cannot be shared between instances in different availability zones.
- Floating IP can be shared across different availability zones. If one availability zone experiences a failure, floating IP can quickly be relocated to another availability zone in order to minimize downtime.

<a id="key-pair"></a>
### Key pair { #key-pair }

A key pair is a pair of [PKI](https://ko.wikipedia.org/wiki/%EA%B3%B5%EA%B0%9C_%ED%82%A4_%EA%B8%B0%EB%B0%98_%EA%B5%AC%EC%A1%B0)-based public and private SSH keys. To access an instance created in NHN Cloud, a key pair is required instead of keyboard-inputted ID/PW authentication, which is vulnerable to security attacks. You can safely access an instance once you have been authenticated after sending the instance your login information, encoded by your key pair's private key. For more details on how to access instances using key pairs, see [How to Access Instances](#how-to-access-instances).

Key pairs can be newly generated from the NHN Cloud console during instance creation, or you can register your own existing key pairs. For more details on how to register key pairs, see [Import Key Pairs in the Console Guide](./console-guide/#import-key-pairs-windows).

> [Caution]
> When a key pair is newly generated, its private key is downloaded. As private keys are issued only once, be sure to store downloaded private keys in a safe disk or USB drive. If a private key is exposed, anyone can access the instance using the exposed private key, so it must be managed carefully.

> [Note]
> A key pair is a resource assigned to a user account and is retained even if the project is deleted.

<a id="security-groups"></a>
### Security groups { #security-groups }

A security group is a virtual firewall that determines the network traffic delivered to an instance. For more details on security groups, see [VPC Overview](/Network/VPC/en/overview/).

> [Note]
> The default security group is configured to ignore all inbound network traffic. Before accessing an instance using SSH, configure the instance's security group to allow access to the SSH port.

<a id="network"></a>
### Network { #network }

To communicate with external networks, an instance must be connected to at least one network defined in the VPC. Instances that are not connected to a network cannot be accessed. To create or modify a network, see [VPC Overview](/Network/VPC/en/overview/).

<!-- @if:this-is-only-public -->
<a id="public-only-notice"></a>
## Notice for public deployment only { #public-only-notice }

This section is displayed only on sites built with the `this-is-only-public` flag. It is not exposed in other zone/environment documents.

* Example: Policy, pricing, and SLA information applicable only to public regions
* Example: Promotional content to be displayed only for commercial deployment targets
<!-- @endif -->

<a id="pricing"></a>
## Pricing { #pricing }

The instance pricing model is as follows:

* Instances are charged from the moment they are created.
* The instance's root block storage is charged separately from the instance, based on block storage pricing.
* When an instance is stopped, a 90% discount on the standard pricing is applied for 90 days. If the stopped state exceeds 90 days, the instance remains stopped and reverts to the standard rate.
* Terminated instances are not charged.

For more details on pricing, see the [pricing page](https://www.toast.com/kr/service/compute/instance#price) for each service.

<a id="backup-and-snapshot"></a>
## Backup and snapshot { #backup-and-snapshot }

To protect instance data safely, we recommend that you create backups and snapshots regularly. Backups and snapshots differ in the following ways:

- **Backup**: Periodically copies the instance's root block storage according to a specified schedule and stores it in a separate storage location. Suitable for long-term retention and disaster recovery.
- **Snapshot**: Saves the state of an instance at a specific point in time. Suitable for use as a rollback point before system changes.

Backups and snapshots are retained even if the original instance is deleted, so you can use them to restore an instance after deletion. For more details, see [Backup Service Overview](/Storage/Backup/en/overview/).

<a id="how-to-access-instances"></a>
## How to access instances { #how-to-access-instances }

<a id="how-to-access-linux-instances"></a>
### How to access Linux instances { #how-to-access-linux-instances }

You can access your Linux instances using an SSH client. An instance cannot be accessed if its security group does not have SSH ports (22 by default) allowed. See [VPC Overview](/Network/VPC/en/overview/) for more details on how to allow SSH access. If a floating IP is not assigned to an instance, the instance cannot be accessed from outside NHN Cloud. See [VPC Overview](/Network/VPC/en/overview/) for more details on how to assign floating IP.

<a id="how-to-access-linux-instances-using-an-ssh-client-on-mac-or-linux"></a>
#### How to access Linux instances using an SSH client on Mac or Linux

Generally, Mac and Linux have SSH clients installed by default. Use a key pair's private key to access an instance from an SSH client as shown below.

Ubuntu instance

	$ ssh -i my_private_key.pem ubuntu@<Instance IP>

Debian instance

	$ ssh -i my_private_key.pem debian@<Instance IP>

Rocky instance

	$ ssh -i my_private_key.pem rocky@<Instance IP>

<a id="how-to-access-linux-instances-using-a-putty-ssh-client-on-windows"></a>
#### How to access Linux instances using a PuTTY SSH client on Windows

The PuTTY SSH client is a widely used SSH client program for Windows. Install [PuTTY](https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html) or [iPuTTY](https://github.com/iPuTTY/iPuTTY/releases/tag/l0.70i), which includes a Korean language patch.

To access Linux instances using PuTTY on Windows, complete the following three steps:

* Change your key pair's private key to a PuTTY-compatible private key
* Register your PuTTY-compatible private key in PuTTY
* Connect to the instance using PuTTY

##### 1. Changing your key pair's private key to a PuTTY-compatible private key

In PuTTY, you must convert the key pair's private key to PuTTY's private key format before using it. Use puttygen, which is installed with PuTTY, to convert the key.

![Image 1](http://static.toastoven.net/prod_instance/putty001.png)

At the bottom of the **PuTTY Key Generator** window under **Parameters**, select **RSA** for the **Type of key to generate**, and enter the default value '2048' bits for the **Number of bits in a generated key**. Under **Actions**, click **Load** next to **Load an existing private key file** to import your key pair's private key file.

![Image 2](http://static.toastoven.net/prod_instance/putty002.png)

Under **Actions**, click **Save private key** next to **Save the generated key** to save the key pair's private key converted for PuTTY. If you save the private key while leaving **Key passphrase** blank, the message **Are you sure you want to save this key without a passphrase to protect it?** appears. To store the converted private key more securely, set a passphrase before saving.

> [Caution]
If you wish to be able to automatically log in to your instance, you should not set a key passphrase. When a passphrase is used, you must manually enter the private key's passphrase during login.


```
#echo hello
```

##### 2. Registering your PuTTY-compatible private key in PuTTY

The PuTTY-compatible private key that you created can be registered and used in two ways.

* Registering and using a private key file for authentication in PuTTY
* Registering and using a private key file for authentication in pageant (PuTTY authentication agent)

**A. Registering and using a private key file for authentication in PuTTY**


Run PuTTY and select **Connection > SSH > Auth** from the **Category** on the left. Under **Authentication parameters** on the right, register your PuTTY-compatible private key in **Private key file for authentication**.

![Image 3](http://static.toastoven.net/prod_instance/putty005.png)

Once you register your private key, you do not have to re-register your private key file each time you access your instance if you save your access information. For details on how to save your access information, see the section below on accessing instances.


**B. Registering and using a private key file for authentication in pageant (PuTTY authentication agent)**


When you run pageant, which is installed along with PuTTY, the icon shown below appears in the Windows tray. Right-click the pageant icon and select **Add Key** to add your PuTTY-compatible private key.

![Image 4](http://static.toastoven.net/prod_instance/putty006.png)

To confirm that the private key was added, select **View Keys**. If the key was added successfully, the added key appears as shown below.

![Image 5](http://static.toastoven.net/prod_instance/putty008.png)

Once you run pageant, it remains running in the Windows tray, so there is no need for you to rerun it every time you access an instance. However, you must run pageant again when you restart Windows.

##### 3. Connecting to an instance using PuTTY

After your PuTTY-compatible private key has been registered successfully, run PuTTY.

![Image 6](http://static.toastoven.net/prod_instance/putty009.png)

Use the following for **Host Name** in the basic connection information:

Ubuntu

	ubuntu@<Instance IP>

Debian

	debian@<Instance IP>

Rocky

	rocky@<Instance IP>

Set **Port** to 22, the default SSH port, and set **Connection type** to **SSH**.

If all of the information is correct, save the session. Under **Load, save or delete a stored session**, enter the name of the session to save in **Saved Sessions** and click **Save** to save the session. If you do not save the session, your private key settings registered in 2-A are also not preserved.

Click **Open** to connect to the instance.

<a id="how-to-access-windows-instances"></a>
### How to access Windows instances { #how-to-access-windows-instances }

To access your Windows server, select a Windows instance to access from the NHN Cloud console. In the instance details page under the **Access Information** tab, click **Confirm Password** to check the password set in the Windows server.

The key pair's private key that you enter in **Confirm Password** is not transmitted to the server; it is used only to decrypt the password in the browser.

Click **Connect** next to **Confirm Password** to download and run the .rdp file that contains the remote desktop connection settings, and connect to the Windows server. The Windows server ID is `Administrator`, and the password is the one that you confirmed in the NHN Cloud console.

<a id="how-to-access-via-serial-console"></a>
### How to access via serial console { #how-to-access-via-serial-console }

You can connect to an instance through the serial console when you cannot use an SSH client due to issues such as boot failures or network configuration problems.

The serial console feature has the following limitations:

* Only one serial console connection is allowed per instance. If multiple connections are attempted, the connection may not work properly.
* Serial console access is not guaranteed for instances created from personally uploaded images or personal images.
* A serial console connection can remain active for up to 10 minutes.
* Windows instances do not support the serial console feature.
* For instances created before the January 27, 2026 release, you must **Stop Instance** and then **Start Instance**. The **Reboot Instance** function does not apply.

> [Caution]
> Changing the boot method by connecting to an instance through the serial console may cause a boot failure. You are responsible for any consequences that result from such changes.
> We recommend that you use an SSH client connection under normal circumstances.

<a id="changing-grub-bootloader-settings"></a>
#### Changing GRUB bootloader settings

To manage the bootloader on instances created before the November 26, 2024 release, GRUB configuration is required.

Modify the GRUB configuration file.

```
$ sudo vi /etc/default/grub.d/50-cloudimg-settings.cfg
GRUB_TIMEOUT=3
GRUB_TERMINAL="console serial"
GRUB_SERIAL_COMMAND="serial --speed=9600 --unit=0 --word=8 --parity=no --stop=1"
```

Apply the updated settings. The command to apply GRUB settings may vary depending on the OS.

```
$ sudo update-grub
<!-- heading-lint: F1 L257 — Delete this line after review (automatically removed when suggestion is accepted) -->
```