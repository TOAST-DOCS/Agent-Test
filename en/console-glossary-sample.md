<!-- machine_translated: true -->

# Console Glossary Sample

This document is a Console Glossary e2e fixture.

<a id="cg-notify"></a>
## Notification Settings

1. Enable **Notification Delivery**.
2. In **Delivery Condition**, select **On Failure**.
3. To receive failure reasons by email, select **Include Failure Reason**.

<a id="cg-window"></a>
## Window Settings

When you configure **Delay Tolerance Time**, messages that arrive after the window closes are also reflected in the results.

<a id="cg-window-fields"></a>
## Window Fields

| Item | Default Value | Description |
| --- | --- | --- |
| Delay Tolerance Time | 0 | Duration (in seconds) for which the collection status is maintained even after the window closes |

If you set Delay Tolerance Time to 0, messages that arrive late are discarded.

<a id="cg-detail"></a>
## View Details

View execution results in the **Details** tab.

<a id="cg-prose"></a>
## Next Steps

After configuring, click **Next**.

Select one of the following:

* Run the schedule immediately.
* Save the schedule only.