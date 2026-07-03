<a id="compute-instance-overview"></a>
## Compute > Instance > Overview

An instance is a virtual server composed of virtual CPU, memory, and root block storage. You can install your services or applications on this server and use it in combination with various services provided by NHN Cloud.

<a id="components"></a>
## Instance Components

The components that make up an instance are as follows.

- **Image**: A virtual disk containing the instance's operating system
- **Type (flavor)**: The virtual hardware performance of the instance
- **Availability Zone (AZ)**: The physical location where the instance will be created
- **Key Pair**: Keys used as a means of accessing the instance
- **Security Groups**: Instance network security settings
- **Network**: The virtual network to which the instance will be connected

Instance properties and usage change depending on these components. While settings for these components, with the exception of image and availability zone, can be modified after the creation of an instance, some instance types (flavors) cannot be modified after an instance has been created. For more details on modifying instance types, see [Modify Flavor in the Console Guide](./console-guide/#modify-flavor).

<a id="image"></a>
### Image

An image is a virtual disk containing an operating system. NHN Cloud currently supports Debian, Ubuntu, Rocky, and Windows.

All images are configured to run optimally on an instance's virtual hardware and are safe to use as they have undergone security inspection by NHN Cloud. For more details on images, see [Image Overview](/Compute/Image/en/overview/).

<a id="flavor"></a>
### Instance Flavor

NHN Cloud provides various instance flavors to support a wide range of use cases. Instances can be created with flavors that best match the requirements of your services or applications. Flavors can be easily modified from the web console, even after an instance has been created.

| Type    | Description                                                                                                                                               |
| ------- |-----------------------------------------------------------------------------------------------------------------------------------------------------------|
| m2 | A balanced type with CPU and memory configured evenly. Use when the performance requirements of your service or application are not clearly defined. |
| c2 | A type with high CPU performance. Used for high-performance web application servers or analysis systems. |
| r2 | Used when memory usage is high compared to other resources. Typically used for in-memory databases or cache servers. |
| t2 | An inexpensive instance type. Used for servers with low workloads. |
| u2 | The most inexpensive instance type. Used for servers with low workloads.<br>Since it uses local block storage, it has relatively lower stability than other instances, but can be used at a lower price.<br>This type of instance does not guarantee I/O performance. |
| x1 | A type that supports high-spec CPU and memory. Used for services or applications requiring high performance. |

<a id="availability-zone"></a>
### Availability Zone

NHN Cloud has divided the entire system into multiple availability zones to prepare for potential failures caused by physical hardware issues. Each availability zone has its own storage system, network switch, data center space, and power supply units. A failure that occurs within one availability zone does not affect other zones, thereby increasing the availability of the whole service. You can ensure increased service availability by creating instances across multiple availability zones.

The characteristics between different availability zones are as follows.

- Instances distributed across multiple availability zones can communicate with each other over the network, and no network usage charges are incurred for such communication.
- Block storage can be shared between instances created in the same availability zone, but block storage cannot be shared between different availability zones.
- Floating IPs can be shared across different availability zones. If one availability zone experiences an outage, you can quickly move the floating IP to another availability zone to minimize downtime.

<a id="key-pair"></a>
### Key Pair

A key pair is a pair of [PKI](https://en.wikipedia.org/wiki/Public_key_infrastructure)-based public and private SSH keys. To access an instance created in NHN Cloud, a key pair is required instead of keyboard-inputted ID/password authentication, which is vulnerable to security attacks. You can safely access an instance once you have been authenticated after sending the instance your login information, encoded by your key pair's private key. For more details on how to access instances using key pairs, see [How to Access Instances](#how-to-access-instances).

You can create a new key pair in the NHN Cloud console when creating an instance, or you can register and use a key pair created by yourself. For more details on how to register a key pair, see [Import Key Pairs in the Console Guide](./console-guide/#import-key-pairs-windows).

> [Caution]
> When a key pair is newly generated, its private key is downloaded. As private keys are issued only once, be sure to store downloaded private keys in a safe disk or USB drive. If a private key is exposed, anyone can access the instance using the exposed private key, so it must be managed carefully.

> [Note]
> A key pair is a resource assigned to a user account, so it is retained and not deleted even when a project is deleted.

<a id="security-groups"></a>
### Security Groups

Security groups are virtual firewalls that determine the network traffic delivered to an instance. For more details on security groups, see [VPC Overview](/Network/VPC/en/overview/).

> [Note]
> The default security group is configured to ignore all inbound network traffic from outside. When accessing an instance via SSH, you must first configure the security group that the instance belongs to to allow SSH port access.

<a id="network"></a>
### Network

To communicate with the outside world, an instance must be connected to at least one of the networks defined in the VPC. An instance that is not connected to a network cannot be accessed. To create or modify a network, see [VPC Overview](/Network/VPC/en/overview/).

<a id="pricing"></a>
## Billing

Instances are charged as follows.

* Instances are charged from the moment of creation.
* Instance root block storage is charged separately from the instance based on block storage billing standards.
* When an instance is stopped, a 90% discount from the website rates is applied for 90 days. If the stopped state exceeds 90 days, normal rates apply while maintaining the stopped state.
* Terminated instances are not charged.

For more details on billing, see the [Pricing page](https://www.toast.com/kr/service/compute/instance#price) by service.

<a id="how-to-access-instances"></a>
## How to Access Instances

<a id="how-to-access-linux-instances"></a>
### How to Access Linux Instances

You can access your Linux instances using an SSH client. An instance cannot be accessed if its security group does not have SSH ports (22 by default) allowed. See [VPC Overview](/Network/VPC/en/overview/) for more details on how to allow SSH access. If a floating IP is not assigned to an instance, the instance cannot be accessed from outside NHN Cloud. See [VPC Overview](/Network/VPC/en/overview/) for more details on how to assign floating IP.

#### How to Access a Linux Instance Using SSH Client on Mac or Linux

SSH clients are usually installed by default on Mac or Linux. You can access your instance using the private key of your key pair in the SSH client as follows.

Ubuntu instance

	$ ssh -i my_private_key.pem ubuntu@<instance IP>

Debian instance

	$ ssh -i my_private_key.pem debian@<instance IP>

Rocky instance

	$ ssh -i my_private_key.pem rocky@<instance IP>

#### How to Access a Linux Instance Using PuTTY SSH Client on Windows

PuTTY SSH Client is a widely used SSH client program on Windows. Install [PuTTY](https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html) or [iPuTTY](https://github.com/iPuTTY/iPuTTY/releases/tag/l0.70i) with Korean localization.

To access a Linux instance using PuTTY SSH Client on Windows, you need to follow three steps.

* Convert the key pair's private key to PuTTY-compatible private key
* Register the PuTTY-compatible private key in PuTTY
* Access the instance using PuTTY

##### 1. Convert the Key Pair's Private Key to PuTTY-Compatible Private Key

In PuTTY, the key pair's private key must be converted to PuTTY's private key format. Key conversion is done using puttygen, which is installed with PuTTY.

![image1](http://static.toastoven.net/prod_instance/putty001.png)

At the bottom of the **PuTTY Key Generator** dialog, under **Parameters**, select **RSA** for **Type of key to generate**, and enter the default value '2048' bits for **Number of bits in a generated key**. Under **Actions**, click **Load** next to **Load an existing private key file** to import your key pair's private key file.

![image2](http://static.toastoven.net/prod_instance/putty002.png)

Under **Actions**, click **Save private key** next to **Save the generated key** to save the key pair's private key converted for PuTTY. If you save the private key with **Key passphrase** left blank, a message appears asking, **Do you really want to save this key without a passphrase to protect it?**. To save the converted private key more securely, set a passphrase and save it.

> [Caution]
> To set up automatic login to the instance, you must not use a passphrase. If you use a passphrase, you will need to manually enter the password for the private key when logging in.

##### 2. Register the PuTTY-Compatible Private Key in PuTTY

The PuTTY-compatible private key created this way can be registered and used in two ways.

* Method 1: Register an authentication private key file in PuTTY
* Method 2: Register an authentication private key file in pageant (PuTTY Authentication Agent)

**A. Register an Authentication Private Key File in PuTTY**


Run PuTTY and select **Connection > SSH > Auth** from the **Category** on the left. Register the PuTTY-compatible private key in **Private key file for authentication** under **Authentication parameters** on the right.

![image3](http://static.toastoven.net/prod_instance/putty005.png)

After registering the private key, if you save the connection information, you don't need to register the private key file again each time. For more details on saving connection information, see the access method below.


**B. Register an Authentication Private Key File in pageant (PuTTY Authentication Agent)**


When you run pageant, which is installed along with PuTTY, an icon appears in the Windows tray as shown below. Right-click the pageant icon and select **Add Key** to add your PuTTY-compatible private key.

![image4](http://static.toastoven.net/prod_instance/putty006.png)

To verify that the private key has been added, select **View Keys**. If the key has been added successfully, the added key appears as shown in the figure below.

![image5](http://static.toastoven.net/prod_instance/putty008.png)

Once pageant is run, it continues to run in the Windows tray, so you don't need to run it again each time you access an instance. However, it must be run again when Windows is restarted.

##### 3. Access the Instance Using PuTTY

If the PuTTY-compatible private key has been registered successfully, run PuTTY.

![image6](http://static.toastoven.net/prod_instance/putty009.png)

Use the **Host Name** in the basic connection information as follows.

Ubuntu

	ubuntu@<instance IP>

Debian

	debian@<instance IP>

Rocky

	rocky@<instance IP>

Set **Port** to 22 (the default SSH port) and **Connection type** to **SSH**.

If all of the information is correct, save the session. Under **Load, save, or delete a stored session**, enter the name of the session to save in the field below **Saved Sessions** and click **Save** to save the session. If you do not save the session, your private key settings registered in 2-A are also not preserved.

Now click **Open** to access the instance.

<a id="how-to-access-windows-instances"></a>
### How to Access Windows Instances

To access a Windows server, select the Windows instance you want to access in the NHN Cloud console. On the instance details screen, click the **View Password** button in the **Connection Information** tab to check the password set on the Windows server.

The private key of the key pair entered in **View Password** is not sent to the server and is used only for decrypting the password in the browser.

Click the **Connect** button next to **View Password** to download and run the .rdp file with remote desktop connection settings to access the Windows server. The username for the Windows server is `Administrator`, and the password is the one you viewed in the NHN Cloud console.

### How to Access via Serial Console

You can access instances through the serial console when you cannot use SSH client, such as in cases of boot failures or network configuration issues. 

The serial console feature has the following limitations.

* Only one serial console connection per instance is available, and multiple connection attempts may not connect properly.
* Serial console access is not guaranteed for instances created from custom-uploaded images or private images.
* Serial console connection can be accessed for a maximum of 10 minutes.
* Windows instances do not support serial console functionality.
* Instances created before January 27, 2026 deployment require **Stop Instance** followed by **Start Instance**. **Reboot Instance** functionality does not apply.

> [Caution]
> When accessing an instance via serial console and changing boot settings, booting may fail, and you are responsible for the consequences.
> In general situations, it is recommended to use SSH client connections.

#### Modify GRUB Bootloader Configuration

To manipulate the bootloader on instances created before November 26, 2024 deployment, GRUB configuration is required.

Modify the GRUB configuration file.

```
$ sudo vi /etc/default/grub.d/50-cloudimg-settings.cfg
GRUB_TIMEOUT=3
GRUB_TERMINAL="console serial"
GRUB_SERIAL_COMMAND="serial --speed=9600 --unit=0 --word=8 --parity=no --stop=1"
```

Apply the modified settings. The command to apply GRUB settings may differ depending on the operating system.

```
$ sudo update-grub
```