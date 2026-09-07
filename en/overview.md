<!-- machine_translated: true -->

<!-- pre-align:aligned sig=f2414300858d -->

<a id="compute-instance-overview"></a>
## Compute > Instance > Overview { #compute-instance-overview }

An instance is a virtual server consisting of virtual CPU, memory, and root block storage. You can install your services or applications on this server and use them in combination with various services provided by NHN Cloud.

<a id="components"></a>
## Instance Components { #components }

Instance components are as follows:

- **Image**: A virtual disk that contains the instance's operating system
- **Flavor**: Virtual hardware performance of the instance
- **Availability Zone**: The physical location where the instance is created
- **Key Pair**: A key used for accessing the instance
- **Security Group**: Network security settings for the instance
- **Network**: The virtual network to which the instance will be connected

Instance properties and usage change depending on these components. While settings for these components, with the exception of image and availability zone, can be modified after the creation of an instance, some flavors cannot be modified after an instance has been created. For more details on modifying instance flavors, see [Modify Flavor in the Console Guide](./console-guide/#modify-flavor).

<a id="image"></a>
### Image { #image }

An image is a virtual disk that contains the operating system. NHN Cloud currently supports Debian, Ubuntu, Rocky, and Windows.

All images are configured to run optimally on an instance's virtual hardware and are safe to use as they have undergone security inspection by NHN Cloud. For more details on images, see [Image Overview](/Compute/Image/en/overview/).

<a id="flavor"></a>
### Instance Flavor { #flavor }

NHN Cloud provides various instance flavors to support a wide range of use cases. Instances can be created with flavors that best match the requirements of your services or applications. Flavors can be easily modified from the web console, even after an instance has been created.

| Flavor    | Description                                                                                                                                               |
| ------- |--------------------------------------------------------------------------------------------------------------------------------------------------|
| m2 | A flavor with balanced CPU and memory. Use this flavor when the performance requirements of your service or application are not clearly defined.                                                                               |
| c2 | A flavor with high CPU performance. Use this flavor for web application servers or analytical systems that require high-performance computing.                                                                           |
| r2 | Use this flavor when memory usage is high compared to other resources. This flavor is typically used for in-memory databases or cache servers.                                                                               |
| t2 | An economical flavor. Use this flavor for servers with low workloads.                                                                                                          |
| u2 | The most economical flavor. Use this flavor for servers with low workloads.<br>Because it uses local block storage, it is relatively less stable than other instance flavors, but it is available at a lower cost.<br>This flavor does not guarantee I/O performance. |
| x1 | A flavor that supports high-specification CPU and memory. Use this flavor for services or applications that require high performance.                                                                                        |

<a id="availability-zone"></a>
### Availability Zone { #availability-zone }

NHN Cloud has divided the entire system into multiple availability zones to prepare for potential failures caused by physical hardware issues. Each availability zone has its own storage system, network switch, data center space, and power supply units. A failure that occurs within one availability zone does not affect other zones, thereby increasing the availability of the whole service. You can ensure increased service availability by creating instances across multiple availability zones.

Between different availability zones, there are the following characteristics:

- Instances created in multiple availability zones can communicate with each other over the network, and no charges are incurred for the network traffic.
- Block storage can be shared between instances created in the same availability zone, but block storage cannot be shared between instances in different availability zones.
- Floating IPs can be shared across different availability zones. If a failure occurs in one availability zone, you can quickly move the floating IP to another availability zone to minimize downtime.

<a id="key-pair"></a>
### Key Pair { #key-pair }

A key pair is a pair of [PKI](https://en.wikipedia.org/wiki/Public_key_infrastructure)-based public and private SSH keys. To access an instance created in NHN Cloud, a key pair is required instead of keyboard-inputted ID/PW authentication, which is vulnerable to security attacks. You can safely access an instance once you have been authenticated after sending the instance your login information, encoded by your key pair's private key. For more details on how to access instances using key pairs, see [How to Access Instances](#how-to-access-instances).

Key pairs can be created during instance creation on the NHN Cloud console, or you can register and use a key pair created by yourself. For details on how to import a key pair, see [Import Key Pairs in the Console Guide](./console-guide/#import-key-pairs-windows).

> [Caution]
> When a key pair is newly generated, its private key is downloaded. As private keys are issued only once, be sure to store downloaded private keys in a safe disk or USB drive. If a private key is exposed, anyone can access the instance using the exposed private key, so it must be managed carefully.

> [Note]
> A key pair is a resource assigned to a user account, so it is retained even when a project is deleted.

<a id="security-groups"></a>
### Security Group { #security-groups }

A security group is a virtual firewall that determines the network traffic delivered to an instance. For more details on security groups, see [VPC Overview](/Network/VPC/en/overview/).

> [Note]
> The default security group is configured to ignore all inbound network traffic from external sources. When accessing an instance via SSH, first configure the security group to open SSH ports, then access the instance.

<a id="network"></a>
### Network { #network }

To communicate with external networks, an instance must be connected to at least one network defined in the VPC. An instance that is not connected to a network cannot be accessed. For details on creating or modifying a network, see [VPC Overview](/Network/VPC/en/overview/).

<a id="pricing"></a>
## Billing { #pricing }

Instance billing is as follows:

* Instances are charged from the moment they are created.
* Instance root block storage is charged separately from instances according to block storage billing standards.
* When an instance is stopped, a 90% discount is applied for 90 days based on the website pricing. If the instance remains stopped for more than 90 days, normal pricing is applied while maintaining the stopped state.
* Terminated instances are not charged.

For more details on billing, see the service-specific [pricing page](https://www.toast.com/kr/service/compute/instance#price).

<a id="how-to-access-instances"></a>
## How to Access Instances { #how-to-access-instances }

<a id="how-to-access-linux-instances"></a>
### How to Access Linux Instances { #how-to-access-linux-instances }

You can access your Linux instances using an SSH client. An instance cannot be accessed if its security group does not have SSH ports (22 by default) allowed. See [VPC Overview](/Network/VPC/en/overview/) for more details on how to allow SSH access. If a floating IP is not assigned to an instance, the instance cannot be accessed from outside NHN Cloud. See [VPC Overview](/Network/VPC/en/overview/) for more details on how to assign floating IP.

<a id="how-to-access-linux-instances-from-mac-or-linux-using-an-ssh-client"></a>
#### How to Access Linux Instances from Mac or Linux Using an SSH Client

Mac or Linux typically come with SSH clients installed by default. In the SSH client, you can connect using your key pair's private key as follows.

Ubuntu instance

	$ ssh -i my_private_key.pem ubuntu@<instance_IP>

Debian instance

	$ ssh -i my_private_key.pem debian@<instance_IP>

Rocky instance

	$ ssh -i my_private_key.pem rocky@<instance_IP>

<a id="how-to-access-linux-instances-from-windows-using-putty-ssh-client"></a>
#### How to Access Linux Instances from Windows Using PuTTY SSH Client

PuTTY SSH client is a popular SSH client program on Windows. Install [PuTTY](https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html) or [iPuTTY](https://github.com/iPuTTY/iPuTTY/releases/tag/l0.70i) with Korean patch applied.

To access a Linux instance from Windows using PuTTY SSH client, you must follow three steps:

* Convert your key pair's private key to a PuTTY-compatible private key
* Register your PuTTY-compatible private key in PuTTY
* Connect to the instance using PuTTY

##### 1. Convert Your Key Pair's Private Key to a PuTTY-Compatible Private Key

In PuTTY, you must convert the key pair's private key to PuTTY's private key format. Use puttygen, which is installed along with PuTTY, to convert the key.

![Image 1](http://static.toastoven.net/prod_instance/putty001.png)

At the bottom of the **PuTTY Key Generator** window under **Parameters**, select **RSA** for the **Type of key to generate**, and enter the default value '2048' bits for the **Number of bits in a generated key**. Under **Actions**, click **Load** next to **Load an existing private key file** to import your key pair's private key file.

![Image 2](http://static.toastoven.net/prod_instance/putty002.png)

Under **Actions**, click **Save private key** next to **Save the generated key** to save your key pair's private key converted for PuTTY. If you save the private key with the **Key passphrase** field left blank, a message appears asking **Save key in a format without a passphrase?**. To save the converted private key more securely, set a passphrase and save it.

> [Caution]
> You must not use a passphrase to configure automatic login to the instance. If you use a passphrase, you must enter the password for the private key directly when logging in.

##### 2. Register Your PuTTY-Compatible Private Key in PuTTY

The PuTTY-compatible private key created this way can be registered and used in two ways:

* Register and use an authentication private key file in PuTTY
* Register and use an authentication private key file with pageant (PuTTY Authentication Agent)

**A. Registering and Using an Authentication Private Key File in PuTTY**

Run PuTTY, select **Connection > SSH > Auth** from the left **Category**. Register your PuTTY-compatible private key in **Authentication private key file** under **Authentication parameters** on the right.

![Image 3](http://static.toastoven.net/prod_instance/putty005.png)

After registering the private key, if you save your connection information, you do not need to register the private key file again each time. For information on how to save connection information, see the connection method below.

**B. Registering and Using an Authentication Private Key File with pageant (PuTTY Authentication Agent)**

When you run pageant, which is installed along with PuTTY, the icon shown below appears in the Windows tray. Right-click the pageant icon and select **Add Key** to add your PuTTY-compatible private key.

![Image 4](http://static.toastoven.net/prod_instance/putty006.png)

To verify that a private key is added, select **View Keys**. If the key is added correctly, you can see the added key as shown in the figure below.

![Image 5](http://static.toastoven.net/prod_instance/putty008.png)

Once pageant is run, it remains in the Windows tray and continues to run, so you do not need to run it again each time you connect to an instance. However, if you restart Windows, you must run it again.

##### 3. Connect to an Instance Using PuTTY

If the private key converted for PuTTY is registered correctly, run PuTTY.

![Image 6](http://static.toastoven.net/prod_instance/putty009.png)

Use the **Host name** in the basic connection information as follows:

Ubuntu

	ubuntu@<instance_IP>

Debian

	debian@<instance_IP>

Rocky

	rocky@<instance_IP>

Set **Port** to 22 (SSH default port) and **Connection type** to **SSH**.

If all of the information is correct, save the session. Under **Load, save or delete a stored session**, enter the name of the session to save in the field under **Saved Sessions** and click **Save** to save the session. If you do not save the session, your private key settings registered in 2-A are also not preserved.

Now click **Open** to connect to the instance.

<a id="how-to-access-windows-instances"></a>
### How to Access Windows Instances { #how-to-access-windows-instances }

To access a Windows server, select the Windows instance to connect to in the NHN Cloud console. On the instance details screen, click the **Check password** button on the **Access Information** tab to check the password set on the Windows server.

The private key of the key pair you enter in **Check password** is not transmitted to the server and is only used to decrypt the password in the browser.

Click the **Connect** button next to **Check password** to download and run the .rdp file that contains the remote desktop connection settings. You will connect to the Windows server with the administrator ID of the Windows server and the password checked in the NHN Cloud console.

<a id="how-to-connect-serial-console"></a>
### How to Connect to Serial Console { #how-to-connect-serial-console }

In situations where SSH client cannot be used, such as boot failure and network configuration issues, you can connect to the serial console to access the instance.

The serial console function has the following limitations:

* Only one serial console connection per instance is allowed, and multiple connection attempts may not connect properly.
* Instances created with user-uploaded images or private images do not guarantee serial console access.
* Serial console connections can be accessed for a maximum of 10 minutes.
* Windows instances do not support the serial console feature.
* Instances created before the January 27, 2026 deployment require **Start Instance** after **Stop Instance**. The **Reboot Instance** function does not apply.

> [Caution]
> When you access an instance using the serial console and change boot settings, boot failure may occur, and you are responsible for the consequences.
> In normal situations, SSH client access is recommended.

<a id="how-to-connect-serial-console-change-grub-bootloader-settings"></a>
#### Change GRUB Bootloader Settings

To manipulate the bootloader on instances created before November 26, 2024 deployment, GRUB configuration is required.

Modify the GRUB configuration file.

```
$ sudo vi /etc/default/grub.d/50-cloudimg-settings.cfg
GRUB_TIMEOUT=3
GRUB_TERMINAL="console serial"
GRUB_SERIAL_COMMAND="serial --speed=9600 --unit=0 --word=8 --parity=no --stop=1"
````

Apply the changed configuration. Depending on the OS, the GRUB configuration application commands may vary.

```
$ sudo update-grub
```
