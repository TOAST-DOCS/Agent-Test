<!-- machine_translated: true -->

<!-- pre-align:aligned sig=af6d5efd1d39 -->

<a id="compute-instance-feature-matrix"></a>
## Compute > Instance > Feature Matrix { #compute-instance-feature-matrix }

This document organizes the features provided by the Instance service from the perspective of regions and pricing plans. It includes tables, lists, code blocks, and nested headings for translation pipeline testing.

<a id="feature-overview"></a>
## Feature Overview { #feature-overview }

The main features of instances are as follows:

- **Create an instance**: Create a virtual server by selecting an image and instance type.
- **Instance Template**: Save frequently used settings as templates for reuse.
- **Scheduling**: Start or stop instances at a specified time.
- **Monitoring**: View CPU, memory, and disk usage on a dashboard.

<a id="feature-by-region"></a>
## Feature availability by region { #feature-by-region }

Features vary by region. Check the table below.

| Feature code | Feature name | Pangyo | Pyeongchon | Japan |
|---|---|---|---|---|
| INST-CREATE | Create an instance | Provided | Provided | Provided |
| INST-TPL | Instance Template | Provided | Provided | Not provided |
| INST-SCHED | Instance scheduling | Provided | Not provided | Not provided |
| INST-MON | Instance monitoring | Provided | Provided | Provided |

<a id="feature-by-plan"></a>
### Limits by pricing plan { #feature-by-plan }

The maximum number of instances you can create varies by pricing plan.

| Pricing plan | Maximum instances | Maximum block storage |
|---|---|---|
| Basic | 10 | 1 TB |
| Standard | 50 | 10 TB |
| Enterprise | Unlimited | Unlimited |

<a id="feature-api"></a>
## Verify features with the API { #feature-api }

You can also check feature availability using the API.

<a id="feature-api-request"></a>
### Query request { #feature-api-request }

Specify the feature code and call the API as shown in the example below.

```
curl -X GET "https://kr1-api-instance.example.com/v2/features?code=INST-CREATE" \
  -H "X-Auth-Token: {token}"
```

<a id="feature-api-response"></a>
#### Response fields

The main fields in the response body are as follows:

- `` `code` ``: Feature code
- `` `available` ``: Availability (true/false)
- `` `regions` ``: List of provided regions

<a id="feature-notes"></a>
## Notes { #feature-notes }

Feature availability may change with prior notice. For the latest information, check the console announcements.