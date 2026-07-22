<!-- pre-align:aligned sig=af6d5efd1d39 -->

<a id="compute-instance-feature-matrix"></a>
## Compute > Instance > Feature Matrix { #compute-instance-feature-matrix }

This document summarizes the features provided by the Instance service by region and pricing plan. It includes tables, lists, code blocks, and nested headings for translation pipeline testing.

<a id="feature-overview"></a>

### New subsection for validating automatic ID assignment

This subsection is a new h3 created to validate automatic anchor ID assignment in the translation pipeline. When the Korean version is modified without adding an anchor ID, the translation job should assign the same ID across all three languages: Korean, English, and Japanese.

<a id="feature-overview"></a>

## Feature Overview { #feature-overview }

The main features of Instance are as follows.

- **Create an Instance**: Create a virtual server by selecting an image and type. (list edit test)
- **Instance Template**: Save frequently used settings as a template and reuse them.
- **Scheduling**: Start or stop an instance at a specified time.
- **Monitoring**: View CPU, memory, and disk usage on the dashboard.

<a id="feature-by-region"></a>

## Feature Availability by Region { #feature-by-region }

Available features vary by region. See the table below.

| Feature Code | Feature Name | Pangyo | Pyeongchon | Japan (updated) |
|---|---|---|---|---|
| INST-CREATE | Create Instances | Available | Available | Available |
| INST-TPL | Instance Templates | Available | Available | Not available |
| INST-SCHED | Instance Scheduling | Available | Not available | Not available |
| INST-MON | Instance Monitoring | Available | Available | Available |
| TEST-ROW | (New row test) | (New row test) | (New row test) | (New row test) |

<a id="feature-by-plan"></a>
### Limits by Pricing Plan { #feature-by-plan }

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
