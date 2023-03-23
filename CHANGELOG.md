# Release Notes

### 1.11.0

**Released** March 23rd, 2023

#### Changes
- introduced `Agents Overview - V2` dashboard which includes filtering for organisation and project by names
- introduced `Analytics Odata` dashboards for Analytics
- introduced `VG` dashboards
- introduced `InfluxDB` data source for Voice Gateway
- introduced `MySQL Overview` dashboard

#### Bugfixes
- fixed `Postgresql Overview` dashboard
- fixed default MS Teams receivers configuration. Runtime MS Teams channel is disabled by default to prevent misconfigurations

### 1.10.0

**Released** March 10th, 2023

#### Changes
- introduced `Service NLP Orchestrator` and `Service NLP Embedding` dashboards for NLPv2
- adjusted visuals in `Service NLP Classifier` dashboard
- introduced `Analytics Reporter` dashboard for Analytics
- introduced organization selector to `Agents Overview` dashboard
- introduced  `RPC execution average time` dashboard for IDE Services

### 1.9.0

**Released** February 17th, 2023

#### Changes

- introduced `Service NLP Classifier` dashboard

### 1.8.0

**Released** February 16th, 2023

#### Changes

- introduced `Conversation Counter & Billing` dashboard

### 1.7.0

**Released** February 2, 2023

#### Changes

- introduced `GenerativeAI` dashboard

### 1.6.1

**Released** January 19th, 2023

#### Bugfixes

- disabled broken `MongodbReplicationLag` alert rule temporary
- fixed RabbitMQ alert rules

### 1.6.0

**Released** January 18th, 2023

#### Changes

- introduced `Horizontal Pod Autoscaler` dashboard
- introduced `Flux Overview` and `Flux Control Plane` dashboards
- added `HPAMaxReplicasReached` alert rule

#### Bugfixes

- fixed `MongodbReplicationLag` alert rule
- fixed `defaultRules` groups and rules severity

### 1.5.0

**Released** January 16th, 2023

#### Changes

- introduced `Analytics Collector` and `Analytics Conversations` dashboards

### 1.4.1

**Released** January 5th, 2023

#### Bugfixes

- Fixed `EndpointMessageProcessingTimeIncreasing` alert logic to avoid false positives
- Fixed timeouts for various alerts to avoid false positives

### 1.4.0

**Released** January 4th, 2023

#### Changes

- Cognigy alerts are grouped by service
- Traefik, NGiNX and MongoDB additional alerts groups are introduced
- Alert names are consolidated

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

**Released** November 23rd, 2022

#### Improvements

- Added PostgreSQL optional dashboard for LA and VG products

#### Bugfixes

- Fixed missing dashboards for Pod services

### 1.0.2

**Released** November 22nd, 2022

#### Bugfixes

- Fixed release pipeline and installation instructions

### 1.0.1

**Released** November 22nd, 2022

#### Bugfixes

- Fixed release pipeline and Prometheus PVC configuration
