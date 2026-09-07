<!-- machine_translated: true -->

<!-- pre-align:aligned sig=82f23cc3f97e -->

<a id="compute-instance-console-guide"></a>
## Compute > Instance > Console User Guide { #compute-instance-console-guide }

<a id="create-instances"></a>
## Create an Instance { #create-instances }

You can create an instance through the settings below or by using an Instance Template. To create an instance using an Instance Template, select **Use Instance Template** on the instance creation screen. For instructions on how to create an Instance Template, see [Instance Template Console User Guide](/Compute/Instance%20Template/en/console-guide/).

![Instance Creation Guide Cover](../static/images/image-1704.jpg)

<a id="os-settings"></a>
### OS Settings { #os-settings }

Determine how to create the root block storage to be used when creating an instance.

- Select either **Create and Configure** or **Use Existing Resource**.
- If you select **Create and Configure**, the root block storage is created using an image.
- If you select **Use Existing Resource**, you can use an existing block storage or snapshot.

<a id="image"></a>
### Image { #image }

Select an image with your desired operating system installed. You can choose from public images provided by NHN Cloud, user images you created, or shared images.

Since available instance flavors depend on the image you select, select an image first when creating an instance.

| Operating System                         | Block Storage | Memory   |
| ------------------------------ | ---------- | -------- |
| Linux<br>Ubuntu, Debian, Rocky | 20 GB or more  | 1 GB or more |
| Windows                         | 50 GB or more  | 2 GB or more |

<a id="root-block-storage"></a>
### Root Block Storage { #root-block-storage }

Configure the root block storage based on **OS Settings**.

- If you select **Create and Configure**, specify **Block Storage Type** and **Block Storage Size** to create the root block storage.
- If you select **Use Existing Resource**, specify **Original Resource** to use as the root block storage.

<a id="root-block-storage-original-resource"></a>
#### Original Resource

You can select either an existing **Block Storage** or **Snapshot**.

- If you select **Block Storage**, the existing block storage will be used as the root block storage.
- If you select **Snapshot**, the root block storage is created using the existing snapshot.

<a id="root-block-storage-block-storage-size"></a>
#### Block Storage Size

Determine the size of the root block storage for the instance.

- The block storage size must be equal to or larger than the minimum size required by the image.

The root block storage size for an instance varies depending on the instance flavor.

| Flavor               | Supported Block Storage Size         |
| -------------------| -------------------------- |
| u2 flavor             | 20 ~ 100 GB (fixed per flavor) |
| t2, m2, c2, r2, x1 flavor | 20 ~ 2,000 GB               |

> [Note]
> Because you are charged by block storage size, it is inefficient to make the default block storage size large without consideration. We recommend adding additional block storage as needed.
> If you select **Block Storage** for **Use Existing Resource** in the **OS Settings**, you cannot change the block storage size.
> If you select **Snapshot** for **Use Existing Resource** in the **OS Settings**, block storage size must be set equal to or larger than the original block storage size.

<a id="root-block-storage-block-storage-type"></a>
#### Block Storage Type

Determine the block storage type for the default block storage of the instance.

- Select either **HDD** or **SSD**. Pricing and performance vary depending on the type.
- The block storage type you select cannot be changed later.

> [Note]
> If you select **Use Existing Resource** in **OS Settings**, you cannot change the block storage type.

<a id="availability-zone"></a>
### Availability Zone { #availability-zone }

If you do not explicitly set an availability zone, it is set to a random zone. Available block storage for this instance is determined by the availability zone. If the block storage you want to use exists in a specific availability zone, set it to that availability zone.

> [Note]
> VPC resources can be used in all availability zones.
> If you select **Use Existing Resource** in **OS Settings**, the availability zone cannot be changed.

