# Release Notes

### 1.21.0
**Released** April 16th, 2024

#### Changes
- Grafana updated to v10.4.1
- Thanos dashboards are introduced
- Kubernetes v1.28 is supported
- New panels are introduced in `Service NLP Classifier` dashboard
- MongoDB dashboard is updated
- `HighConversationVolume` alert rule is introduced
- `KubePodCrashLooping` alert is parametrized
- RabbitMQ alert rules are parametrized

#### Bugfixes
- Default dashboard refresh interval is set to 5 minutes
- `Service-API` dashboard is fixed
- Dashboard conversion script is fixed

### 1.20.0
**Released** February 14th, 2024

#### Changes
- **IMPORTANT:** Legacy single-replica Redis and MongoDB exporters are deprecated. This release is compatible with Cognigy.AI and Cognigy.VG
v4.65+ only which are deployed with Redis HA setups.
- NLPv1 is removed from `Agents Overview`. Knowledge AI panels are fixed.
- Added `LiveAgentEndpointSlowRequest` and `PostgresqlTooManyLocksAcquired` alerts.
- `MongoDB Overview` dashboard is refactored.
- Dashboards are converted into YAML format for Thanos compatibility.

#### Bugfixes
- `LiveAgentHighHttpErrorRate` alert is fixed to catch sparsely distributed errors.

### 1.19.0
**Released** January 10th, 2024

#### Changes
- `Agents Overview v2` is renamed to `Agents Overview` dashboard. Previous version of `Agents Overview` dashboard is deprecated.
- `Extensions Executions / Minute` panel is added to `Service-Execution` dashboard.
- `Functions Scheduled / Minute` and  `Functions Executions / Minute` panels are added to `Service-Function-Execution` dashboard.
- `Dead-lettered Messages` panel added to `Service-Endpoint` and `Service-AI` dashboards. 
- `Agent Assist Backend` dashboard is extended.
- `Insights Cube Reports` dashboard is introduced. 
- `VG Feature-Server` dashboard is extended.

#### Bugfixes
- Several panels are fixed on `Agents Overview` dashboard.
- `Cluster Resources - Nodegroups` dashboard is fixed.
- `Service NLP Classifier` dashboard is fixed.

### 1.18.1

**Released** December 1st, 2023

#### Bugfixes
- Fixed Kubernetes versions compatibility.

### 1.18.0

**Released** November 24th, 2023

#### Changes
- Added `Cluster Resources - Nodegroups` dashboard.

#### Bugfixes
- Fixed `PodManyRestarts` alert logic.
- Fixed `Redis Instances Overview` dashboard.
- Improved performance of queries in `Kubecost Global` dashboard.
- Fixed `Agent Assist Backend` dashboard.

### 1.17.1

**Released** October 24th, 2023

#### Bugfixes
- Fixed `Live Agent Overview` dashboard.
- Fixed `PostgreSQL Overview` dashboard.
- Fixed `LiveAgentHighHttpErrorRate` alert rule.
- Fixed `CPUThrottlingBackendServiceHigh` to catch LA PostgreSQL alerts.

### 1.17.0

**Released** October 16th, 2023

#### Changes
- Added Postgres alert rules.

#### Bugfixes
- Fixed `RedisBlockedClients` alert to avoid false positives.
- Fixed `CPUThrottlingBackendServiceHigh` to avoid false positives from `metrics` container.
- Fixed `PostgreSQL Patroni` dashboard.
- Fixed `kube-state-metrics` compatibility with Kubernetes v1.26.

### 1.16.0

**Released** October 6th, 2023

#### Changes
- Added `IDE NFS Status` dashboard.
- Added `Cluster Upgrades` dashboard.
- Added pod monitor for postgres-ha setup.
- Added new metrics to `Agent Assist Genesys Notifications Forwarder` dashboard.

#### Bugfixes
- Fixed `Kubecost Global` dashboard.

### 1.15.0

**Released** September 7th, 2023

#### Changes
- Enabled filtering on namespaces and pod names on `Redis Instances Overview` dashboard.
- Added dynamic organisation and project tables on `Agents Overview v2` dashboard.
- Added `Live Agent OData Overview` dashboard.
- Added `Knowledge AI search` metrics to `Agents Overview v2` dashboard.
- Added `Agent Assist Genesys Notifications Forwarder` dashboard.
- Added alerts for Insights services.
- Added several VG dashboards.
- Added optional `Kubecost Global` dashboard.
- Added optional dashboard and alerts for Velero.

#### Bugfixes
- Fixed `containerOOMKilled` logic to catch the first occurrence.
- Fixed Timezone `defaultDashboardsTimezone` on dashboards.
- Fixed VG dashboards names.

### 1.14.0

**Released** July 17th, 2023

#### Changes
- Introduced `Kubernetes Cluster Autoscaler (AWS)` dashboard.
- Made parameters for `RedisBlockedClients` alert configurable.
- Added SMTP metrics to `Service-AI` dashboard.
- Introduced Prometheus `podMonitor` for Flux CD.

#### Bugfixes
- Fixed various dashboards for NLP V2.
- Fixed `VG Overview` dashboard.
- Fixed `Agent Assist Backend` dashboard.

### 1.13.1

**Released** June 7th, 2023

#### Bugfixes
- Fixed default timeout of `ContainerOOMKilled` alert.
- Fixed `MatcherFindKeyphraseError` alert.
- Fixed `EndpointMessageProcessingTimeIncreasing` alert logic with `messageProcessingTimeBaseline` parameter.

### 1.13.0

**Released** May 26th, 2023

#### Changes
- Made parameters for `cognigy.alert.k8s` configurable, see [values.yaml](cognigy-monitoring/charts/cognigy-alerts/values.yaml)
for details.
- Changed default severity of `kubeDeploymentReplicasMismatch`, `kubePodNotReady` and `kubeStatefulSetReplicasMismatch`
to `warning`, use `severity` configuration parameter to override default setting.
- Made `ServiceHandoverErrorsHigh` configurable, see [values.yaml](cognigy-monitoring/charts/cognigy-alerts/values.yaml) for details.
- Introduced `xApps Metrics` dashboard.
- Introduced `Weaviate` dashboards.
- Introduced `Agent Assist Backend` and  `Agent Assist Frontend` dashboards.

### 1.12.0

**Released** April 27th, 2023

#### Changes
- Updated `VG` dashboards.
- Introduced `HostOutOfMemory` and `HostMemoryUnderMemoryPressure` alerts.
- Introduced `Request Handover` dashboard.
- Made `mongodbReplicationLag` alert configurable.
- Made `traefikHighHttp5xxErrorRateService` alert configurable.

#### Bugfixes
- Fixed `Kubecost Overview` dashboard.
- Fixed `mongodbReplicationLag` alert.
- Fixed `Live Agent` dashboard.

### 1.11.0

**Released** March 23rd, 2023

#### Changes
- Introduced `Agents Overview - V2` dashboard which includes filtering for organisation and project by names.
- Introduced `Analytics Odata` dashboards for Analytics.
- Introduced `VG` dashboards.
- Introduced `InfluxDB` data source for Voice Gateway.
- Introduced `MySQL Overview` dashboard.

#### Bugfixes
- Fixed `Postgresql Overview` dashboard.
- Fixed default MS Teams receivers configuration. Runtime MS Teams channel is disabled by default to prevent misconfigurations.

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
