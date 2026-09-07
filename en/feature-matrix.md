<!-- machine_translated: true -->

<!-- pre-align:aligned sig=af6d5efd1d39 -->

<a id="compute-instance-feature-matrix"></a>
## Compute > Instance > Feature matrix { #compute-instance-feature-matrix }

This document describes the features provided by the Instance service from the perspectives of regions and billing plans. For translation pipeline testing, it includes tables, lists, code blocks, and nested headings.

<a id="feature-overview"></a>
## Feature overview { #feature-overview }

The main features of Instance service are as follows:

- **Create Instance**: Create a virtual server by selecting an image and instance type.
- **Instance Template**: Save frequently used settings as a template for reuse.
- **Scheduling**: Start or stop an instance at a specified time.
- **Monitoring**: View CPU, memory, and disk usage on the dashboard.

<a id="feature-by-region"></a>
## Feature availability by region { #feature-by-region }

Feature availability varies by region. Check the table below.

| Feature Code | Feature Name | Pangyo | Pyeongchon | Japan |
|---|---|---|---|---|
| INST-CREATE | Create Instance | Available | Available | Available |
| INST-TPL | Instance Template | Available | Available | Not available |
| INST-SCHED | Instance Scheduling | Available | Not available | Not available |
| INST-MON | Instance Monitoring | Available | Available | Available |

<a id="feature-by-plan"></a>
### Billing plan limits { #feature-by-plan }

The maximum number of instances you can create varies by billing plan.

| Billing Plan | Maximum Instances | Maximum Block Storage |
|---|---|---|
| Basic | 10 | 1 TB |
| Standard | 50 | 10 TB |
| Enterprise | Unlimited | Unlimited |

<a id="feature-api"></a>
## Checking features with API { #feature-api }

You can also check feature availability using the API.

<a id="feature-api-request"></a>
### Query request { #feature-api-request }

Call the API by specifying the feature code as shown in the example below.

```
curl -X GET "https://kr1-api-instance.example.com/v2/features?code=INST-CREATE" \
  -H "X-Auth-Token: {token}"
```

<a id="feature-api-response"></a>
#### Response fields

The main fields in the response body are as follows:

- `code`: Feature code
- `available`: Whether the feature is available (true/false)
- `regions`: List of regions where the feature is available

<a id="feature-notes"></a>
## Notes { #feature-notes }

Feature availability may change after prior notice. For the latest information, check the console announcements.