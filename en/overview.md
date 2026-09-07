<!-- machine_translated: true -->

<!-- pre-align:aligned sig=f2414300858d -->

<a id="compute-instance-overview"></a>
## Compute > Instance > Overview { #compute-instance-overview }

An instance is a virtual server composed of virtual CPU, memory, and root block storage. You can install your services or applications on this server and use them in combination with various services provided by NHN Cloud.

<a id="components"></a>
## Instance Components { #components }

The components that make up an instance are as follows:

- **Image**: A virtual disk containing the instance's operating system
- **Flavor**: The virtual hardware performance of the instance
- **Availability zone**: The physical location where the instance will be created
- **Key pair**: A key used as a means to access the instance
- **Security groups**: Network security settings for the instance
- **Network**: The virtual network to which the instance will be connected

Instance properties and usage change depending on these components. While settings for these components, with the exception of image and availability zone, can be modified after the creation of an instance, some flavors cannot be modified after an instance has been created. For more details on modifying instance flavors, see [Modify Flavor in the Console Guide](./console-guide/#modify-flavor).

<a id="image"></a>
### Image { #image }

An image is a virtual disk containing the operating system. NHN Cloud currently supports Debian, Ubuntu, Rocky, and Windows.

All images are configured to run optimally on an instance's virtual hardware and are safe to use as they have undergone security inspection by NHN Cloud. For more details on images, see [Image Overview](/Compute/Image/en/overview/).

<a id="flavor"></a>
### Instance Flavor { #flavor }

NHN Cloud provides various instance flavors to support a wide range of use cases. Instances can be created with flavors that best match the requirements of your services or applications. Flavors can be easily modified from the web console, even after an instance has been created.

| Flavor | Description |
|--------|-------------|
| m2 | A flavor with balanced CPU and memory settings. Use this when the performance requirements of your services or applications are not clear. |
| c2 | A flavor with high CPU performance. Use for web application servers or analysis systems that require high computational performance. |
| r2 | Use when memory usage is higher than other resources. Typically used for in-memory databases or cache servers. |
| t2 | An inexpensive flavor. Use for servers with low workloads. |
| u2 | The most inexpensive flavor. Use for servers with low workloads.<br>Since it uses local block storage, it is relatively less stable than other flavors but can be used at a lower cost.<br>This flavor does not guarantee I/O performance. |
| x1 | A flavor that supports high-performance CPU and memory. Use for services or applications that require high performance. |

<a id="availability-zone"></a>
### Availability Zone { #availability-zone }

NHN Cloud has divided the entire system into multiple availability zones to prepare for potential failures caused by physical hardware issues. Each availability zone has its own storage system, network switch, data center space, and power supply units. A failure that occurs within one availability zone does not affect other zones, thereby increasing the availability of the whole service. You can ensure increased service availability by creating instances across multiple availability zones.

The following characteristics exist between different availability zones:

- Instances created and distributed across multiple availability zones can communicate with each other over the network, and no network usage fees are incurred for this communication.
- Block storage can be shared among instances created in the same availability zone, but block storage cannot be shared between instances in different availability zones.
- Floating IPs can be shared across different availability zones. If a failure occurs in one availability zone, you can quickly move the floating IP to another availability zone to minimize downtime.

<a id="key-pair"></a>
### Key Pair { #key-pair }

A key pair is a pair of [PKI](https://en.wikipedia.org/wiki/Public_key_infrastructure)-based public and private SSH keys. To access an instance created in NHN Cloud, a key pair is required instead of keyboard-inputted ID/PW authentication, which is vulnerable to security attacks. You can safely access an instance once you have been authenticated after sending the instance your login information, encoded by your key pair's private key. For more details on how to access instances using key pairs, see [How to Access Instances](#how-to-access-instances).

Key pairs can be newly created in the NHN Cloud console when creating an instance, or you can register and use key pairs created by you. For more details on how to register key pairs, see [Import Key Pairs in the Console Guide](./console-guide/#import-key-pairs-windows).

> [Caution]
> When a key pair is newly generated, its private key is downloaded. As private keys are issued only once, be sure to store downloaded private keys in a safe disk or USB drive. If a private key is exposed, anyone can access the instance using the exposed private key, so it must be managed carefully.

> [Note]
> A key pair is a resource assigned to a user account, so it is retained and not deleted even when a project is deleted.

<a id="security-groups"></a>
### Security Groups { #security-groups }

A security group is a virtual firewall that determines the network traffic delivered to an instance. For more details on security groups, see [VPC Overview](/Network/VPC/en/overview/).

> [Note]
> The default security group is configured to ignore all inbound network traffic from outside. When accessing an instance via SSH, configure the security group to which the instance belongs to open the SSH port, and then access the instance.

<a id="network"></a>
### Network { #network }

For an instance to communicate with the outside, it must be connected to at least one network defined in the VPC. Instances that are not connected to a network cannot be accessed. To create or modify a network, see [VPC Overview](/Network/VPC/en/overview/).

<a id="pricing"></a>
## Pricing { #pricing }

Instance billing is as follows:

- Instances are billed from the moment they are created.
- An instance's root block storage is billed separately according to the block storage billing criteria.
- When an instance is stopped, a 90% discount is applied for 90 days according to the homepage rate. If the stopped state exceeds 90 days, the normal rate applies while maintaining the stopped state.
- Terminated instances are not billed.

For more details on billing, see the service-specific [Pricing page](https://www.toast.com/kr/service/compute/instance#price).

<a id="how-to-access-instances"></a>
## How to Access Instances { #how-to-access-instances }

<a id="how-to-access-linux-instances"></a>
### How to Access Linux Instances { #how-to-access-linux-instances }

You can access Linux instances using an SSH client. An instance cannot be accessed if its security group does not have SSH ports (22 by default) allowed. See [VPC Overview](/Network/VPC/en/overview/) for more details on how to allow SSH access. If a floating IP is not assigned to an instance, the instance cannot be accessed from outside NHN Cloud. See [VPC Overview](/Network/VPC/en/overview/) for more details on how to assign floating IP.

<a id="how-to-access-linux-instances-from-mac-or-linux-using-an-ssh-client"></a>
#### How to Access Linux Instances from Mac or Linux Using an SSH Client

SSH clients are typically installed by default on Mac or Linux. In the SSH client, access your instance using the private key of your key pair as follows:

Ubuntu instance

	$ ssh -i my_private_key.pem ubuntu@<Instance IP>

Debian instance

	$ ssh -i my_private_key.pem debian@<Instance IP>

Rocky instance

	$ ssh -i my_private_key.pem rocky@<Instance IP>

<a id="how-to-access-linux-instances-from-windows-using-putty-ssh-client"></a>
#### How to Access Linux Instances from Windows Using PuTTY SSH Client

PuTTY SSH client is a widely used SSH client program on Windows. Install [PuTTY](https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html) or [iPuTTY](https://github.com/iPuTTY/iPuTTY/releases/tag/l0.70i) with Korean patch applied.

To access a Linux instance from Windows using the PuTTY SSH client, follow three steps:

- Change the private key of the key pair to a PuTTY private key
- Register the PuTTY private key in PuTTY
- Access the instance with PuTTY

##### 1. Change the Private Key to a PuTTY Private Key

In PuTTY, you must convert the key pair private key to PuTTY's private key format. Use puttygen, which is installed with PuTTY, to convert the key.

![Image 1](http://static.toastoven.net/prod_instance/putty001.png)

At the bottom of the **PuTTY Key Generator** window under **Parameters**, select **RSA** for **Type of key to generate**, and enter the default value '2048' bits for **Number of bits in a generated key**. Under **Actions**, click **Load** next to **Load an existing private key file** to import your key pair's private key file.

![Image 2](http://static.toastoven.net/prod_instance/putty002.png)

Under **Actions**, click **Save private key** next to **Save the generated key** to save the key pair's private key converted for PuTTY. If you leave **Key passphrase** blank and save the private key, a message appears asking "Save this key without a passphrase?". To save the converted private key more securely, set a passphrase and save it.

> [Caution]
> To automatically log in to an instance, you must not use a passphrase. If you use a passphrase, you must enter the password for the private key manually when logging in.

##### 2. Register the PuTTY Private Key in PuTTY

The PuTTY private key created this way can be registered and used in two ways:

- Register an authentication private key file in PuTTY
- Register an authentication private key file in pageant (PuTTY Authentication Agent)

**A. Register an Authentication Private Key File in PuTTY**

Run PuTTY and select **Connection > SSH > Auth** in the left **Category**. Under **Authentication parameters** on the right, register the PuTTY private key in **Private key file for authentication**.

![Image 3](http://static.toastoven.net/prod_instance/putty005.png)

After registering the private key, if you save the access information, you do not need to register the private key file again each time. See the following access method for how to save access information.

**B. Register an Authentication Private Key File in pageant (PuTTY Authentication Agent)**

When you run pageant, which is installed with PuTTY, an icon appears in the Windows tray as shown below. Right-click the pageant icon and select **Add Key** to add your PuTTY-compatible private key.

![Image 4](http://static.toastoven.net/prod_instance/putty006.png)

To verify that the private key has been added, select **View Keys**. If the key is added correctly, the added key appears as shown below.

![Image 5](http://static.toastoven.net/prod_instance/putty008.png)

Once pageant is run, it remains in the Windows tray and continues to run, so you do not need to run it again each time you access an instance. However, if you restart Windows, you must run it again.

##### 3. Access the Instance with PuTTY

If the private key converted for PuTTY has been registered correctly, run PuTTY.

![Image 6](http://static.toastoven.net/prod_instance/putty009.png)

The **Host Name** for basic access information is as follows:

Ubuntu

	ubuntu@<Instance IP>

Debian

	debian@<Instance IP>

Rocky

	rocky@<Instance IP>

Set **Port** to 22, the default SSH port, and set **Connection type** to **SSH**.

If all the information is correct, save the session. Under **Load, save or delete a stored session**, enter the name of the session to save in **Saved Sessions** and click **Save** to save the session. If you do not save the session, the private key settings registered in 2-A are also not preserved.

Now click **Open** to access the instance.

<a id="how-to-access-windows-instances"></a>
### How to Access Windows Instances { #how-to-access-windows-instances }

To access a Windows server, select the Windows instance you want to access in the NHN Cloud console. In the **Connection Information** tab on the instance details page, click the **Confirm Password** button to check the password set on the Windows server.

The private key of the key pair that you enter in **Confirm Password** is not sent to the server, but is used only to decrypt the password in the browser.

Click the **Connect** button next to **Confirm Password** to receive and run the .rdp file with the remote desktop access settings saved. The Windows server ID is `Administrator`, and use the password you confirmed in the NHN Cloud console as the password.

<a id="how-to-connect-serial-console"></a>
### How to Connect to the Serial Console { #how-to-connect-serial-console }

In situations where you cannot use an SSH client, such as boot failures or network configuration issues, you can connect to the serial console to access your instance.

The serial console feature has the following limitations:

- Only one serial console connection per instance is possible, and multiple connection attempts may not connect properly.
- Instances created with user-uploaded images or private images do not guarantee serial console access.
- Serial console connection is accessible for a maximum of 10 minutes.
- Windows instances do not support the serial console feature.
- For instances created before the deployment on January 27, 2026, you must **Stop the instance** and then **Start the instance**. The **Reboot instance** function does not apply.

> [Caution]
> You may encounter boot failures if you change boot methods through the serial console, and you are responsible for the resulting consequences.
> For normal situations, it is recommended to use SSH client access.

<a id="how-to-connect-serial-console-change-grub-bootloader-settings"></a>
#### Change GRUB Bootloader Settings

For instances created before the deployment on November 26, 2024, GRUB settings are required to manipulate the bootloader.

Modify the GRUB configuration file.

```
$ sudo vi /etc/default/grub.d/50-cloudimg-settings.cfg
GRUB_TIMEOUT=3
GRUB_TERMINAL="console serial"
GRUB_SERIAL_COMMAND="serial --speed=9600 --unit=0 --word=8 --parity=no --stop=1"
````

Apply the changed settings. The GRUB configuration application command may differ depending on the OS.

```
$ sudo update-grub
```
