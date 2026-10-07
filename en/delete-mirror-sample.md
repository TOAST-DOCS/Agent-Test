<!-- pre-align:aligned sig=866682166a59 -->

<a id="delete-mirror-overview"></a>
## Delete Mirror Test { #delete-mirror-overview }

This document is a fixture that reproduces a ko PR that only **deletes** one sub-block inside a section while
the same PR has already removed that block from en/ja (TOAST-DOCS/Network#160 → #163, 2026-10-07).
If sibling bullets that ko did not touch change in en/ja, it is a defect.

<a id="delete-mirror-2025-11-25"></a>
### November 25, 2025 { #delete-mirror-2025-11-25 }

<a id="delete-mirror-2025-11-25-added-features"></a>
#### Added Features

##### VPN Gateway
* When you connect a Transit Hub to a VPC with a VPN connection, VPN communication with on-premises networks is also supported from VPCs of other projects connected via the Transit Hub. (An additional VPN Connection must be created for the connected bandwidth.)

##### DNS Plus
* Improved so that custom headers can be added to GSLB health checks.
* Added the traffic weight setting feature per pool.

##### Service Gateway
* Improved so that you can create a Service Gateway with a fixed NAT IP.

##### Load Balancer
* Added the custom response configuration feature per listener.
* Added the feature to enable/disable X-Forwarded-* headers.

<a id="delete-mirror-2024-05-28"></a>
### May 28, 2024 { #delete-mirror-2024-05-28 }

<a id="delete-mirror-2024-05-28-feature-updates"></a>
#### Feature Updates

##### DNS Plus
* Added the bulk record set registration feature when using the domain service.

##### Load Balancer
* Improved so that IP access control can be configured together in the basic information when creating a load balancer.

<a id="delete-mirror-control"></a>
### March 14, 2023 { #delete-mirror-control }

<a id="delete-mirror-control-added-features"></a>
#### Added Features

##### Service Gateway
* Released the Service Gateway service.
