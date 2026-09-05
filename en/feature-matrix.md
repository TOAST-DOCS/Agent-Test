<!-- machine_translated: true -->

<!-- pre-align:aligned sig=af6d5efd1d39 -->

<a id="compute-instance-feature-matrix"></a>
## Compute > Instance > Feature Matrix { #compute-instance-feature-matrix }

This document summarizes the features provided by the Instance service by region and pricing plan. It includes tables, lists, code blocks, and nested headings for translation pipeline testing.

<a id="feature-overview"></a>
## Feature Overview { #feature-overview }

The main features of Instance are as follows.

- **Create an Instance**: Select an image and type to create a virtual server. (list modification test)
- **Instance Template**: Save frequently used settings as a template and reuse them.
- **Scheduling**: Start or stop an instance at a specified time.
- **Monitoring**: Check CPU, memory, and disk usage in the dashboard.

<a id="feature-by-region"></a>
## Feature Availability by Region { #feature-by-region }

Available features vary by region. See the table below.

| Function Code | Function Name | Pangyo | Pyeongchon | Japan (Modified) |
|---|---|---|---|---|
| INST-CREATE | Create Instances | Available | Available | Available |
| INST-TPL | Instance Templates | Available | Available | Not available |
| INST-SCHED | Instance Scheduling | Available | Not available | Not available |
| INST-MON | Instance Monitoring | Available | Available | Available |

<a id="feature-by-plan"></a>
### Limits and details by pricing plan { #feature-by-plan }

The number of instances you can create differs by pricing plan.

| Plan | Max Instances | Max Block Storage |
|---|---|---|
| Basic | 10 | 1TB |
| Standard | 50 | 10TB |

<a id="feature-api"></a>
## Checking Features via API { #feature-api }

Feature availability can also be queried via the API.

<a id="feature-api-request"></a>
### Query Request { #feature-api-request }

Call the API with a feature code as shown below.

```
curl -X GET "https://kr1-api-instance.example.com/v2/features?code=INST-CREATE" \
  -H "X-Auth-Token: {token}"
```

<a id="feature-api-response"></a>
#### Response Fields

The main fields of the response body are as follows.

- `code`: feature code
- `available`: availability (true/false)
- `regions`: list of available regions

<a id="feature-notes"></a>
## Notes { #feature-notes }

Feature availability is subject to change with prior notice. Check the console announcements for the latest information.
