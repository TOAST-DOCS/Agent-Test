<!-- machine_translated: true -->

# Console Glossary Sample

This document is a console glossary e2e fixture.

<a id="cg-notify"></a>
## Notification Settings

1. Enable **Notification sent**.
2. Select **On failure** in **Send Criteria**.
3. To receive failure reasons by email, select **Reason for failure included**.

<a id="cg-window"></a>
## Window Settings

When you set **Allowed lateness**, messages that arrive after the window closes are also reflected in the results.

<a id="cg-window-fields"></a>
## Window Fields

| Field | Default | Description |
| --- | --- | --- |
| Allowed lateness | 0 | Time (in seconds) to maintain the aggregation status after the window closes |

If you set Allowed lateness to 0, messages that arrive late are discarded.

<a id="cg-detail"></a>
## View Detailed Info

In the **Detailed Info** tab, you can view the execution results.

<a id="cg-prose"></a>
## Next Steps

After you finish the configuration, click **Next**.

Select one of the following:

* Run the schedule immediately.
* Only save the schedule.