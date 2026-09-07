<!-- machine_translated: true -->

<!-- pre-align:aligned sig=af6d5efd1d39 -->

<a id="compute-instance-feature-matrix"></a>
## Compute > Instance > Feature Matrix { #compute-instance-feature-matrix }

This document describes the features provided by the Instance service from the perspective of regions and billing plans. For translation pipeline testing, it includes tables, lists, code blocks, and nested headings.

<a id="feature-overview"></a>
## Feature Overview { #feature-overview }

The main features of instances are as follows:

- **Create Instance**: Creates a virtual server by selecting an image and flavor.
- **Instance Template**: Saves frequently used settings as a template for reuse.
- **Scheduling**: Starts or stops instances at a specified time.
- **Monitoring**: Monitors CPU, memory, and disk usage on the dashboard.

<a id="feature-by-region"></a>
## Feature Availability by Region { #feature-by-region }

Features available vary by region. Check the table below.

| Feature Code | Feature Name | Pangyo | Pyeongchon | Japan |
|---|---|---|---|---|
| INST-CREATE | Create Instance | Available | Available | Available |
| INST-TPL | Instance Template | Available | Available | Not Available |
| INST-SCHED | Instance Scheduling | Available | Not Available | Not Available |
| INST-MON | Instance Monitoring | Available | Available | Available |

<a id="feature-by-plan"></a>
### Limits by Billing Plan { #feature-by-plan }

The maximum number of instances you can create varies by billing plan.

| Billing Plan | Maximum Instances | Maximum Block Storage |
|---|---|---|
| Basic | 10 | 1 TB |
| Standard | 50 | 10 TB |
| Enterprise | Unlimited | Unlimited |

<a id="feature-api"></a>
## Check Features via API { #feature-api }

You can also query feature availability by using the API.

<a id="feature-api-request"></a>
### Query Request { #feature-api-request }

Call the API with the feature code specified, as shown in the example below.

```
curl -X GET "https://kr1-api-instance.example.com/v2/features?code=INST-CREATE" \
  -H "X-Auth-Token: {token}"
```

<a id="feature-api-response"></a>
#### Response Fields

The main fields in the response body are as follows:

- `code`: Feature code
- `available`: Availability (true/false)
- `regions`: List of regions where available

<a id="feature-notes"></a>
## Notes { #feature-notes }

Feature availability may change after prior notice. For the latest information, check the console announcements.