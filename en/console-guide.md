<!-- machine_translated: true -->

<!-- pre-align:aligned sig=82f23cc3f97e -->

<a id="compute-instance-console-guide"></a>

## Compute > Instance > Console User Guide { #compute-instance-console-guide }

<a id="create-instances"></a>

## Create Instances { #create-instances }

You can create instances through the following settings or by using an Instance Template. To create an instance using an Instance Template, choose **Use Instance Template** on the instance creation screen. For instructions on creating an Instance Template, see [Instance Template Console User Guide](/Compute/Instance%20Template/en/console-guide/).

![Instance creation guide cover](../static/images/image-1704.jpg)

<a id="os-settings"></a>
### OS Settings { #os-settings }

Determine how the root block storage to be used when creating an instance will be created.

- Choose either **Create and Configure** or **Use Existing Resource**.
- If you choose **Create and Configure**, root block storage is created using the image.
- If you choose **Use Existing Resource**, you use previously created block storage or a snapshot.

<a id="image"></a>
### Image { #image }

Select an image with the desired operating system installed. You can select from public images provided by NHN Cloud, user-created images, or shared images.

The instance flavor varies depending on the image you use, so select an image first when creating an instance.

| Operating System | Block Storage | Memory |
| --- | --- | --- |
| Linux<br>Ubuntu, Debian, Rocky | At least 20GB | At least 1GB |
| Windows | At least 50GB | At least 2GB |

<a id="root-block-storage"></a>
### Root Block Storage { #root-block-storage }

Configure root block storage according to the **OS Settings**.

- If you choose **Create and Configure**, specify the **Block Storage Type** and **Block Storage Size** to create root block storage.
- If you choose **Use Existing Resource**, specify the **Original Resource** to use as root block storage.

<a id="root-block-storage-original-resource"></a>
#### Original Resource

You can select either a previously created **block storage** or **snapshot**.

- If you select **block storage**, previously created block storage is used as root block storage.
- If you select **snapshot**, root block storage is created using a previously created snapshot.

<a id="root-block-storage-block-storage-size"></a>
#### Block Storage Size

Determine the size of the root block storage for the instance.

- Block storage size must be at least the minimum size required by the image.

Root block storage size for an instance varies depending on the instance flavor.

| Flavor | Supported Block Storage Size |
| --- | --- |
| u2 | 20 ~ 100 GB (fixed per flavor) |
| t2, m2, c2, r2, x1 | 20 ~ 2000GB |

> [Note]
> Because you are charged by block storage size, it is inefficient to make the default block storage size large without consideration. We recommend adding additional block storage as needed.
> If you select **block storage** for **Use Existing Resource** in the **OS Settings**, you can't change the block storage size.
> If you select **snapshot** for **Use Existing Resource** in the **OS Settings**, block storage size must be set equal to or larger than the original block storage size.

<a id="root-block-storage-block-storage-type"></a>
#### Block Storage Type

Determine the default block storage type for the instance.

- Choose either **HDD** or **SSD**. Pricing and performance vary by type.
- Once selected, the block storage type cannot be changed.

> [Note]
> If you select **Use Existing Resource** in **OS Settings**, the block storage type cannot be changed.

<a id="availability-zone"></a>
### Availability Zone { #availability-zone }

If you do not explicitly set an availability zone, it is set to an arbitrary zone. The block storage available for this instance is determined by the availability zone. If the block storage you want to use exists in a specific availability zone, set and use that availability zone.

> [Note]
> VPC resources can be used in all availability zones.
> If you select **Use Existing Resource** in **OS Settings**, the availability zone cannot be changed.

