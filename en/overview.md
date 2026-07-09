<!-- pre-align:aligned sig=1e81aa248323 -->

<a id="compute-instance-overview"></a>
## Compute > Instance > Overview { #compute-instance-overview }

An instance is a virtual server composed of virtual CPUs, memory, and root block storage. You can install your services and applications on this server and use it in combination with the various services provided by NHN Cloud. An instance can be created in just a few minutes and can be scaled up or down at any time as needed.

<a id="components"></a>
## Instance components overview { #components }

The components that make up an instance are as follows:

- **Image**: A virtual disk containing the operating system of the instance
- **Flavor**: The virtual hardware performance of the instance
- **Availability zone** (AZ): The physical location where the instance is created
- **Key pair**: A key used to access the instance
- **Security group**: Network security settings for the instance
- **Network**: The virtual network to which the instance is connected
- **Tags**: User-defined labels for organizing and searching instances

Instance properties and usage change depending on these components. While settings for these components, with the exception of image and availability zone, can be modified after the creation of an instance, some flavors cannot be modified after an instance has been created. For more details on modifying instance flavors, see [Modify Flavor in the Console Guide](./console-guide/#modify-flavor).

<a id="image"></a>
### Instance image { #image }

An image is a virtual disk that contains an operating system. NHN Cloud currently supports Debian, Ubuntu, Rocky, and Windows.

All images are configured to run optimally on an instance's virtual hardware and are safe to use as they have undergone security inspection by NHN Cloud. For more details on images, see [Image Overview](/Compute/Image/en/overview/).

<a id="flavor"></a>
### Instance flavor { #flavor }

NHN Cloud provides various instance flavors to support a wide range of use cases. Instances can be created with flavors that best match the requirements of your services or applications. Flavors can be easily modified from the web console, even after an instance has been created.

| Type | Description |
| ------- |--------------------------------------------------------------------------------------------------------------------------------------------------|
| m2 | A balanced flavor with equal CPU and memory settings. Use this flavor when the performance requirements of your service or application are not clearly defined. |
| c2 | A compute-optimized flavor with high CPU performance. Suitable for web application servers or analytics systems that require high-performance computing. |
| r2 | Use this flavor when memory usage is higher relative to other resources. Typically used for in-memory databases or cache servers. |
| t2 | A cost-effective flavor. Use this for servers with low workloads. |
| u2 | The most affordable flavor. Use this for servers with low workloads.<br>Because it uses local block storage, it is relatively less reliable than other instances, but it is available at a lower cost.<br>This flavor does not guarantee I/O performance. |
| x1 | A flavor that supports high-spec CPUs and memory. Use this for services or applications that require high performance. |

<a id="availability-zone"></a>
### Availability zone { #availability-zone }

NHN Cloud has divided the entire system into multiple availability zones to prepare for potential failures caused by physical hardware issues. Each availability zone has its own storage system, network switch, data center space, and power supply units. A failure that occurs within one availability zone does not affect other zones, thereby increasing the availability of the whole service. You can ensure increased service availability by creating instances across multiple availability zones.

The following characteristics apply between different availability zones:

- Instances created across multiple availability zones can communicate with each other over the network, and no network usage fees are charged for this communication.
- Block storage can be shared between instances within the same availability zone, but cannot be shared between instances in different availability zones.
- Floating IP can be shared across different availability zones. If one availability zone experiences a failure, floating IP can quickly be relocated to another availability zone in order to minimize downtime.

<a id="key-pair"></a>
### Key pair { #key-pair }

A key pair is a pair of [PKI](https://ko.wikipedia.org/wiki/%EA%B3%B5%EA%B0%9C_%ED%82%A4_%EA%B8%B0%EB%B0%98_%EA%B5%AC%EC%A1%B0)-based public and private SSH keys. To access an instance created in NHN Cloud, a key pair is required instead of keyboard-inputted ID/PW authentication, which is vulnerable to security attacks. You can safely access an instance once you have been authenticated after sending the instance your login information, encoded by your key pair's private key. For more details on how to access instances using key pairs, see [How to Access Instances](#how-to-access-instances).

Key pairs can be newly generated from the NHN Cloud console during instance creation, or you can register your own existing key pairs. For more details on how to register key pairs, see [Import Key Pairs in the Console Guide](./console-guide/#import-key-pairs-windows).

> [Caution]
> When a key pair is newly generated, its private key is downloaded. As private keys are issued only once, be sure to store downloaded private keys in a safe disk or USB drive. If a private key is exposed, anyone can access the instance using the exposed private key, so it must be managed carefully.

> [Note]
> Key pairs are resources assigned to your user account, so they are not deleted even if the project is deleted.

<a id="security-groups"></a>
### Security groups { #security-groups }

A security group is a virtual firewall that controls the network traffic delivered to an instance. For more details on security groups, see [VPC Overview](/Network/VPC/en/overview/).

> [Note]
> The default security group is configured to ignore all inbound network traffic. Before accessing an instance using SSH, configure the instance's security group to allow access to the SSH port.

<a id="network"></a>
### Network { #network }

To communicate with external systems, an instance must be connected to at least one network defined in the VPC. Instances that are not connected to a network cannot be accessed. To create or modify a network, see [VPC Overview](/Network/VPC/en/overview/).

<a id="pricing"></a>
## Pricing { #pricing }

The pricing for instances is as follows:

* Instances are charged from the moment they are created.
* The root block storage of an instance is charged separately from the instance, based on the block storage pricing criteria.
* When an instance is stopped, a 90% discount from the standard pricing is applied for 90 days. If the instance remains stopped for more than 90 days, standard pricing is applied while the instance remains in the stopped state.
* Terminated instances are not charged.

For more details on pricing, see the [pricing page](https://www.toast.com/kr/service/compute/instance#price) for each service.

<a id="regions-and-availability"></a>
## Supported regions and availability { #regions-and-availability }

Instances are available across multiple NHN Cloud regions, and each region consists of independent availability zones. When selecting a region, consider the location of your target users, regulatory requirements, and compatibility with other NHN Cloud services.

- **Korea (Pangyo) region**: Provides the lowest latency for domestic services.
- **Korea (Pyeongchon) region**: Well-suited as a disaster recovery site for the Pangyo region.
- **Japan region**: Suitable for services targeting users in Japan and East Asia.

The instance flavors and images available in each region may vary, so check the supported list by region in the console before creating an instance.

<a id="how-to-access-instances"></a>
## How to access instances { #how-to-access-instances }

<a id="how-to-access-linux-instances"></a>
### How to access Linux instances { #how-to-access-linux-instances }

You can access your Linux instances using an SSH client. An instance cannot be accessed if its security group does not have SSH ports (22 by default) allowed. See [VPC Overview](/Network/VPC/en/overview/) for more details on how to allow SSH access. If a floating IP is not assigned to an instance, the instance cannot be accessed from outside NHN Cloud. See [VPC Overview](/Network/VPC/en/overview/) for more details on how to assign floating IP.

<a id="how-to-access-linux-instances-from-mac-or-linux-using-an-ssh-client"></a>
#### How to access Linux instances from Mac or Linux using an SSH client

Generally, Mac and Linux have SSH clients installed by default. Use a key pair's private key to access an instance from an SSH client as shown below.

Ubuntu instance

	$ ssh -i my_private_key.pem ubuntu@<instance IP>

Debian instance

	$ ssh -i my_private_key.pem debian@<instance IP>

Rocky instance

	$ ssh -i my_private_key.pem rocky@<instance IP>

<a id="how-to-access-linux-instances-from-windows-using-putty-ssh-client"></a>
#### How to access Linux instances from Windows using PuTTY SSH client

The PuTTY SSH client is a widely used SSH client program for Windows. Install [PuTTY](https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html) or [iPuTTY](https://github.com/iPuTTY/iPuTTY/releases/tag/l0.70i), which includes a Korean language patch.

To access a Linux instance from Windows using the PuTTY SSH client, you must complete three steps.

* Change the key pair's private key to a PuTTY-compatible private key
* Register the PuTTY-compatible private key in PuTTY
* Access the instance using PuTTY

##### 1. Change the key pair's private key to a PuTTY-compatible private key

In PuTTY, you must convert the key pair's private key to PuTTY's private key format. Use puttygen, which is installed along with PuTTY, for key conversion.

![이미지1](http://static.toastoven.net/prod_instance/putty001.png)

At the bottom of the **PuTTY Key Generator** window under **Parameters**, select **RSA** for the **Type of key to generate**, and enter the default value '2048' bits for the **Number of bits in a generated key**. Under **Actions**, click **Load** next to **Load an existing private key file** to import your key pair's private key file.

![이미지2](http://static.toastoven.net/prod_instance/putty002.png)

Under **Actions**, click **Save private key** next to **Save the generated key** to save the converted key pair's private key for PuTTY. If you save the private key while leaving **Key passphrase** blank, the message **Are you sure you want to save this key without a passphrase to protect it?** appears. To save the converted private key more securely, set a passphrase before saving.

> [Caution]
If you wish to be able to automatically log in to your instance, you should not set a key passphrase. When a passphrase is used, you must manually enter the private key's passphrase during login.

##### 2. Register the PuTTY-compatible private key in PuTTY

The PuTTY-compatible private key that you created can be registered and used in two ways.

* Registering the authentication private key file in PuTTY
* Registering the authentication private key file in pageant (PuTTY authentication agent)

**A. Registering the authentication private key file in PuTTY**


Run PuTTY and select **Connection > SSH > Auth** from the **Category** on the left. Under **Authentication parameters** on the right, register your PuTTY-compatible private key in **Private key file for authentication**.

![이미지3](http://static.toastoven.net/prod_instance/putty005.png)

Once you register your private key, you do not have to re-register your private key file each time you access your instance if you save your access information. For details on how to save your access information, see the section below on accessing instances.


**B. Registering the authentication private key file in pageant (PuTTY authentication agent)**


When you run pageant, which is installed along with PuTTY, the icon shown below appears in the Windows tray. Right-click the pageant icon and select **Add Key** to add your PuTTY-compatible private key.

![이미지4](http://static.toastoven.net/prod_instance/putty006.png)

To verify that the private key has been added, select **View Keys**. If the key was added successfully, the added key appears as shown below.

![이미지5](http://static.toastoven.net/prod_instance/putty008.png)

Once you run pageant, it remains running in the Windows tray, so there is no need for you to rerun it every time you access an instance. However, you must run pageant again when you restart Windows.

##### 3. Access the instance using PuTTY

Once the converted private key is properly registered, run PuTTY.

![이미지6](http://static.toastoven.net/prod_instance/putty009.png)

For **Host Name** in the basic connection settings, use the following:

Ubuntu

	ubuntu@<instance IP>

Debian

	debian@<instance IP>

Rocky

	rocky@<instance IP>

Set **Port** to 22, which is the default SSH port, and set **Connection type** to **SSH**.

If all of the information is correct, save the session. Under **Load, save or delete a stored session**, enter the name of the session to save in **Saved Sessions** and click **Save** to save the session. If you do not save the session, your private key settings registered in 2-A are also not preserved.

Click **Open** to connect to the instance.

<a id="how-to-access-windows-instances"></a>
### How to access Windows instances { #how-to-access-windows-instances }

To access your Windows server, select a Windows instance to access from the NHN Cloud console. In the instance details page under the **Access Information** tab, click **Confirm Password** to check the password set in the Windows server.

The key pair's private key that you enter in **Confirm Password** is not sent to the server and is only used to decrypt the password in the browser.

Click **Connect** next to **Confirm Password** to download and run the .rdp file that contains the remote desktop connection settings to access the Windows server. The username for the Windows server is `Administrator`, and use the password that you confirmed in the NHN Cloud console.

<a id="how-to-connect-serial-console"></a>
### How to connect to the serial console { #how-to-connect-serial-console }

You can connect to the serial console to access an instance in situations where an SSH client cannot be used, such as when there is a boot failure or a network configuration issue. 

The serial console feature has the following restrictions:

* Only one serial console connection is allowed per instance. Multiple connection attempts may result in connection failure.
* Serial console access is not guaranteed for instances created from images uploaded by users or from private images.
* A serial console connection can last up to 10 minutes.
* Windows instances do not support the serial console feature.
* Instances created before the January 27, 2026 deployment require **Stop Instance** followed by **Start Instance**. The **Reboot Instance** feature does not apply this change.

> [Caution]
> Changing the boot method while connected to an instance via the serial console may cause a boot failure. You are responsible for any consequences that result.
> We recommend that you use an SSH client to access an instance under normal circumstances.

<a id="change-grub-bootloader-settings"></a>
#### Change GRUB bootloader settings

GRUB configuration is required to modify the bootloader on instances created before the November 26, 2024 deployment.

Modify the GRUB configuration file.

```
$ sudo vi /etc/default/grub.d/50-cloudimg-settings.cfg
GRUB_TIMEOUT=3
GRUB_TERMINAL="console serial"
GRUB_SERIAL_COMMAND="serial --speed=9600 --unit=0 --word=8 --parity=no --stop=1"
```

Apply the updated settings. The command for applying GRUB settings may vary depending on your operating system.

```
$ sudo update-grub
```