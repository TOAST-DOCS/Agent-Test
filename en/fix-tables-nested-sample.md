<a id="fix-tables-nested-sample"></a>
## Nested Table Repair Sample { #fix-tables-nested-sample }

This document is a test fixture that verifies **broken table repair** keeps the indentation of a table nested in a list item.
The en/ja copies hold tables whose first-column identifiers differ from ko, and after the repair the tables must stay inside their list items.

This document is not registered in the user guide menu.

<a id="fix-tables-nested-list"></a>
## Tables in a List { #fix-tables-nested-list }

The following fields are added for each log type.

- **Training Log Fields**

    | Name | Description |
    | --- | --- |
    | trainingId | Training ID |

- **Endpoint Log Fields**

    | Name | Description |
    | --- | --- |
    | endpointId | Endpoint ID |

- **Endpoint Log Fields**

    | Name | Description |
    | --- | --- |
    | endpointId | Endpoint ID |
    | endpointStageId | Endpoint stage ID |

<a id="fix-tables-nested-deep"></a>
## Table in a Two-Level List { #fix-tables-nested-deep }

1. Write the request body.
    - **Required Fields**

        | Name | Format | Description |
        | --- | --- | --- |
        | UUID | UUID | Cluster UUID |
        | Integer | Integer | Number of nodes |

2. Send the request.

<a id="fix-tables-nested-top"></a>
## Table Not Indented { #fix-tables-nested-top }

The table in this section is outside a list. It must stay at column 0 after the repair.

| Name | Format | Description |
| --- | --- | --- |
| String | String | Region ID |
| String | String | Availability zone ID |

<a id="fix-tables-nested-untouched"></a>
## Correct Table in a List { #fix-tables-nested-untouched }

- **Response Fields**

    | Name | Description |
    | --- | --- |
    | jobId | Job ID |
    | jobName | Job name |
