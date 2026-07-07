<!-- pre-align:aligned sig=8a1251a5621e -->

<a id="compute-instance-overview"></a>

## Compute > Instance > Overview

An instance is a virtual server composed of virtual CPUs, memory, and root block storage. You can install your services and applications on this server and use it in combination with the various services provided by NHN Cloud. Instances can be created within minutes and can be scaled up or down at any time as needed.

<a id="components"></a>

## Instance components

The components that make up an instance are as follows:

- **Image**: A virtual disk that contains the operating system for the instance
- **Flavor**: The virtual hardware performance of the instance
- **Availability zone**: The physical location where the instance is created
- **Key pair**: A key used to access the instance
- **Security groups**: Network security settings for the instance
- **Network**: A virtual network to which the instance is connected
- **Tags**: User-defined labels to classify and search for instances

Instance properties and usage change depending on these components. While settings for these components, with the exception of image and availability zone, can be modified after the creation of an instance, some flavors cannot be modified after an instance has been created. For more details on modifying instance flavors, see [Modify Flavor in the Console Guide](./console-guide/#modify-flavor).

<a id="image"></a>
### Image

An image is a virtual disk that contains the operating system. NHN Cloud currently supports Debian, Ubuntu, Rocky, and Windows.

All images are configured to run optimally on an instance's virtual hardware and are safe to use as they have undergone security inspection by NHN Cloud. For more details on images, see [Image Overview](/Compute/Image/en/overview/).

<a id="flavor"></a>
### Instance flavor

NHN Cloud provides various instance flavors to support a wide range of use cases. Instances can be created with flavors that best match the requirements of your services or applications. Flavors can be easily modified from the web console, even after an instance has been created.

| Flavor    | Description                                                                                                                                               |
| ------- |--------------------------------------------------------------------------------------------------------------------------------------------------|
| m2 | A balanced type with CPU and memory configured evenly. Use this when the performance requirements of your services or applications are not clear.                                                                               |
| c2 | An instance type with high CPU performance. Use this for high-performance web application servers or analysis systems that require high computational performance.                                                                           |
| r2 | A type for use when memory usage is high compared to other resources. It is typically used for memory databases or cache servers.                                                                               |
| t2 | An affordable instance type. Use this for servers with light workloads.                                                                                                          |
| u2 | The most affordable instance type. Use this for servers with light workloads.<br>Because it uses local block storage, it has relatively lower stability than other instance types, but can be used at a lower cost.<br>This type of instance does not guarantee I/O performance. |
| x1 | A type that supports high-end CPUs and memory. Use this for services or applications that require high performance.                                                                                        |

<a id="availability-zone"></a>
### Availability zone

NHN Cloud has divided the entire system into multiple availability zones to prepare for potential failures caused by physical hardware issues. Each availability zone has its own storage system, network switch, data center space, and power supply units. A failure that occurs within one availability zone does not affect other zones, thereby increasing the availability of the whole service. You can ensure increased service availability by creating instances across multiple availability zones.

The following characteristics apply between different availability zones:

- Instances created across multiple availability zones can communicate with each other through the network, and no network usage charges are incurred for such communication.
- Block storage can be shared between instances created in the same availability zone, but block storage cannot be shared between instances in different availability zones.
- Floating IP can be shared across different availability zones. If one availability zone experiences a failure, floating IP can quickly be relocated to another availability zone in order to minimize downtime.

<a id="key-pair"></a>
### Key pair

A key pair is a pair of PKI-based public and private SSH keys. To access an instance created in NHN Cloud, a key pair is required instead of keyboard-inputted ID/PW authentication, which is vulnerable to security attacks. You can safely access an instance once you have been authenticated after sending the instance your login information, encoded by your key pair's private key. For more details on how to access instances using key pairs, see [How to Access Instances](#how-to-access-instances).

Key pairs can be newly generated from the NHN Cloud console during instance creation, or you can register your own existing key pairs. For more details on how to register key pairs, see [Import Key Pairs in the Console Guide](./console-guide/#import-key-pairs-windows).

> [Caution]
> When a key pair is newly generated, its private key is downloaded. As private keys are issued only once, be sure to store downloaded private keys in a safe disk or USB drive. If a private key is exposed, anyone can access the instance using the exposed private key, so it must be managed carefully.

> [Note]
> A key pair is a resource assigned to a user account, so it is preserved even if the project is deleted.

<a id="security-groups"></a>
### Security groups

A security group is a virtual firewall that determines the network traffic delivered to an instance. For more details on security groups, see [VPC Overview](/Network/VPC/en/overview/).

> [Note]
> The default security group is configured to ignore all inbound network traffic. Before accessing an instance using SSH, configure the instance's security group to allow access to the SSH port.

<a id="network"></a>
### Network

For an instance to communicate with the outside world, it must be connected to at least one network defined in the VPC. Instances that are not connected to a network cannot be accessed. To create or modify a network, see [VPC Overview](/Network/VPC/en/overview/).

<!-- @if:this-is-only-public -->
<a id="public-only-notice"></a>

## Public deployment notice

This section is displayed only on sites built with the `this-is-only-public` flag. It is not exposed in documentation for other zones or environments.

* Example: Policies, pricing, and SLA notices that apply only to the public region
* Example: Promotional text to be exposed only for commercial deployment targets
<!-- @endif -->

<a id="pricing"></a>

## Pricing

Instance pricing works as follows:

* Instances are charged from the moment they are created.
* The instance root block storage is charged separately according to the block storage pricing criteria.
* When an instance is stopped, a 90% discount is applied for 90 days. If the instance remains stopped for more than 90 days, normal billing charges apply.
* Terminated instances are not charged.

For more details on pricing, see the [pricing page](https://www.toast.com/kr/service/compute/instance#price) for each service.

<a id="backup-and-snapshot"></a>

## Backups and snapshots

To safely protect instance data, regular backups and snapshots are recommended. Backups and snapshots differ as follows:

- **Backup**: According to a specified schedule, the root block storage of an instance is periodically copied and stored in a separate storage location. It is suitable for long-term retention and disaster recovery.
- **Snapshot**: The state of an instance at a specific point in time is saved as is. It is suitable for use as a rollback point before system changes.

Backups and snapshots are preserved even after the original instance is deleted, so instances can be restored using them even after deletion. For more details, see [Backup Service Overview](/Storage/Backup/en/overview/).

<a id="how-to-access-instances"></a>

## How to access instances

<a id="how-to-access-linux-instances"></a>
### How to access Linux instances

You can access your Linux instances using an SSH client. An instance cannot be accessed if its security group does not have SSH ports (22 by default) allowed. See [VPC Overview](/Network/VPC/en/overview/) for more details on how to allow SSH access. If a floating IP is not assigned to an instance, the instance cannot be accessed from outside NHN Cloud. See [VPC Overview](/Network/VPC/en/overview/) for more details on how to assign floating IP.

#### How to access a Linux instance using an SSH client on Mac or Linux

Generally, Mac and Linux have SSH clients installed by default. Use a key pair's private key to access an instance from an SSH client as shown below.

Ubuntu instance

	$ ssh -i my_private_key.pem ubuntu@<instance IP>

Debian instance

	$ ssh -i my_private_key.pem debian@<instance IP>

Rocky instance

	$ ssh -i my_private_key.pem rocky@<instance IP>

#### How to access a Linux instance using the PuTTY SSH client on Windows

PuTTY SSH client is a popular SSH client program for Windows. Install [PuTTY](https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html) or [iPuTTY](https://github.com/iPuTTY/iPuTTY/releases/tag/l0.70i) with a Korean patch applied.

To access a Linux instance from the PuTTY SSH client on Windows, you must follow three steps:

* Convert the private key of a key pair to a PuTTY-compatible private key
* Register the PuTTY-compatible private key in PuTTY
* Access the instance using PuTTY

##### 1. Convert the private key of a key pair to a PuTTY-compatible private key

PuTTY requires you to convert the key pair private key to the PuTTY private key format. Use puttygen, which is installed with PuTTY, to convert the key.

![Image1](http://static.toastoven.net/prod_instance/putty001.png)

At the bottom of the **PuTTY Key Generator** window under **Parameters**, select **RSA** for the **Type of key to generate**, and enter the default value '2048' bits for the **Number of bits in a generated key**. Under **Actions**, click **Load** next to **Load an existing private key file** to import your key pair's private key file.

![Image2](http://static.toastoven.net/prod_instance/putty002.png)

Under **Actions**, click **Save private key** next to **Save the generated key** to save the converted key pair private key for PuTTY. If you save the private key with the **Key passphrase** field left blank, the message "Save key without a passphrase? Really save key?" appears. To save the converted private key more securely, set a passphrase and then save it.

> [Caution]
If you wish to be able to automatically log in to your instance, you should not set a key passphrase. When a passphrase is used, you must manually enter the private key's passphrase during login.


```
#echo hello
```

##### 2. Register the PuTTY-compatible private key in PuTTY

The PuTTY-compatible private key created this way can be registered and used in two ways:

* Register the authentication private key file in PuTTY and use it
* Register the authentication private key file in pageant (PuTTY authentication agent) and use it

**A. Register the authentication private key file in PuTTY and use it**

Run PuTTY and select **Connection > SSH > Auth** from the **Category** on the left. Under **Authentication parameters** on the right, register your PuTTY-compatible private key in **Private key file for authentication**.

![Image3](http://static.toastoven.net/prod_instance/putty005.png)

Once you register your private key, you do not have to re-register your private key file each time you access your instance if you save your access information. For details on how to save your access information, see the section below on accessing instances.

**B. Register the authentication private key file in pageant (PuTTY authentication agent) and use it**

When you run pageant, which is installed along with PuTTY, the icon shown below appears in the Windows tray. Right-click the pageant icon and select **Add Key** to add your PuTTY-compatible private key.

![Image4](http://static.toastoven.net/prod_instance/putty006.png)

To verify that the private key has been added, select **View Keys**. If the key was successfully added, the added key appears as shown in the figure below.

![Image5](http://static.toastoven.net/prod_instance/putty008.png)

Once you run pageant, it remains running in the Windows tray, so there is no need for you to rerun it every time you access an instance. However, you must run pageant again when you restart Windows.

##### 3. Access the instance using PuTTY

If the converted PuTTY-compatible private key is registered correctly, run PuTTY.

![Image6](http://static.toastoven.net/prod_instance/putty009.png)

For the **Host name** in the basic connection information, use the following:

Ubuntu

	ubuntu@<instance IP>

Debian

	debian@<instance IP>

Rocky

	rocky@<instance IP>

Set **Port** to 22, the default SSH port, and set **Connection type** to **SSH**.

If all of the information is correct, save the session. Under **Load, save or delete a stored session**, enter the name of the session to save in **Saved Sessions** and click **Save** to save the session. If you do not save the session, your private key settings registered in 2-A are also not preserved.

Now click **Open** to access the instance.

<a id="how-to-access-windows-instances"></a>
### How to access Windows instances

To access your Windows server, select a Windows instance to access from the NHN Cloud console. In the instance details page under the **Access Information** tab, click **Confirm Password** to check the password set in the Windows server.

The private key you enter in **Confirm Password** is not transmitted to the server; it is only used by your browser to decrypt the password.

Click the **Connect** button next to **Confirm Password** to download and run the .rdp file with the remote desktop connection settings saved. You can then access the Windows server. The user ID for the Windows server is `Administrator`, and use the password you confirmed in the NHN Cloud console.

### How to access using serial console

You can access an instance by connecting to the serial console in situations where you cannot use an SSH client, such as boot failures or network configuration issues.

The serial console feature has the following limitations:

* Only one serial console connection is allowed per instance. Multiple connection attempts may result in unsuccessful connections.
* Instances created with a custom image or a private image do not guarantee serial console access.
* A serial console connection allows up to 10 minutes of access.
* Windows instances do not support the serial console feature.
* For instances created before the deployment date of January 27, 2026, you must **Stop an instance** and then **Start an instance**. The **Reboot an instance** feature does not apply.

> [Caution]
> You may experience boot failures if you change the boot method by accessing an instance through the serial console. You are responsible for any consequences resulting from such changes.
> It is recommended that you use SSH client access in typical situations.

#### Change GRUB bootloader settings

For instances created before the deployment date of November 26, 2024, GRUB settings are required to manipulate the bootloader.

Modify the GRUB configuration file.

```
$ sudo vi /etc/default/grub.d/50-cloudimg-settings.cfg
GRUB_TIMEOUT=3
GRUB_TERMINAL="console serial"
GRUB_SERIAL_COMMAND="serial --speed=9600 --unit=0 --word=8 --parity=no --stop=1"
```

Apply the changed settings. The GRUB configuration application command may vary depending on the OS.

```
$ sudo update-grub
<!-- heading-lint: F1 L257 — Remove this line after review (automatically removed when suggestion is accepted) -->
```