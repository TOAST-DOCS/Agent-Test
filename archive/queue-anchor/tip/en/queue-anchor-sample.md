<!-- pre-align:aligned sig=bbbbbbbbbbbb -->
## Flow { #flow }

<a id="flow-overview"></a>
### Overview { #flow-overview }

Create and run flows.

<a id="execution-history"></a>
### Execution History { #execution-history }

Displays the execution history of flows in execution units.

<a id="execution-history-execution-list"></a>
#### Execution List

* Displays the execution ID, status, start time, end time, and elapsed time.
* Failure Reason
    * Displays the failure reason for failed executions. The failure reason is one of the following three:
        * The flow's engine type cannot be executed.
        * The executable flow resources have been exceeded.
        * Failed to execute the flow.
* Filter
    * You can narrow the list by selecting one of All, Success, or Failure using the status filter.
    * You can select one of Last 1 day, Last 7 days, Last 30 days, or All using the period filter.

<a id="execution-history-execution-details"></a>
#### Execution Details

* Overview
    * Displays the execution ID, execution status, start time, and end time.
* Logs
    * **Copy Log Query**: Copies the query that retrieves only the logs of this execution.

<a id="execution-history-execution-metrics"></a>
#### Execution Metrics

Displays the graph and metric charts for the selected execution in a modal window.

* Period
    * Select **Full Execution** to view metrics from the start to the end of the execution.
    * Metrics are retained for up to the last 16 days.

<a id="schedule-list"></a>
### Schedule List { #schedule-list }

Displays registered schedules.