For more information about availability zones, see [Availability Zone in Instance Overview](./overview/#availability-zone).

<a id="flavor"></a>
### Flavor { #flavor }

You can select various flavors depending on the performance of the virtual hardware. However, the flavors you can select may be limited depending on the virtual hardware performance required by the image. For more information, see [Instance Overview](./overview).

> [Note]
> 1 vCPU consists of one socket with one thread and one core, and the number of threads and cores per socket is fixed at one each.

Instance flavors can be changed in the NHN Cloud console even after instance creation, from higher to lower specs and vice versa. However, note that some flavors cannot be changed. See [Modify flavor](./console-guide/#modify-flavor) for details.

> [Caution]
> The root block storage of an instance cannot be changed by changing the flavor.

<a id="number-of-instances"></a>
### Number of Instances { #number-of-instances }

You can specify the number of instances you want to create when creating multiple instances with the same image, availability zone, flavor, block storage size, key pair, and network settings. The instance names will be the name you specified, with numbers such as -1 and -2 appended to the end. For example, creating two instances named `my-instance` will result in `my-instance-1` and `my-instance-2`. The maximum number of instances you can create at once is 10.

When you create multiple instances without specifying an availability zone, each instance will be created in a randomly selected availability zone. For example, if two instances are created without specifying an availability zone, they may be created in the same zone or they may be created in different zones. If all instances need to be created in the same availability zone, select a particular zone.

> [Note]
> If you select **Block Storage** for **Use Existing Resource** in **OS Settings**, or if you select **Use Existing Network Interface** in **Network Settings**, the number of instances is limited to 1.

<a id="key-pair"></a>
### Key Pair { #key-pair }

You can use an existing key pair or create and use a new key pair. For information about registering an existing key pair, see [Import Key Pairs (Windows Users)](./console-guide/#import-key-pairs-windows) for Windows users or [Import Key Pairs (Mac and Linux Users)](./console-guide/#import-key-pairs-mac-and-linux) for Mac and Linux users.

> [Note]
> Key pairs are resources assigned to user accounts, so they are retained even if you delete the project.

<a id="network"></a>
### Network { #network }

Select a subnet defined in your VPC to connect to an instance. For each selected subnet, a network interface is created in the instance to connect to that subnet. You can change the order of selected subnets to change network interfaces, in which case the first network interface (`eth0`) will be set as the default gateway.

For more information about network creation and management, see [VPC Overview](/Network/VPC/en/overview/).

<a id="floating-ip"></a>
### Floating IP { #floating-ip }

Select whether you will use a floating IP after instance creation. If you enable this option, a new floating IP is created and connected to the first network interface. Note that the first network interface must be connected to a subnet where an internet gateway is configured.

You can also manage floating IP on the Instance > Management page or the Instance > Floating IP page. For more information about floating IPs, see [VPC Console User Guide](/Network/VPC/en/console-guide/).

<a id="security-group"></a>
### Security Group { #security-group }

Specify the security group that the instance will belong to. An instance can belong to multiple security groups. When an instance belongs to multiple security groups, consider the following:

- Network communication is possible with all instances in each security group. For instances with sensitive data that need to prevent unintended access from other instances, you must carefully specify the security group.
- All rules from each security group are combined and applied to the external communication of that instance.

For more information about security groups, see [VPC Console User Guide](/Network/VPC/en/console-guide/).

<a id="additional-block-storage"></a>
### Additional Block Storage { #additional-block-storage }

Specify whether to attach additional block storage after instance creation. If you select to use additional block storage, a new block storage separate from the root block storage is created and attached to the instance. As with the root block storage, you can specify the name, storage type, and size when creating additional block storage.

By using the root block storage only for the OS and storing your frequently used applications and data on the additional block storage, you can easily migrate or copy your applications and data using the block storage attach/detach and snapshot features. In addition, when an instance failure occurs, you can easily recover your services by simply detaching the additional block storage and attaching it to another instance.

You can also manage block storage on the Instance > Block Storage page. For more information about block storage, see [Block Storage Guide](/Storage/Block%20Storage/en/overview/).

<a id="placement-policy"></a>
### Placement Policy { #placement-policy }

You can use a placement policy to place instances on different hypervisors. If you set a placement policy when creating an instance, instances assigned to the same placement policy are created on different hypervisors.

> [Caution]
> Instance creation may fail if distributed placement is not possible.

<a id="user-script"></a>
### User Script { #user-script }

You can specify a script to be executed after instance creation. The user script is executed following the instance's initial boot and after the initialization process including network configuration has completed. User scripts in NHN Cloud are executed by automated tools such as cloud-init (Linux) and Cloudbase-init (Windows), which are embedded in the official images.

> [Caution]
> User scripts are executed with root (Linux) / Administrator (Windows) user privileges.

<a id="user-script-linux"></a>
#### Linux

The first line of a user script must start with `#!`.
```
#!/bin/bash
...
```

For a user script to run successfully, log files in the instance must be checked. You can check output logs printed by standard output/error from the script in `/var/log/cloud-init-output.log`.

<a id="user-script-windows"></a>
#### Windows

For Windows images, user scripts support both batch script format and PowerShell script format. Each format is distinguished by the directive specified on the first line.

* Batch script
```
rem cmd
...
```

* PowerShell script
```
#ps1_sysnative
...
```

If you want to use batch scripts and PowerShell scripts together, write them as follows:

* EC2 format
```
<script>
...
</script>
<powershell>
...
</powershell>
```

You can check the user script logs in `C:\Program Files\Cloudbase Solutions\Cloudbase-Init\log\cloudbase-init`.

For more information about user scripts, see the [cloud-init](https://cloudinit.readthedocs.io/ko/latest/topics/format.html) or [Cloudbase-init](https://cloudbase-init.readthedocs.io/ko/latest/userdata.html) guide.

<a id="additional-instance-features"></a>
## Additional Instance Features { #additional-instance-features }

![Additional Instance Features section cover](../static/images/image-1791.jpg)

<a id="change-instance-status"></a>
### Change Instance Status { #change-instance-status }

You can change the status of an instance by stopping, terminating, deleting, or starting it.

For information about hypervisor resources and billing related to stopping, terminating, and deleting instances, refer to the following table:

| Item | Stop Instance | Terminate Instance | Delete Instance |
| --- | --- | --- | --- |
| Hypervisor Resource | Resource remains allocated | Resources are released and reallocated when instance starts | Resources are removed |
| Instance Billing | Stop billing policy applied | Free | Free |
| Connected Resource Billing | Charged | Charged | Charged |

> [Note] GPU instances cannot be terminated, and normal (100%) charges apply even when stopped.

<a id="create-image"></a>
### Create an Image { #create-image }

Create an image from the root block storage of an instance. To ensure data consistency, we recommend that you create an image while the instance is stopped.

While it is possible to create an image from an instance that has no available free space in its root block storage, those images are unusable by other instances because they cannot be properly initialized. Before creating an image, ensure that your instance has at least 100KB of free space.

Created images are registered as private images in **Compute > Image**. You can use the registered image to create an instance with a block storage identical to that of the original instance.

> [Caution]
> The size of the created image may be larger than the actual usage of the root block storage.

<a id="associatedisassociate-floating-ip"></a>
### Associate and Disassociate Floating IP { #associatedisassociate-floating-ip }

Floating IP can be associated with or disassociated from an instance, regardless of the instance's status. If you have no available floating IP or if the floating IP you want is not available, you can create one by clicking **Create**. Alternatively, floating IP can also be created from **Network > VPC > Floating IP**.

For more information about floating IP, see [VPC Overview](/Network/VPC/en/overview/).

<a id="modify-security-group"></a>
### Modify Security Group { #modify-security-group }

You can modify the security group of an instance regardless of the instance's status. The modified security group is applied immediately.

For more information about security groups, see [Security Group](./console-guide/#security-group) and [VPC Overview](/Network/VPC/en/overview/).

<a id="change-network-subnet"></a>
### Change Network Subnet { #change-network-subnet }

An instance's network subnet can only be changed while the instance is stopped. When you add a subnet, a network interface that will be connected to that subnet is automatically created on your instance. If you add multiple subnets at once, the order of the newly created network interfaces on the instance is set randomly. Deleting a subnet from an instance automatically deletes the network interface that was created along with the subnet.

<a id="modify-flavor"></a>
### Change Instance Flavor { #modify-flavor }

Instance flavors can be changed once an instance has been stopped. If an instance is running, click **Stop Instance** in **Additional Features** to stop the instance.

The instance flavors you can change to vary depending on the current flavor.

* Instances of the m2, c2, r2, t2, and x1 types can be changed to m2, c2, r2, t2, or x1 flavors.
* Instances of the m2, c2, r2, t2, and x1 types cannot be changed to u2 flavor.
* Instances of the u2 type cannot be changed to a different flavor after creation, including to another u2 flavor.

When you modify flavors, instance resize and resize confirmation tasks proceed. When all tasks are completed, the VM changes its status to **Shutoff**. You can start the instance by clicking **Start Instance** in **Additional Features**.

> [Note] The instance's root block storage size cannot be modified. If an instance requires additional block storage space, attach a block storage. For details on how to attach block storage, see [Block Storage Overview](/Storage/Block%20Storage/en/overview/).

Billing for the instance is based on the changed flavor from the time of change.

<a id="change-instance-os-details"></a>
### Change Instance OS Information { #change-instance-os-details }

You can change instance OS information regardless of the instance's status.

On the **Compute > Instance** service page, click the instance for which you want to change OS information. On the **Basic Information** tab of the instance details screen, click **OS > Change**.

> [Note] The OS category cannot be changed.

<a id="change-instance-description"></a>
### Change Instance Description { #change-instance-description }

You can change the instance description regardless of the instance's status.

On the **Compute > Instance** service page, click the instance for which you want to change the description. On the **Basic Information** tab of the instance details screen, click **Description > Change**.

<a id="change-instance-key-pair"></a>
### Change Instance Key Pair { #change-instance-key-pair }

Instance key pairs can only be changed when the instance is in an active state.

On the **Compute > Instance** service page, click the instance for which you want to change key pair information. On the **Basic Information** tab of the instance details screen, click **Key Pair > Change**.

Change the key pair of the instance default account to the selected key pair. The instance default account can be found on the **Connection Information** tab of the instance's bottom details screen.

> [Caution] When you change the instance key pair, all public keys within the instance except the selected key pair are deleted.

> [Note] Only project members with ADMIN permission for the basic infrastructure service can change instance key pairs, and key pairs cannot be changed for Windows OS instances.

> [Note] The key pair change feature may not be supported if the image version used to create the instance is low.

<a id="manage-placement-policies"></a>
### Manage Placement Policies { #manage-placement-policies }

You can create and delete placement policies and view a list of instances assigned to the placement policy.

Only the `anti-affinity` placement policy type is provided for distributed placement.

Placement policies can be deleted even if instances are assigned to them, and in such cases, the instances are not deleted.

<a id="key-pairs"></a>
## Key Pair { #key-pairs }

![Key Pair Section Cover](../static/images/en/image-1461.jpg)

<a id="import-key-pairs-windows"></a>
### Import Key Pair (Windows Users) { #import-key-pairs-windows }

You can generate a key pair using the puttygen program that is installed with the PuTTY SSH client and register it with NHN Cloud to use it.

Install [PuTTY](https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html) or [iPuTTY](https://github.com/iPuTTY/iPuTTY/releases/tag/l0.70i) with Korean language support.

Run puttygen.

![Image 1](http://static.toastoven.net/prod_instance/putty-ssh-001.png)

Select **RSA** in **Parameters** (or SSH-2 RSA in older versions of puttygen). Click the **Generate** button in **Actions**. Move the mouse continuously in the blank space to generate the key.

After the key is generated, the public key file contents will be visible as shown below. Paste the contents of the public key into the **Public Key:** field in **Get Key Pair** in order to register the key pair.

![Image 1](http://static.toastoven.net/prod_instance/putty-ssh-002.png)

Click the **Save private key** button in **Actions** to save the private key. If you save the private key with an empty key passphrase, the message **Do you want to save this key without a passphrase to protect it?** will appear. To use the converted private key more securely, set a passphrase and save it.

> [Caution]
To automatically log in to instances, you must not use a passphrase. If you use a passphrase, you must enter a password for the private key when logging in.

The registered key pair can be used to create instances, and the key pair's private key must be used when accessing instances. For more details on how to access instances, see [How to Access Instances](./overview/#how-to-access-instances).

Just as with key pairs created from NHN Cloud, imported key pairs also need to be managed cautiously since exposed private keys can be abused by anyone to access instances.

<a id="import-key-pairs-mac-and-linux"></a>
### Import Key Pair (Mac and Linux Users) { #import-key-pairs-mac-and-linux }

You can generate a key pair using `ssh-keygen` on Mac or Linux, register it with NHN Cloud, and use it. Generate a key pair using the following command.

	$ ssh-keygen -t rsa -f my_key.key

You can choose to set a passphrase for the key pair, although it is not required. If you wish to use your key pair more securely, we recommend setting a passphrase. The file with `.pub` appended to the specified key pair name contains the public key.

	$ cat my_key.key.pub
	ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCnnUAe36txQqk8J7VzbNuYKVQQ3gbNoClndHMX49OD+1Rw5xrDFLUKQqxbBDtlNMoA9tKBZNrQBpKr1kFEtvMIj1HPkH9ocb4MbuoVVjpkIhixbKMMJPDQ4JQJxaifsjR59YsZyDAp0aXZp+o+OB97P3S4AKPY2kQR0JdSr30+6Av6smf+3mZceAE4abzklfbyWT5slP1im/wfYEPO3QBEDl/0JbmTjKWPYI6QnbwnPRHS63SJ+Kd2QeYQYJCadv7X4mXnw81qEIWq/dx1SQkGDTNgR7lnN2ApFlU5EZcow69z6tiCr0hlyigwjGooMg3wTZvcSlYcVeTzZ755RArd ...

Paste all of this content into the **Public Key:** field in **Get Key Pair** in order to register the key pair.

The registered key pair can be used to create instances, and the key pair's private key must be used when accessing instances. For more details on how to access instances, see [How to Access Instances](./overview/#how-to-access-instances).

Just as with key pairs created from NHN Cloud, imported key pairs also need to be managed cautiously since exposed private keys can be abused by anyone to access instances.

<a id="appendix-1-change-language-packs-in-windows"></a>
## Appendix 1. Change Language Packs in Windows { #appendix-1-change-language-packs-in-windows }

NHN Cloud Windows images are provided with English as the default language. Users who want to use a different language by default can do so by following the method below.

1. START > Control Panel > Clock, Language, and Region > Add a language
![Image 1](http://static.toastoven.net/prod_instance/windows1.png)

2. Change language preferences > Add a language
![Image 1](http://static.toastoven.net/prod_instance/windows2.png)

3. Add a language > Select the language you want to use > Add
![Image 1](http://static.toastoven.net/prod_instance/windows3.png)

4. Check the added language pack
![Image 1](http://static.toastoven.net/prod_instance/windows4.png)

5. Download and install the added language pack
![Image 1](http://static.toastoven.net/prod_instance/windows5.png)

6. Download and install updates
![Image 1](http://static.toastoven.net/prod_instance/windows6.png)

7. Double-click the selected language or choose options to change the installed language pack
![Image 1](http://static.toastoven.net/prod_instance/windows7.png)

8. Choose to set the language as the default language in the language options
![Image 1](http://static.toastoven.net/prod_instance/windows8.png)

9. Log off to apply the default language setting
![Image 1](http://static.toastoven.net/prod_instance/windows9.png)

10. When you log in again, you can see that the language pack you selected has been applied.
![Image 1](http://static.toastoven.net/prod_instance/windows10.png)

<a id="appendix-2-change-routing-in-windows"></a>
## Appendix 2. Change Routing in Windows { #appendix-2-change-routing-in-windows }

The following are methods to change routing in NHN Cloud Windows.

* START > Run > cmd

Route command

* Print current settings: route print
* Add: route add "destination" mask "subnet" "gateway" metric "Metric value" if "Interface number"
* Change: route change "destination" mask "subnet" "gateway" metric "Metric value" if "Interface number"
* Delete: route delete "destination" mask "destination subnet" "gateway" metric "Metric value" if "Interface number"
* Option: -p (specify permanent route)

Description

![Image 1](http://static.toastoven.net/prod_instance/windows_route1.png)

* Metric value: Lower values have higher priority
* Interface number: Can be checked in route print (red border)
* Permanent route: Use this option since the configured route will be initialized when the system reboots if you do not use the -p option (blue border)

Case 1 - Configure external communication for a specific interface only

* You can restrict an interface from communicating externally by using the route change command to change its route metric or by leaving the default gateway field blank when configuring fixed IP settings.
* Method to modify metric
    * Increase the interface's metric

            $ route change 0.0.0.0 mask 0.0.0.0 172.16.5.1 metric 10 if 14 -p

![Image 1](http://static.toastoven.net/prod_instance/windows_route2.png)

* Method to configure static IP
    1. Check IP information using ipconfig /all
![Image 1](http://static.toastoven.net/prod_instance/windows_route3.png)
    2. Use the checked IP information to enter the IP settings window excluding the default gateway
![Image 1](http://static.toastoven.net/prod_instance/windows_route4.png)
    3. Check using route print
![Image 1](http://static.toastoven.net/prod_instance/windows_route5.png)

Case 2 - Configure routing for a specific range

* Configure routing for a specific range by using the route add command.

        $ route add 172.16.0.0 mask 255.255.0.0 172.16.5.1 metric 1 if 14 -p

![Image 1](http://static.toastoven.net/prod_instance/windows_route6.png)

Case 3 - Remove a specific route

* Remove the specified route using route delete.

        $ route delete 172.16.0.0 mask 255.255.0.0 172.16.5.1

![Image 1](http://static.toastoven.net/prod_instance/windows_route7.png)

<a id="appendix-3-change-system-locale"></a>
## Appendix 3. Change System Locale { #appendix-3-change-system-locale }

The following is how to change the system locale in NHN Cloud Windows.

1. Choose **Windows key > Control Panel > Clock and Region**.
![Image 1](http://static.toastoven.net/prod_instance/win_locale1.png)

2. Choose **Country or Region**.
![Image 1](http://static.toastoven.net/prod_instance/win_locale2.png)

3. On the **Administration** tab, click **Change system locale**.
![Image 1](http://static.toastoven.net/prod_instance/win_locale3.png)

4. Select the system locale to change.
![Image 1](http://static.toastoven.net/prod_instance/win_locale4.png)

5. Restart the system for the changes to take effect.
![Image 1](http://static.toastoven.net/prod_instance/win_locale5.png)

<a id="appendix-4-restarting-instances-for-hypervisor-maintenance"></a>
## Appendix 4. Guide to Restarting Instances for Hypervisor Maintenance { #appendix-4-restarting-instances-for-hypervisor-maintenance }

NHN Cloud updates hypervisor software on a regular basis to enhance the security and stability of infrastructure services that we provide.
Instances running on a hypervisor that requires maintenance must be restarted and migrated to a hypervisor that has completed maintenance.

To restart an instance, use the **! Restart** button that has been created next to the instance name in the console.
`Using the "Restart Instances" button in the console or rebooting the operating system will not migrate an instance to another hypervisor.`
Follow the guide below to use the restart feature in the console.

Go to the project that contains the instance designated for maintenance.

**1. Identify the instance requiring maintenance.**

Any instance that has the **! Restart** button before its name requires maintenance.
Put the mouse cursor over the **! Restart** button to find maintenance schedule details.
![Instance Maintenance Image 1](http://static.toastoven.net/prod_instance/instance_p_migration_ko_1.png)    

**2. Deactivate or stop any application programs running on the instance requiring maintenance.**

Any application programs running on an instance which requires maintenance must be deactivated or stopped in order not to impact your service. 
If there is no way to do so without impacting your service, please contact NHN Cloud Customer Center, and we will provide you with guidance on appropriate measures to take.

**3. Click the [! Restart] button that has been created next to the instance name requiring maintenance.**

![Instance Maintenance Image 2](http://static.toastoven.net/prod_instance/instance_p_migration_ko_2.png)

**4. When a dialog asking whether to restart the instance appears, click the [OK] button.**

![Instance Maintenance Image 3](http://static.toastoven.net/prod_instance/instance_p_migration_ko_3.png)

**5. Wait until the instance status indicator turns green and the [! Restart] button disappears.**

If the instance status indicator does not change or the **! Restart** button does not become inactive, try refreshing.

You cannot operate or modify the instance while a restart is underway.
If an instance restart does not complete successfully, the administrator will automatically be notified, and you'll also be contacted by NHN Cloud.