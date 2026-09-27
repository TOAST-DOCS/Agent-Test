<!-- pre-align:aligned sig=e2e0f1e1d00 -->

<a id="tfr"></a>
# table-field-rows e2e fixture

This document is a generated e2e fixture (20260927-030407).

<a id="tfr-overview"></a>
## Overview { #tfr-overview }

This API modifies service settings. Put only the fields to modify in the request body.

<a id="tfr-fields"></a>
## Request Body { #tfr-fields }

[Field]

| Name                  | Type    | Required | Default | Valid Range                                                    | Description                                                         |
| --------------------- | ------- | --------- | ------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| domain                | String  | Required      |        | Up to 255 characters                                                   | Domain (service name) to modify                                   |
| useOriginCacheControl | Boolean | Optional      |        | true/false                                                        | Set cache expiration (true: use origin server settings, false: use user settings). One of useOriginCacheControl or cacheType must be entered.      |
| cacheType             | String  | Optional      |        | BYPASS, NO_STORE            | Set cache type. One of useOriginCacheControl or cacheType must be entered.                                          |
| referrerType          | String  | Required      |        | BLACKLIST/WHITELIST                                          | Referrer access management ("BLACKLIST": Blacklist, "WHITELIST": Whitelist) |
| referrers             | List    | Optional      |        |                                                              | List of regex referrer headers |
| isAllowWhenEmptyReferrer | Boolean | Optional      | true      | true/false             | Whether to allow (true) or deny (false) access to content when there is no referer header             |
| description           | String  | Optional      |        | Up to 255 characters                                                   | Description                                                         |
| domainAlias           | List    | Optional      |        | Up to 255 characters                                                   | Domain alias (using a domain owned by individuals or companies) |
| defaultMaxAge         | Integer | Optional      | 0      | 0~2,147,483,647                                            | Cache expiration time (seconds), the default value 0 is 604,800 seconds.              |
| origins               | List    | Required      |        |                                                              | Origin server                                                    |
| origins[0].origin     | String  | Required      |        | Up to 255 characters                                                   | Origin server (domain or IP)                                      |
| origins[0].originPath | String  | Optional      |        | Up to 8192 characters                                                  | Sub-path of origin server                                          |
| forwardHostHeader     | String  | Required      |        | ORIGIN_HOSTNAME<br/>REQUEST_HOST_HEADER   | Set the host header to be forwarded by the CDN server when requesting content to the origin server ("ORIGIN_HOSTNAME": Set to the host name of the origin server, "REQUEST_HOST_HEADER": Set to the host header of the client request)|
| rootPathAccessControl  | Object  | Optional |  |  | Set the access control for the CDN service root path | 

- The default value of `forwardHostHeader` is `REQUEST_HOST_HEADER` when `domainAlias` is set.
