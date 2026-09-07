<!-- machine_translated: true -->

<!-- pre-align:aligned sig=f2414300858d -->

<a id="compute-instance-overview"></a>
## Compute > Instance > Overview { #compute-instance-overview }

An instance is a virtual server consisting of virtual CPU, memory, and root block storage. You can install your services or applications on this server and use them in combination with various services provided by NHN Cloud.

<a id="components"></a>
## Instance components { #components }

The components that make up an instance are as follows:

- **Image**: A virtual disk containing the instance's operating system
- **Flavor**: The virtual hardware performance of the instance
- **Availability Zone (AZ)**: The physical location where the instance is created
- **Key pair**: A key used as a means of accessing the instance
- **Security groups**: Network security settings for the instance
- **Network**: The virtual network to which the instance is connected

Instance properties and usage change depending on these components. While settings for these components, with the exception of image and availability zone, can be modified after the creation of an instance, some flavors cannot be modified after an instance has been created. For more details on modifying instance flavors, see [Modify Flavor in the Console Guide](./console-guide/#modify-flavor).

<a id="image"></a>
### Image { #image }

An image is a virtual disk containing an operating system. NHN Cloud currently supports Debian, Ubuntu, Rocky, and Windows.

All images are configured to run optimally on an instance's virtual hardware and are safe to use as they have undergone security inspection by NHN Cloud. For more details on images, see [Image Overview](/Compute/Image/en/overview/).

<a id="flavor"></a>
### Instance flavor { #flavor }

NHN Cloud provides various instance flavors to support a wide range of use cases. Instances can be created with flavors that best match the requirements of your services or applications. Flavors can be easily modified from the web console, even after an instance has been created.

| Flavor    | Description                                                                                                                                               |
| ------- |--------------------------------------------------------------------------------------------------------------------------------------------------|
| m2 | This flavor has a balanced configuration of CPU and memory. Use this when the performance requirements of your services or applications are not clear.                                                                               |
| c2 | This flavor has high CPU performance. Use this for web application servers or analytics systems that require high computational performance.                                                                           |
| r2 | Use this when you need a high memory capacity relative to other resources. It is typically used for in-memory databases or cache servers.                                                                               |
| t2 | This is a cost-effective flavor. Use this for servers with low workloads.                                                                                                          |
| u2 | This is the most cost-effective flavor. Use this for servers with low workloads.<br>Because it uses local block storage, it is relatively less stable than other flavors, but can be used at a lower cost.<br>This flavor does not guarantee I/O performance. |
| x1 | This flavor supports high-performance CPU and memory. Use this for services or applications that require high performance.                                                                                        |

<a id="availability-zone"></a>
### Availability Zone { #availability-zone }

NHN Cloud has divided the entire system into multiple availability zones to prepare for potential failures caused by physical hardware issues. Each availability zone has its own storage system, network switch, data center space, and power supply units. A failure that occurs within one availability zone does not affect other zones, thereby increasing the availability of the whole service. You can ensure increased service availability by creating instances across multiple availability zones.

Availability zones have the following characteristics:

- Instances created across multiple availability zones can communicate with each other over the network, and no network usage charges are incurred for this communication.
- Block storage can be shared between instances in the same availability zone, but block storage cannot be shared between different availability zones.
- Floating IPs can be shared across different availability zones. If one availability zone experiences a failure, you can quickly migrate the floating IP to another availability zone to minimize downtime.

<a id="key-pair"></a>
### Key pair { #key-pair }

A key pair is a pair of PKI-based public and private SSH keys. To access an instance created in NHN Cloud, a key pair is required instead of keyboard-inputted ID/PW authentication, which is vulnerable to security attacks. You can safely access an instance once you have been authenticated after sending the instance your login information, encoded by your key pair's private key. For more details on how to access instances using key pairs, see [How to Access Instances](#how-to-access-instances).

Key pairs can be created directly in the NHN Cloud console when you create an instance, or you can import and use your own key pair. For information on how to import key pairs, see [Import Key Pairs in the Console Guide](./console-guide/#import-key-pairs-windows).

> [Caution]
> When a key pair is newly generated, its private key is downloaded. As private keys are issued only once, be sure to store downloaded private keys in a safe disk or USB drive. If a private key is exposed, anyone can access the instance using the exposed private key, so it must be managed carefully.

> [Note]
> Key pairs are resources assigned to a user account, so they are not deleted even if you delete the project.

<a id="security-groups"></a>
### Security groups { #security-groups }

A security group is a virtual firewall that determines the network traffic delivered to an instance. For more details on security groups, see [VPC Overview](/Network/VPC/en/overview/).

> [Note]
> The default security group is configured to ignore all inbound network traffic from outside. When accessing an instance via SSH, set the security group of the instance to open the SSH port before accessing the instance.

<a id="network"></a>
### Network { #network }

For an instance to communicate with the outside world, it must be connected to at least one network defined in the VPC. Instances that are not connected to a network cannot be accessed. To create or modify a network, see [VPC Overview](/Network/VPC/en/overview/).

<a id="pricing"></a>
## Billing { #pricing }

Instance billing is as follows:

* Billing for an instance starts from the moment it is created.
* The instance's root block storage is billed separately according to block storage billing standards.
* When an instance is stopped, a 90% discount is applied for 90 days based on the homepage pricing. If the stopped state exceeds 90 days, normal pricing is applied while maintaining the stopped state.
* Terminated instances are not billed.

For more details on billing, see the [Pricing page](https://www.toast.com/kr/service/compute/instance#price) for each service.

<a id="how-to-access-instances"></a>
## How to access instances { #how-to-access-instances }

<a id="how-to-access-linux-instances"></a>
### How to access Linux instances { #how-to-access-linux-instances }

You can access your Linux instances using an SSH client. An instance cannot be accessed if its security group does not have SSH ports (22 by default) allowed. See [VPC Overview](/Network/VPC/en/overview/) for more details on how to allow SSH access. If a floating IP is not assigned to an instance, the instance cannot be accessed from outside NHN Cloud. See [VPC Overview](/Network/VPC/en/overview/) for more details on how to assign floating IP.

<a id="how-to-access-linux-instances-from-mac-or-linux-using-an-ssh-client"></a>
#### How to access Linux instances from Mac or Linux using an SSH client

SSH clients are typically installed by default on Mac and Linux. Use the SSH client to access the instance with your key pair's private key as follows:

Ubuntu instance

	$ ssh -i my_private_key.pem ubuntu@<instance_IP>

Debian instance

	$ ssh -i my_private_key.pem debian@<instance_IP>

Rocky instance

	$ ssh -i my_private_key.pem rocky@<instance_IP>

<a id="how-to-access-linux-instances-from-windows-using-putty-ssh-client"></a>
#### How to access Linux instances from Windows using PuTTY SSH client

PuTTY SSH client is a widely used SSH client program on Windows. Install [PuTTY](https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html) or [iPuTTY](https://github.com/iPuTTY/iPuTTY/releases/tag/l0.70i) with Korean language patch applied.

To access Linux instances from Windows using the PuTTY SSH client, follow these three steps:

* Convert the key pair's private key to PuTTY format
* Register the PuTTY private key in PuTTY
* Connect to the instance using PuTTY

##### 1. Convert the key pair's private key to PuTTY format

PuTTY requires that you convert the key pair's private key to PuTTY's private key format. Use puttygen, which is installed along with PuTTY, to convert the key.

![Image1](http://static.toastoven.net/prod_instance/putty001.png)

At the bottom of the **PuTTY Key Generator** window under **Parameters**, select **RSA** for the **Type of key to generate**, and enter the default value '2048' bits for the **Number of bits in a generated key**. Under **Actions**, click **Load** next to **Load an existing private key file** to import your key pair's private key file.

![Image2](http://static.toastoven.net/prod_instance/putty002.png)

Under **Actions**, click **Save private key** next to **Save the generated key** to save the converted key pair private key for PuTTY. If you leave the **Key passphrase** blank and save the private key, a message appears asking "Save this key without a passphrase to protect it?" To save the converted private key more securely, set a passphrase and save it.

> [Caution]
> To enable automatic login to the instance, you must not use a passphrase. If you use a passphrase, you must enter a password for the private key each time you log in.

##### 2. Register the PuTTY private key in PuTTY

The PuTTY private key created this way can be used in two ways:

* Register the private key file in PuTTY's authentication settings
* Register the private key file in pageant (PuTTY Authentication Agent)

**A. Register the private key in PuTTY's authentication settings**

Run PuTTY and select **Connection > SSH > Auth** in the left **Category**. Under **Authentication parameters** on the right, register your PuTTY private key in **Private key file for authentication**.

![Image3](http://static.toastoven.net/prod_instance/putty005.png)

After registering the private key, if you save your connection information, you do not need to register the private key file again each time you connect. For information on how to save connection information, see the connection method below.

**B. Register the private key in pageant (PuTTY Authentication Agent)**

When you run pageant, which is installed along with PuTTY, the icon shown below appears in the Windows tray. Right-click the pageant icon and select **Add Key** to add your PuTTY-compatible private key.

![Image4](http://static.toastoven.net/prod_instance/putty006.png)

To verify that the private key has been added, select **View Keys**. If the key was added successfully, it appears as shown in the image below.

![Image5](http://static.toastoven.net/prod_instance/putty008.png)

Once pageant is run, it continues to run in the Windows tray, so you do not need to run it again each time you connect to the instance. However, you must run it again if you restart Windows.

##### 3. Connect to the instance using PuTTY

If the private key converted for PuTTY has been registered successfully, run PuTTY.

![Image6](http://static.toastoven.net/prod_instance/putty009.png)

Use the following for the **Host Name** in the basic connection information:

Ubuntu

	ubuntu@<instance_IP>

Debian

	debian@<instance_IP>

Rocky

	rocky@<instance_IP>

Set the **Port** to 22, which is the default SSH port, and set the **Connection type** to **SSH**.

If all of the information is correct, save the session. Under **Load, save or delete a stored session**, enter the name of the session to save in the field under **Saved Sessions** and click **Save** to save the session. If you do not save the session, your private key settings registered in 2-A are also not preserved.

Now click **Open** to connect to the instance.

<a id="how-to-access-windows-instances"></a>
### How to access Windows instances { #how-to-access-windows-instances }

To access a Windows server, select the Windows instance you want to access from the NHN Cloud console. On the **Connection Information** tab of the instance details screen, click **View Password** to view the password set on the Windows server.

The private key you enter in **View Password** is not sent to the server; it is only used by the browser to decrypt the password.

Click the **Connect** button next to **View Password** to receive and run the .rdp file with remote desktop connection settings saved. The Windows server login ID is `Administrator`, and use the password you viewed in the NHN Cloud console.

<a id="how-to-connect-serial-console"></a>
### How to connect to serial console { #how-to-connect-serial-console }

You can access an instance through the serial console in situations where you cannot use an SSH client, such as boot failures or network configuration issues.

The serial console feature has the following limitations:

* Only one serial console connection per instance is possible; multiple connection attempts may not connect properly.
* Instances created from user-uploaded images and private images do not guarantee serial console access.
* Serial console connections can be accessed for up to 10 minutes.
* Windows instances do not support the serial console feature.
* For instances created before January 27, 2026, you must **Stop Instance** and then **Start Instance**. The **Reboot Instance** feature does not apply the changes.

> [Caution]
> If you change boot settings through the serial console, boot failure may occur, and you are responsible for the consequences. In normal situations, it is recommended that you use SSH client access.

<a id="how-to-connect-serial-console-change-grub-bootloader-settings"></a>
#### Change GRUB bootloader settings

For instances created before November 26, 2024, GRUB configuration is required to manipulate the bootloader.

Edit the GRUB configuration file.

```
$ sudo vi /etc/default/grub.d/50-cloudimg-settings.cfg
GRUB_TIMEOUT=3
GRUB_TERMINAL="console serial"
GRUB_SERIAL_COMMAND="serial --speed=9600 --unit=0 --word=8 --parity=no --stop=1"
````

Apply the changed settings. The GRUB configuration application command may vary depending on the OS.

```
$ sudo update-grub
```
