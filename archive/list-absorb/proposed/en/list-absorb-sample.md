# List absorption fixture — a different kind of list past a blank line

python-markdown joins a **list item** that follows a list past a blank line to that list, even when
the kind (bullet vs. number) differs. So a `2.` the author wrote reads as a bullet, and a `- …` note reads
as `8.`. The GitHub preview (CommonMark) starts a new list when the kind changes, so source review never
shows it.

Every section is an **excerpt of a real alpha document** (source noted per section). `scripts/check_list_absorb.py`
judges it with the site's renderer — it counts items whose marker or number differs from what the author wrote.

<a id="c1-numbered-after-bullets"></a>
## C1 Numbered list after a bullet list { #c1-numbered-after-bullets }

<!-- 원본: TOAST-DOCS/Log-Crash-Search en/console-guide.md L347-L361 @ e6bc510c -->

Set information for external log storage. 

![lcs_25_202108](https://static.toastoven.net/prod_logncrash/lcs_25_202312_en.png)

- Logs can be stored at an external OBS. 

<!-- -->

1. Visit [AWS S3 API](/Storage/Object%20Storage/en/s3-api-guide/#s3-api-credential) and register/query credential to import access key and secret key. 
2. From the **External Log Storage Settings**, click **Storage Settings**.
3. Enter data, including access key and secret key.
4. All of the information about external log tampering notifications is required when adding/editing/deleting settings.
5. After all data entered for OBS, click **Save**.
    - A temporary file is created in the bucket you set up for integration verification. 

<!-- -->

- Logs are saved at OBS as configured. 
- [Guide for NHN Cloud OBS API](/Storage/Object%20Storage/en/s3-api-guide/)

<a id="c2-fence-between-steps"></a>
## C2 Unindented code block between steps + check bullets { #c2-fence-between-steps }

<!-- 원본: TOAST-DOCS/PrivateCA en/cert-manager-guide.md L656-L688 @ a658294d -->

1. **Check Issuer status**

    ```bash
    kubectl describe issuer my-acme-issuer-example-com -n default
    ```

    - Verify that the `Ready` status `is True`.
    - Verify that your ACME account registration was successful.

2. **Check Certificate Satus**

    ```bash
    kubectl describe certificate test-server-cert-example-com -n default
    ```

    - In the Events section, check for error messages.

3. **Verify ertificateRequest**

    ```bash
    kubectl get certificaterequest -n default
    kubectl describe certificaterequest <request-name> -n default
    ```

4. **Check Challenge**

```bash
kubectl get challenge -n default
kubectl describe challenge <challenge-name> -n default
```

- For HTTP-01 Challenge, make sure Ingress is configured correctly.
- Verify that the Challenge URL is accessible.

<a id="c3-note-bullets-after-steps"></a>
## C3 Note bullets after the steps { #c3-note-bullets-after-steps }

<!-- 원본: TOAST-DOCS/E-mail en/console-guide.md L14-L31 @ 4a31def4 -->

You can send an email by entering the recipient, title, content, attachment, and so on.
For general mail delivery, you must enter the receiver directly.

![email_01_20231023_en](https://static.toastoven.net/prod_email/email_01_20231023_en.png)

1. On **Deliver Mails** tab, select **Disable** under **Enable Template or Not**.
2. On **Deliver Type** tab, select **General Mails**.
3. Enter **Deliver Mails** address. You can enter the sender's name and mail address by creating it in the name format.
    - When you send it in the form of "Sender Name <Sender Mail>, it will appear to recipient in the form of sender name and email address.
4. To choose time of delivery, specify it **Scheduled Delivery**.
5. Click **Attached File** and upload attached files.
6. **Enter the title and message content**.
7. In **Recipient** and **CC**, enter the email address that you want to send to.

<!-- -->

- Up to 10 attachments can be uploaded, and only 30MB or less files can be uploaded.
- Total size of attachments cannot exceed 30MB.
- You can attach up to 30MB, but it is recommended to attach it within 10MB because it may be rejected due to `exceeding the limit` or may result in a higher
  spam rating depending on the attachment restriction policy of incoming email system (gmail.com, naver.com, etc.).

<a id="c4-image-bullets-between-steps"></a>
## C4 Image + bullets between steps { #c4-image-bullets-between-steps }

<!-- 원본: TOAST-DOCS/Deploy en/reference.md L151-L172 @ ea5b4fec -->

1. Add Individually 

    ![deploy_ref_08_202402.png](https://static.toastoven.net/prod_tcdeploy/deploy_ref_08_202402.png)

    * Enter host name (required), IP address (required), and OS (optional), and click **Add**. 
    * Find what is added on the server list below. Only the servers left in the list are registered. 
    * Click **Create**: to modify, click **Modify**. 

2. Add in Mass 

![deploy_ref_09_202402.png](https://static.toastoven.net/prod_tcdeploy/deploy_ref_09_202402.png)

* Check **Enter in Mass**. 
* Enter server information in the following format: 
    ```
   test.host.name1;1.1.1.1;CentOS7.9;
    test.host.name2;2.2.2.2;
    ```

* Click **Add**.
* Find two more servers that are added.
* Click **Create**: to modify, click **Modify**. 

<a id="c5-sub-bullets-3-spaces"></a>
## C5 Bullets indented 3 spaces under a numbered item { #c5-sub-bullets-3-spaces }

<!-- 원본: TOAST-DOCS/Private-DNS en/console-guide.md L57-L62 @ 576922ad -->

1. Select the Private DNS Zone to modify, then click **Modify Private DNS Zone** .
   
2. You can add or delete VPCs. You can add a VPC by clicking the **+** button on the right side of the screen, and remove a VPC by clicking the **-** button on the added VPC.
    - Because a Private DNS Zone must be associated with at least one VPC, the last VPC cannot be deleted.

3. Modify **Description** and click **Confirm**.

<a id="c6-bullets-under-step"></a>
## C6 Unindented bullets right under a numbered item { #c6-bullets-under-step }

<!-- 원본: TOAST-DOCS/API-Gateway en/console-guide.md L50-L64 @ 230a077f -->

1. To create a resource, click the **Create Resource** button, or click **Create Resource** from the menu that appears upon right-clicking the Resource Tree screen on the left.
2. Write the **Resource Path**. The entire path including the written resource path must not exceed 255 characters.
    - –	e.g./products/, /products/{productsId}, /{proxy+}
3. **Path Variable**: Curly brackets can be used in the Resource path to create a **Path Variable**.
    - **Path Variable** containing **{variable}** or child path can be declared as **{variable+}**.
        - **Path Variable** can be utilized in the plugin and backend endpoint settings.
        - **{variable}** declares the value of the path where the path variable is located.
            - e.g./members/{memberId} 
                - **{memberId}** path variable value of /members/id1 request becomes **id1**.
        - **{variable+}** includes the child path where the path variable is located to declare a variable. A child resource path cannot be created in the variable containing the child path.
            - e.g./{proxy+} 
                - **{proxy+}** path variable value of **/members/id1** becomes **members/id1**.

<!-- -->

- **Plugin**: Select this option if you want to add a plugin that is added to the selected path to the created method as well.
- To create a resource and register a method at the same time, select HTTP method.
- If you make a request to API Gateway with an unregistered resource path, 404 Not Found response is returned.

<a id="k1-bullets-after-bullets"></a>
## Control K1 Bullets after bullets { #k1-bullets-after-bullets }

<!-- 합성 대조군 -->

- An item of the first bullet list.
- The second item of the same list.

- A bullet after a blank line. Joining the list above keeps its marker.

<a id="k2-loose-numbered-steps"></a>
## Control K2 Numbered steps separated by blank lines { #k2-loose-numbered-steps }

<!-- 합성 대조군 -->

1. The first step.

2. The second step.

3. The third step.

<a id="k3-sub-bullets-4-spaces"></a>
## Control K3 Sub-bullets indented 4 spaces { #k3-sub-bullets-4-spaces }

<!-- 합성 대조군 -->

1. Select how to configure.
    * **All**: Use the same value for every target.
    * **Each**: Enter a value per target.
2. Click **OK**.