For a detailed description of availability zones, see [Availability Zone in the Instance overview](./overview/#availability-zone).

<a id="flavor"></a>
### Flavor { #flavor }

You can select from various flavors based on virtual hardware performance. However, the flavors you can select may be limited based on the virtual hardware performance required by the image. For a detailed description, see [Instance overview](./overview).

> [Note]
> 1 vCPU refers to one socket composed of one thread and one core, and the number of threads and cores per socket is always one each.

Instance flavors can be changed in the NHN Cloud console even after instance creation, from higher to lower specs and vice versa. However, note that some flavors cannot be changed. See [Modify flavor](./console-guide/#modify-flavor) for details.

> [Caution]
> The root block storage of an instance cannot be changed by modifying the flavor.

<a id="number-of-instances"></a>
### Number of Instances { #number-of-instances }

Use this setting when creating multiple instances with the same image, availability zone, flavor, block storage size, key pair, and network settings. Instance names will be created with numbers such as `-1` and `-2` appended to the end of the specified name. For example, creating two instances named `my-instance` will result in `my-instance-1` and `my-instance-2`. The maximum number of instances you can create at once is 10.

When you create multiple instances without specifying an availability zone, each instance will be created in a randomly selected availability zone. For example, if two instances are created without specifying an availability zone, they may be created in the same zone or they may be created in different zones. If all instances need to be created in the same availability zone, select a particular zone.

> [Note]
> If you select **block storage** for **Use Existing Resource** in **OS Settings** or select **Use Existing Network Interface** in **Network Settings**, the number of instances is limited to `1`.

<a id="key-pair"></a>
### Key Pair { #key-pair }

You can use an existing key pair or create a new key pair. To register an existing key pair, Windows users can see [Import Key Pairs (Windows Users)](./console-guide/#import-key-pairs-windows), and Mac and Linux users can see [Import Key Pairs (Mac and Linux Users)](./console-guide/#import-key-pairs-mac-and-linux).

> [Note]
> A key pair is a resource assigned to a user account, so it is not deleted even if you delete a project.

<a id="network"></a>
### Network { #network }

Select a subnet defined in your VPC to connect to an instance. For each subnet you select, a network interface is created in the instance to connect to that subnet. You can change the order of selected subnets to change network interfaces, in which case the first network interface (`eth0`) will be set as the default gateway.

For detailed information on network creation and management, see [VPC overview](/Network/VPC/en/overview/).

<a id="floating-ip"></a>
### Floating IP { #floating-ip }

Select whether you will use a floating IP after instance creation. If you select this option, a new floating IP is created and connected to the first network interface. Note that the first network interface must be connected to a subnet where an internet gateway is configured.

You can also manage floating IPs on the Instance > Manage page or the Instance > Floating IP page. For detailed information about floating IPs, see [VPC Console User Guide](/Network/VPC/en/console-guide/).

<a id="security-group"></a>
### Security Group { #security-group }

Specify the security groups to which the instance will belong. An instance can belong to multiple security groups. When an instance belongs to multiple security groups, note the following:

- Network communication is possible with all instances in each security group. For instances with sensitive data that must prevent unintended access from other instances, specify security groups carefully.
- All rules from each security group are combined and applied to the instance's external communications.

For detailed information about security groups, see [VPC Console User Guide](/Network/VPC/en/console-guide/).

<a id="additional-block-storage"></a>
### Additional Block Storage { #additional-block-storage }

Specify whether to attach additional block storage after instance creation. If you select to use additional block storage, a new block storage separate from the root block storage is created and attached to the instance. Like the root block storage, you can specify the name, storage type, and size when creating additional block storage.

By using the root block storage only for the OS and storing your frequently used applications and data on the additional block storage, you can easily migrate or copy your applications and data using the block storage attach/detach and snapshot features. In addition, when an instance failure occurs, you can easily recover your services by simply detaching the additional block storage and attaching it to another instance.

You can also manage block storage on the Instance > Block Storage page. For detailed information about block storage, see [Block Storage guide](/Storage/Block%20Storage/en/overview/).

<a id="placement-policy"></a>
### Placement Policy { #placement-policy }

You can use a placement policy to place instances on different hypervisors. If you set a placement policy when creating an instance, instances assigned to the same placement policy will be created on different hypervisors.

> [Caution]
> Instance creation may fail if distributed placement is not possible.

<a id="user-script"></a>
### User Script { #user-script }

Specify a script to be executed after instance creation. The user script is executed after the instance's initial boot has completed and the initialization process, including network configuration, has finished. User scripts in NHN Cloud are executed by automated tools such as cloud-init (Linux) and Cloudbase-init (Windows), which are embedded in the official images.

> [Caution]
> User scripts are executed with root (Linux) or Administrator (Windows) user privileges.

<a id="user-script-linux"></a>
#### Linux

The first line of the user script must start with `#!`.
```
#!/bin/bash
...
```

For a user script to run successfully, log files in the instance must be checked. You can check output logs printed by standard output/error from the script in `/var/log/cloud-init-output.log`.

<a id="user-script-windows"></a>
#### Windows

Windows images support both Batch script and PowerShell script formats for user scripts. Each format is distinguished by a directive specified in the first line.

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

If you want to use both Batch and PowerShell scripts, enter them as follows:

* EC2 format
```
<script>
...
</script>
<powershell>
...
</powershell>
```

You can check user script logs in `C:\Program Files\Cloudbase Solutions\Cloudbase-Init\log\cloudbase-init`.

For detailed information about user scripts, see the [cloud-init](https://cloudinit.readthedocs.io/ko/latest/topics/format.html) or [Cloudbase-init](https://cloudbase-init.readthedocs.io/ko/latest/userdata.html) guides.

<a id="additional-instance-features"></a>

## Additional Instance Features { #additional-instance-features }

![Additional Instance Features Section Cover](../static/images/image-1791.jpg)

<a id="change-instance-status"></a>

### Change Instance Status { #change-instance-status }

You can change the status of an instance by stopping, terminating, deleting, or starting it.

For information about hypervisor resources and billing related to stopping, terminating, and deleting instances, refer to the table below.

| Item | Stop Instance | Terminate Instance | Delete Instance |
| --- | -- | --- | --- |
| Hypervisor Resources | Resource allocation maintained | Resources released and reallocated when instance starts | Resources removed |
| Instance Billing | Stop billing policy applied | Free | Free |
| Connected Resource Billing | Charged | Charged | Charged |

> [Note] GPU Instance cannot be terminated and normal (100%) billing applies even when stopped.

<a id="create-image"></a>

### Create an Image { #create-image }

Create an image from the instance's root block storage. It is recommended that you create images while the instance is stopped to ensure data consistency.

While it is possible to create an image from an instance that has no available free space in its root block storage, those images are unusable by other instances because they cannot be properly initialized. Before creating an image, ensure that your instance has at least 100KB of free space.

Created images are registered as private images in **Compute > Image**. You can use the registered image to create an instance with a block storage identical to that of the original instance.

> [Caution]
> The size of the created image may be larger than the actual usage of the root block storage.

<a id="associatedisassociate-floating-ip"></a>

### Associate and Disassociate Floating IP { #associatedisassociate-floating-ip }

Floating IP can be associated with or disassociated from an instance, regardless of the instance's status. If you have no available floating IP or if the floating IP you want is not available, you can create one by clicking **Create**. Alternatively, floating IP can also be created from **Network > VPC > Floating IP**.

For more information about Floating IP, see [VPC Overview](/Network/VPC/en/overview/).

<a id="modify-security-group"></a>

### Modify Security Group { #modify-security-group }

You can modify the security group of an instance regardless of the instance's status. Modified security groups are applied immediately.

For more information about security groups, see [Security Group](./console-guide/#security-group) and [VPC Overview](/Network/VPC/en/overview/).

<a id="change-network-subnet"></a>

### Change Network Subnet { #change-network-subnet }

An instance's network subnet can only be changed while the instance is stopped. When you add a subnet, a network interface that will be connected to that subnet is automatically created on your instance. If you add multiple subnets at once, the order of the newly created network interfaces on the instance is set randomly. Deleting a subnet from an instance automatically deletes the network interface that was created along with the subnet.

<a id="modify-flavor"></a>

### Change Instance Flavor { #modify-flavor }

Instance flavors can be changed once an instance has been stopped. If an instance is running, click **Stop Instance** in **Additional Features** to stop the instance.

The instance flavors you can change to depend on the current flavor.

* Instances of types m2, c2, r2, t2, and x1 can be changed to instance flavors of types m2, c2, r2, t2, and x1.
* Instances of types m2, c2, r2, t2, and x1 cannot be changed to instance flavors of type u2.
* Type u2 cannot be changed after creation. It cannot be changed to any other u2 instance flavor either.

When you modify flavors, instance resize and resize confirmation tasks proceed. When all tasks are completed, the VM changes its status to **Shutoff**. You can start the instance by clicking **Start Instance** in **Additional Features**.

> [Note] The instance's root block storage size cannot be modified. If an instance requires additional block storage space, attach a block storage. For details on how to attach block storage, see [Block Storage Overview](/Storage/Block%20Storage/en/overview/).

Instances are billed according to the changed flavor from the time of change.

<a id="change-instance-os-details"></a>

### Change Instance OS Information { #change-instance-os-details }

You can change the instance OS information regardless of the instance's status.

On the **Compute > Instance** service page, click the instance for which you want to change OS information. On the **Basic Information** tab of that instance's details screen, click **OS > Change**.

> [Note] The OS type cannot be changed.

<a id="change-instance-description"></a>

### Change Instance Description { #change-instance-description }

You can change the instance description regardless of the instance's status.

On the **Compute > Instance** service page, click the instance for which you want to change the description. On the **Basic Information** tab of that instance's details screen, click **Description > Change**.

<a id="change-instance-key-pair"></a>

### Change Instance Key Pair { #change-instance-key-pair }

The instance key pair can only be changed when the instance is active.

On the **Compute > Instance** service page, click the instance for which you want to change the key pair information. On the **Basic Information** tab of that instance's details screen, click **Key Pair > Change**.

Change the key pair of the instance default account to the selected key pair. The instance default account can be found on the **Connection Information** tab of the instance's bottom details screen.

> [Caution] When you change the instance key pair, all public key contents inside the instance except for the selected key pair are deleted.

> [Note] Only project members with basic infrastructure service ADMIN permission can change the instance key pair, and it cannot be changed if the instance is a Windows OS instance.

> [Note] If the image version used to create the instance is outdated, the key pair change feature may not be supported.

<a id="manage-placement-policies"></a>

### Manage Placement Policies { #manage-placement-policies }

You can create and delete placement policies and view a list of instances assigned to placement policies.

Only the `anti-affinity` placement policy type for distributed placement is provided.

Placement policies can be deleted even if instances are assigned to them, and in this case the instances are not deleted.

<a id="key-pairs"></a>

## Key Pairs { #key-pairs }

![Key Pairs section cover](../static/images/en/image-1461.jpg)

<a id="import-key-pairs-windows"></a>
### Import key pairs (Windows users) { #import-key-pairs-windows }

You can generate key pairs using the puttygen program that comes with the PuTTY SSH client and register them with NHN Cloud.

Install [PuTTY](https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html) or [iPuTTY](https://github.com/iPuTTY/iPuTTY/releases/tag/l0.70i) with Korean language support.

Run puttygen.

![Image 1](http://static.toastoven.net/prod_instance/putty-ssh-001.png)

In **Parameters**, select **RSA** (or SSH-2 RSA in older versions of puttygen). Click the **Generate** button in **Actions**. To generate the key, move your mouse around in the empty space.

After the key is generated, the public key file contents will be visible as shown below. Paste the contents of the public key into the **Public Key:** field in **Import Key Pair** in order to register the key pair.

![Image 1](http://static.toastoven.net/prod_instance/putty-ssh-002.png)

Click the **Save private key** button in **Actions** to save the private key. If you save the private key with an empty passphrase field, a message will appear asking **Save private key without a passphrase?**. To use the converted private key more securely, set a passphrase and save it.

> [Caution]
To automatically log in to an instance, you must not use a passphrase. If you use a passphrase, you must enter a password for the private key when you log in.

The registered key pair can be used to create instances, and the key pair's private key must be used when accessing instances. For more details on how to access instances, see [How to Access Instances](./overview/#how-to-access-instances).

Just as with key pairs created from NHN Cloud, imported key pairs also need to be managed cautiously since exposed private keys can be abused by anyone to access instances.

<a id="import-key-pairs-mac-and-linux"></a>
### Import key pairs (Mac and Linux users) { #import-key-pairs-mac-and-linux }

You can generate key pairs using `ssh-keygen` on Mac or Linux and register them with NHN Cloud. Generate key pairs with the following command:

	$ ssh-keygen -t rsa -f my_key.key

You can choose to set a passphrase for the key pair, although it is not required. If you wish to use your key pair more securely, we recommend setting a passphrase. The file with `.pub` appended to the specified key pair name contains the public key.

	$ cat my_key.key.pub
	ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCnnUAe36txQqk8J7VzbNuYKVQQ3gbNoClndHMX49OD+1Rw5xrDFLUKQqxbBDtlNMoA9tKBZNrQBpKr1kFEtvMIj1HPkH9ocb4MbuoVVjpkIhixbKMMJPDQ4JQJxaifsjR59YsZyDAp0aXZp+o+OB97P3S4AKPY2kQR0JdSr30+6Av6smf+3mZceAE4abzklfbyWT5slP1im/wfYEPO3QBEDl/0JbmTjKWPYI6QnbwnPRHS63SJ+Kd2QeYQYJCadv7X4mXnw81qEIWq/dx1SQkGDTNgR7lnN2ApFlU5EZcow69z6tiCr0hlyigwjGooMg3wTZvcSlYcVeTzZ755RArd ...

Paste the contents of the public key into the **Public Key:** field in **Import Key Pair** in order to register the key pair.

The registered key pair can be used to create instances, and the key pair's private key must be used when accessing instances. For more details on how to access instances, see [How to Access Instances](./overview/#how-to-access-instances).

Just as with key pairs created from NHN Cloud, imported key pairs also need to be managed cautiously since exposed private keys can be abused by anyone to access instances.

<a id="appendix-1-change-language-packs-in-windows"></a>

## Appendix 1. Change language packs in Windows { #appendix-1-change-language-packs-in-windows }

NHN Cloud provides English as the default Windows image. Users who want to use a different language as the default can do so by following the steps below.

1. Windows Key > Control Panel > Clock, Language, and Region > Add a language
![Image 1](http://static.toastoven.net/prod_instance/windows1.png)

2. Change language preferences > Add a language
![Image 1](http://static.toastoven.net/prod_instance/windows2.png)

3. Add a language > Select the language you want to use > Add
![Image 1](http://static.toastoven.net/prod_instance/windows3.png)

4. Verify the added language pack
![Image 1](http://static.toastoven.net/prod_instance/windows4.png)

5. Download and install the added language pack
![Image 1](http://static.toastoven.net/prod_instance/windows5.png)

6. Download and install updates
![Image 1](http://static.toastoven.net/prod_instance/windows6.png)

7. Double-click the selected language or choose options to change the installed language pack
![Image 1](http://static.toastoven.net/prod_instance/windows7.png)

8. In language options, select to set as the default language
![Image 1](http://static.toastoven.net/prod_instance/windows8.png)

9. Log off for the change to take effect
![Image 1](http://static.toastoven.net/prod_instance/windows9.png)

10. When you log back in, you will see that the system has been changed to the language pack you selected.
![Image 1](http://static.toastoven.net/prod_instance/windows10.png)

<a id="appendix-2-change-routing-in-windows"></a>

## Appendix 2. Change routing in Windows { #appendix-2-change-routing-in-windows }

The following are methods for changing routing in NHN Cloud Windows:

* Windows Key > Run > cmd

Route command

* Print current settings: route print
* Add: route add "destination" mask "subnet" "gateway" metric "Metric value" if "Interface number"
* Change: route change "destination" mask "subnet" "gateway" metric "Metric value" if "Interface number"
* Delete: route delete "destination" mask "destination subnet" "gateway" metric "Metric value" if "Interface number"
* Option: -p (specify permanent route)

Description

![Image 1](http://static.toastoven.net/prod_instance/windows_route1.png)

* Metric value: Lower values have higher priority
* Interface number: Can be found in route print (red border)
* Permanent route: Use when not using the -p option because the configured route is reset when the system reboots (blue border)

Case 1 - Configure external communication for a specific interface only

* You can restrict an interface from communicating externally by using the route change command to change its route metric or by leaving the default gateway field blank when configuring fixed IP settings.
* Method to modify metric
    * Increase the interface metric

            $ route change 0.0.0.0 mask 0.0.0.0 172.16.5.1 metric 10 if 14 -p

![Image 1](http://static.toastoven.net/prod_instance/windows_route2.png)

* How to set fixed IP
    1. Check IP information using ipconfig /all
![Image 1](http://static.toastoven.net/prod_instance/windows_route3.png)
    2. Using the checked IP information, enter in the IP settings window except for the default gateway
![Image 1](http://static.toastoven.net/prod_instance/windows_route4.png)
    3. Verify using route print
![Image 1](http://static.toastoven.net/prod_instance/windows_route5.png)

Case 2 - Configure routing for a specific CIDR range

* Configure routing for a specific range using the route add command.

        $ route add 172.16.0.0 mask 255.255.0.0 172.16.5.1 metric 1 if 14 -p

![Image 1](http://static.toastoven.net/prod_instance/windows_route6.png)

Case 3 - Remove a specific route

* Remove the specified route using route delete.

        $ route delete 172.16.0.0 mask 255.255.0.0 172.16.5.1

![Image 1](http://static.toastoven.net/prod_instance/windows_route7.png)

<a id="appendix-3-change-system-locale"></a>

## Appendix 3. Change system locale { #appendix-3-change-system-locale }

The following is how to change the system locale in NHN Cloud Windows.

1. Select **Windows Key > Control Panel > Clock and Region**.
![Image 1](http://static.toastoven.net/prod_instance/win_locale1.png)

2. Select **Country or Region**.
![Image 1](http://static.toastoven.net/prod_instance/win_locale2.png)

3. On the **Administrator** tab, click **Change system locale**.
![Image 1](http://static.toastoven.net/prod_instance/win_locale3.png)

4. Select the system locale you want to change.
![Image 1](http://static.toastoven.net/prod_instance/win_locale4.png)

5. Restart the system for the changes to take effect.
![Image 1](http://static.toastoven.net/prod_instance/win_locale5.png)

<a id="appendix-4-restarting-instances-for-hypervisor-maintenance"></a>

## Appendix 4. Restart instances for hypervisor maintenance { #appendix-4-restarting-instances-for-hypervisor-maintenance }

NHN Cloud updates hypervisor software on a regular basis to enhance the security and stability of infrastructure services that we provide.
Instances running on a hypervisor that requires maintenance must be restarted and migrated to a hypervisor that has completed maintenance.

To restart an instance, use the **! Restart** button that has been created next to the instance name in the console.
`Using the "Restart Instances" button in the console or rebooting the operating system will not migrate an instance to another hypervisor.`
Follow the guide below to use the restart feature in the console.

Go to the project that contains the instance designated for maintenance.

**1. Verify the instance that requires maintenance.**

Any instance that has the **! Restart** button before its name requires maintenance.
Put the mouse cursor over the **! Restart** button to find maintenance schedule details.
![Instance Maintenance Image 1](http://static.toastoven.net/prod_instance/instance_p_migration_ko_1.png)    

**2. Deactivate or stop application programs running on the instance that requires maintenance.**

Any application programs running on an instance which requires maintenance must be deactivated or stopped in order not to impact your service. 
If there is no way to do so without impacting your service, please contact NHN Cloud Customer Center, and we will provide you with guidance on appropriate measures to take.

**3. Click the [! Restart] button created next to the instance name that requires maintenance.**

![Instance Maintenance Image 2](http://static.toastoven.net/prod_instance/instance_p_migration_ko_2.png)

**4. When a window asking whether to restart the instance appears, click the [Confirm] button.**

![Instance Maintenance Image 3](http://static.toastoven.net/prod_instance/instance_p_migration_ko_3.png)

**5. Wait until the instance status indicator turns green and the [! Restart] button disappears.**

If the instance status indicator does not change or the **! Restart** button does not become disabled, try refreshing.

You cannot operate or modify the instance while a restart is underway.
If an instance restart does not complete successfully, the administrator will automatically be notified, and you'll also be contacted by NHN Cloud.