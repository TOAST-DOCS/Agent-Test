<!-- machine_translated: true -->

<!-- pre-align:aligned sig=f2414300858d -->

<a id="compute-instance-overview"></a>
## Compute > Instance > Overview { #compute-instance-overview }

An instance is a virtual server composed of virtual CPU, memory, and root block storage. You can install your services or applications on this server and use them in combination with various services provided by NHN Cloud.

<a id="components"></a>
## Instance Components { #components }

The components that make up an instance are as follows:

- **Image**: A virtual disk that contains the instance's operating system
- **Flavor**: The virtual hardware performance of the instance
- **Availability zone**: The physical location where the instance will be created
- **Key pair**: A key that is used to access the instance
- **Security groups**: Network security settings for the instance
- **Network**: The virtual network to which the instance will be connected

Instance properties and usage change depending on these components. Of these components, all settings except image and availability zone can be modified after instance creation. However, some instance flavors cannot be modified after instance creation. For more details on modifying instance flavors, see [Modify Flavor in the Console Guide](./console-guide/#modify-flavor).

<a id="image"></a>
### Image { #image }

An image is a virtual disk that contains an operating system. NHN Cloud currently supports Debian, Ubuntu, Rocky, and Windows.

All images are configured to run optimally on an instance's virtual hardware and are safe to use as they have undergone security inspection by NHN Cloud. For more details on images, see [Image Overview](/Compute/Image/en/overview/).

<a id="flavor"></a>
### Instance flavor { #flavor }

NHN Cloud provides various instance flavors to support a wide range of use cases. Instances can be created with flavors that best match the requirements of your services or applications. Flavors can be easily modified from the web console, even after an instance has been created.

| Flavor    | Description                                                                                                                                               |
| ------- |--------------------------------------------------------------------------------------------------------------------------------------------------|
| m2 | A flavor with balanced CPU and memory settings. Use this when the performance requirements of your services or applications are not clearly defined.                                                                               |
| c2 | A flavor with high CPU performance. Use this for high-performance web application servers or analytical systems that require high computational performance.                                                                           |
| r2 | A flavor used when memory usage is high compared to other resources. Typically used for in-memory databases or cache servers.                                                                               |
| t2 | An inexpensive flavor. Use this for servers with low workloads.                                                                                                          |
| u2 | The most inexpensive flavor. Use this for servers with low workloads.<br>Because it uses local block storage, it has relatively lower stability than other flavors, but can be used at a lower price.<br>This flavor does not guarantee I/O performance. |
| x1 | A flavor that supports high-end CPU and memory. Use this for services or applications that require high performance.                                                                                        |

<a id="availability-zone"></a>
### Availability zone { #availability-zone }

NHN Cloud has divided the entire system into multiple availability zones to prepare for potential failures caused by physical hardware issues. Each availability zone has its own storage system, network switch, data center space, and power supply units. A failure that occurs within one availability zone does not affect other zones, thereby increasing the availability of the whole service. You can ensure increased service availability by creating instances across multiple availability zones.

The characteristics between different availability zones are as follows:

- Instances created across multiple availability zones can communicate with each other over the network, and no network usage charges are incurred for this communication.
- Block storage can be shared between instances in the same availability zone, but cannot be shared across different availability zones.
- Floating IPs can be shared across different availability zones. If one availability zone fails, you can quickly move the floating IP to another availability zone to minimize downtime.

<a id="key-pair"></a>
### Key pair { #key-pair }

A key pair is a pair of PKI-based public and private SSH keys. To access an instance created in NHN Cloud, a key pair is required instead of keyboard-inputted ID/PW authentication, which is vulnerable to security attacks. You can safely access an instance once you have been authenticated after sending the instance your login information, encoded by your key pair's private key. For more details on how to access instances using key pairs, see [How to Access Instances](#how-to-access-instances).

Key pairs can be created new in the NHN Cloud console when creating an instance, or you can register and use key pairs that you have created yourself. For more details on how to import key pairs, see [Import Key Pairs in the Console Guide](./console-guide/#import-key-pairs-windows).

> [Caution]
> When a key pair is newly generated, its private key is downloaded. As private keys are issued only once, be sure to store downloaded private keys in a safe disk or USB drive. If a private key is exposed, anyone can access the instance using the exposed private key, so it must be managed carefully.

> [Note]
> Key pairs are resources assigned to a user account and are retained even if the project is deleted.

<a id="security-groups"></a>
### Security groups { #security-groups }

A security group is a virtual firewall that determines the network traffic delivered to an instance. For more details on security groups, see [VPC Overview](/Network/VPC/en/overview/).

> [Note]
> The default security group is configured to ignore all inbound network traffic from outside. When accessing an instance via SSH, configure the security group that the instance belongs to to open SSH ports before accessing the instance.

<a id="network"></a>
### Network { #network }

For an instance to communicate with external systems, it must be connected to at least one network defined in VPC. An instance that is not connected to a network cannot be accessed. To create or modify a network, see [VPC Overview](/Network/VPC/en/overview/).

<a id="pricing"></a>
## Billing { #pricing }

Billing for instances is as follows:

* Instances are charged from the moment they are created.
* Instance root block storage is charged separately based on block storage billing criteria.
* When an instance is stopped, a 90% discount off the homepage rate is applied for 90 days. If the stopped state exceeds 90 days, the full billing rate is applied while maintaining the stopped state.
* Terminated instances are not charged.

For more details on billing, see the [Pricing page](https://www.toast.com/kr/service/compute/instance#price) for each service.

<a id="how-to-access-instances"></a>
## How to Access Instances { #how-to-access-instances }

<a id="how-to-access-linux-instances"></a>
### How to Access Linux Instances { #how-to-access-linux-instances }

You can access your Linux instances using an SSH client. An instance cannot be accessed if its security group does not have SSH ports (22 by default) allowed. See [VPC Overview](/Network/VPC/en/overview/) for more details on how to allow SSH access. If a floating IP is not assigned to an instance, the instance cannot be accessed from outside NHN Cloud. See [VPC Overview](/Network/VPC/en/overview/) for more details on how to assign floating IP.

<a id="how-to-access-linux-instances-from-mac-or-linux-using-an-ssh-client"></a>
#### How to Access Linux Instances from Mac or Linux Using an SSH Client

Mac and Linux typically have SSH clients installed by default. Use the SSH client to access an instance using your key pair's private key as follows:

Ubuntu instance

	$ ssh -i my_private_key.pem ubuntu@<instance-ip>

Debian instance

	$ ssh -i my_private_key.pem debian@<instance-ip>

Rocky instance

	$ ssh -i my_private_key.pem rocky@<instance-ip>

<a id="how-to-access-linux-instances-from-windows-using-putty-ssh-client"></a>
#### How to Access Linux Instances from Windows Using PuTTY SSH Client

PuTTY SSH Client is a popular SSH client program for Windows. Install [PuTTY](https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html) or [iPuTTY](https://github.com/iPuTTY/iPuTTY/releases/tag/l0.70i) with Korean localization applied.

To access a Linux instance from Windows using PuTTY SSH Client, you need to follow three steps:

* Convert the key pair's private key to a PuTTY-compatible private key
* Register the PuTTY-compatible private key with PuTTY
* Access the instance using PuTTY

##### 1. Convert the key pair's private key to a PuTTY-compatible private key

In PuTTY, you must convert the key pair's private key to PuTTY's private key format. Use puttygen, which is installed with PuTTY, to convert the key.

![Image 1](http://static.toastoven.net/prod_instance/putty001.png)

At the bottom of the **PuTTY Key Generator** window under **Parameters**, select **RSA** for the **Type of key to generate**, and enter the default value '2048' bits for the **Number of bits in a generated key**. Under **Actions**, click **Load** next to **Load an existing private key file** to import your key pair's private key file.

![Image 2](http://static.toastoven.net/prod_instance/putty002.png)

Under **Actions**, click **Save private key** next to **Save the generated key** to save your key pair's private key converted for PuTTY. If you leave the **Key passphrase** field empty and save the private key, a message appears asking "Save the key without a passphrase?". To save the converted private key more securely, set and save a passphrase.

> [Caution]
> To set up automatic login to the instance, you must not use a passphrase. If you use a passphrase, you must enter the password for the private key each time you log in.

##### 2. Register the PuTTY-compatible private key with PuTTY

The PuTTY-compatible private key you have created can be registered and used in two ways:

* Register the authentication private key file in PuTTY
* Register the authentication private key file with pageant (PuTTY Authentication Agent)

**A. How to register the authentication private key file in PuTTY and use it**

Run PuTTY and select **Connection > SSH > Auth** in the left **Category**. Register the PuTTY-compatible private key under **Private key file for authentication** in the **Authentication parameters** on the right.

![Image 3](http://static.toastoven.net/prod_instance/putty005.png)

After registering the private key, if you save the connection information, you do not need to register the private key file again each time. See the following access method for how to save connection information.

**B. How to register the authentication private key file with pageant (PuTTY Authentication Agent) and use it**

When you run pageant, which is installed along with PuTTY, the icon shown below appears in the Windows tray. Right-click the pageant icon and select **Add Key** to add your PuTTY-compatible private key.

![Image 4](http://static.toastoven.net/prod_instance/putty006.png)

To verify that the private key has been added, select **View Keys**. If the key has been added successfully, you can see the added key as shown below.

![Image 5](http://static.toastoven.net/prod_instance/putty008.png)

Once pageant runs, it continues to run in the Windows tray, so you do not need to run it again each time you access the instance. However, if you restart Windows, you must run it again.

##### 3. Access the instance using PuTTY

If the private key converted for PuTTY has been registered correctly, run PuTTY.

![Image 6](http://static.toastoven.net/prod_instance/putty009.png)

Use the **Host name** in the basic connection information as follows:

Ubuntu

	ubuntu@<instance-ip>

Debian

	debian@<instance-ip>

Rocky

	rocky@<instance-ip>

Set the **Port** to 22, which is the default SSH port, and set the **Connection type** to **SSH**.

If all of the information is correct, save the session. Under **Load, save or delete a stored session**, enter the name of the session to save in the field under **Saved Sessions** and click **Save** to save the session. If you do not save the session, your private key settings registered in 2-A are also not preserved.

Now click **Open** to access the instance.

<a id="how-to-access-windows-instances"></a>
### How to Access Windows Instances { #how-to-access-windows-instances }

To access a Windows server, select the Windows instance you want to access in the NHN Cloud console. On the **Connection Information** tab in the instance details screen, click **Confirm Password** to verify the password set on the Windows server.

The private key of the key pair that you input in **Confirm Password** is not transmitted to the server and is only used to decrypt the password in the browser.

Click the **Connect** button next to **Confirm Password** to download and run the .rdp file with remote desktop access settings saved. This allows you to access the Windows server. The ID of the Windows server is `Administrator`, and the password is the one you confirmed in the NHN Cloud console.

<a id="how-to-connect-serial-console"></a>
### How to Connect to Serial Console { #how-to-connect-serial-console }

If you cannot use an SSH client due to boot failures or network configuration issues, you can access the instance by connecting to the serial console.

The serial console function has the following limitations:

* Only one serial console connection per instance is possible. Multiple connection attempts may not connect properly.
* Instances created from user-uploaded images or personal images do not guarantee serial console access.
* Serial console connections can be accessed for a maximum of 10 minutes.
* Windows instances do not support the serial console function.
* For instances created before the deployment on January 27, 2026, **stop the instance** and then **start the instance** is required. The **reboot instance** function does not apply these settings.

> [Caution]
> You may experience boot failures if you change boot settings by accessing the instance via serial console, and you are responsible for any consequences that result.
> For normal situations, it is recommended to use SSH client access.

<a id="how-to-connect-serial-console-change-grub-bootloader-settings"></a>
#### Modify GRUB Bootloader Settings

GRUB configuration is required to manipulate the bootloader on instances created before the deployment on November 26, 2024.

Modify the GRUB configuration file.

```
$ sudo vi /etc/default/grub.d/50-cloudimg-settings.cfg
GRUB_TIMEOUT=3
GRUB_TERMINAL="console serial"
GRUB_SERIAL_COMMAND="serial --speed=9600 --unit=0 --word=8 --parity=no --stop=1"
````

Apply the changed settings. The GRUB configuration command may differ depending on the OS.

```
$ sudo update-grub
```
