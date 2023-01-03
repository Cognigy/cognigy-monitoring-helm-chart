# Release Notes

### 1.3.1
**Released** January 3rd, 2023
#### Bugfixes
- Fixed `RedisMemoryHigh` alert for environments without memory limit on Redis

### 1.3.0
**Released** January 3rd, 2023
#### Bugfixes
- Fixed metrics on service-endpoint dashboard
#### Changes
- "Container Health" dashboard is introduced. "K8s service monitoring" dashboard is deprecated
- `ContainerOOMKilled` alert introduced
- `RedisMemoryHigh`, `RedisBlockedClients` and `RedisContainerRestarted` alerts are introduced
- `EndpointMessageProcessingTimeIncreasing` and `EndpointMessageProcessingTimeHigh` alerts are configurable 
- `ServiceHandoverErrorsHigh` alert is introduced 

### 1.2.3
**Released** December 19th, 2022
#### Bugfixes
- Fixed duplication of cadvisor metrics.
#### Changes
To fix metrics duplication on an already installed monitoring stack execute: `kubectl delete -n=kube-system service prom-kube-prometheus-stack-kubelet`

### 1.2.2
**Released** December 13th, 2022
#### Bugfixes
- Fixed and updated NLPv2 dashboards

### 1.2.1
**Released** December 9th, 2022
#### Bugfixes
- Fixed NLPv2 and Agent Overview dashboards

### 1.2.0
**Released** December 5th, 2022
#### Bugfixes
- Fixed Cognigy.AI dashoboards 

#### Improvements
- Added NLPv2 Dashboard
- Added NGiNX optional service dashboard

### 1.1.1
**Released** November 24th, 2022
#### Bugfixes
- Fixed migration and installation documentation

### 1.1.0
**Released** November 23th, 2022

#### Improvements
- Added PostgreSQL optional dashboard for LA and VG products 

#### Bugfixes
- Fixed missing dashboards for Pod services

### 1.0.2
**Released** November 22th, 2022

#### Bugfixes
- Fixed release pipeline and installation instructions

### 1.0.1
**Released** November 22th, 2022

#### Bugfixes
- Fixed release pipeline and Prometheus PVC configuration
