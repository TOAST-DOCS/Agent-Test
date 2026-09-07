<!-- machine_translated: true -->

<!-- pre-align:aligned sig=af6d5efd1d39 -->

<a id="compute-instance-feature-matrix"></a>
## Compute > Instance > Feature Matrix { #compute-instance-feature-matrix }

This document organizes the features provided by the Instance service from the perspective of regions and pricing plans. It includes tables, lists, code blocks, and nested headings for translation pipeline testing.

<a id="feature-overview"></a>
## Feature Overview { #feature-overview }

The main features of the Instance service are as follows.

- **Create instances**: Create virtual servers by selecting an image and flavor.
- **Instance Template**: Save frequently used configurations as templates for reuse.
- **Scheduling**: Start or stop instances at specified times.
- **Monitoring**: View CPU, memory, and disk usage on the dashboard.

<a id="feature-by-region"></a>
## Features Available by Region { #feature-by-region }

Features available vary by region. See the table below.

| Feature Code | Feature Name | Pangyo | Pyeongchon | Japan |
|---|---|---|---|---|
| INST-CREATE | Create Instance | Available | Available | Available |
| INST-TPL | Instance Template | Available | Available | Not available |
| INST-SCHED | Instance Scheduling | Available | Not available | Not available |
| INST-MON | Instance Monitoring | Available | Available | Available |

<a id="feature-by-plan"></a>
### Limits by Pricing Plan { #feature-by-plan }

The maximum number of instances you can create varies by pricing plan.

| Pricing Plan | Maximum Instances | Maximum Block Storage |
|---|---|---|
| Basic | 10 | 1 TB |
| Standard | 50 | 10 TB |
| Enterprise | Unlimited | Unlimited |

<a id="feature-api"></a>
## Check Features with API { #feature-api }

You can also check feature availability through the API.

<a id="feature-api-request"></a>
### Query Request { #feature-api-request }

Specify the feature code and call as shown in the example below.

```
curl -X GET "https://kr1-api-instance.example.com/v2/features?code=INST-CREATE" \
  -H "X-Auth-Token: {token}"
```

<a id="feature-api-response"></a>
#### Response Fields

The main fields in the response body are as follows.

- `code`: Feature code
- `available`: Feature availability (true/false)
- `regions`: List of regions where the feature is available

<a id="feature-notes"></a>
## Notes { #feature-notes }

Feature availability may be subject to change after prior notice. For the latest information, check the console announcements.