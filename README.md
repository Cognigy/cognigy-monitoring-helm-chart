![Cognigy.AI banner](assets/cognigy-ai.png)

# Cognigy Monitoring Stack Helm Chart
This chart installs Cognigy Monitoring Stack which is based on [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)

## Prerequisites
1. Kubernetes cluster running one or more of [Cognigy Products](https://github.com/orgs/Cognigy/repositories)
2. `kubectl` and `helm` utilities connected to the Kubernetes cluster in administrative mode.
3. Kubernetes, kubectl and Helm versions as specified in [Version Compatibility Matrix](https://docs.cognigy.com/ai/installation/version-compatibility-matrix/).

## Installation
1. To deploy a Helm Release for Monitoring Stack you need to create a separate file with Helm release values. You can use `values_prod.yaml` as a baseline, we recommend to start with it. Make a copy of `values_prod.yaml` into a new file and name it accordingly, we refer to it as `YOUR_VALUES_FILE.yaml` later in this document.
2. Set the essential parameters in `YOUR_VALUES_FILE.yaml`, see the comments inside the file.
3. Create the `monitoring` namespace.
   ```shell
   kubectl create namespace monitoring
   ```
4. Create a [`docker-registry`](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/) type secret to pull the images from Cognigy container registry and name it as `cognigy-registry-token`. Provide your Cognigy container registry credentials.
   ```shell
   kubectl create secret docker-registry cognigy-registry-token \
     --namespace=monitoring \
     --docker-server=cognigy.azurecr.io \
     --docker-username=<your-username> \
     --docker-password=<your-password>
   ```
5. Install Monitoring Stack Helm Release:
   * Installing from Cognigy Container Registry (recommended), specify proper `HELM_CHART_VERSION` (check [CHANGELOG](CHANGELOG.md) for details) and `YOUR_VALUES_FILE.yaml`:
      * Login into Cognigy helm registry (provide your Cognigy Container Registry credentials):
         ```shell
         helm registry login cognigy.azurecr.io \
           --username <your-username> \
           --password <your-password>
         ```
      * Install Helm Chart into a separate `monitoring` namespace:
         ```shell
         helm upgrade --install --create-namespace -n monitoring monitoring-stack oci://cognigy.azurecr.io/helm/cognigy-monitoring --version HELM_CHART_VERSION --values YOUR_VALUES_FILE.yaml
         ```
   * Alternatively you can install it from the local chart (not recommended):
      ```shell
      helm upgrade --install --create-namespace -n monitoring monitoring-stack ./cognigy-monitoring --values YOUR_VALUES_FILE.yaml
      ```
6. If Grafana ingress is disabled you can access the grafana directly by using kubectl port-forwarding: `kubectl port-forward svc/monitoring-stack-grafana 3000:80`. Then access Grafana via `http://localhost:3000`. Use Grafana credentials you have set in `YOUR_VALUES_FILE.yaml`
7. If Grafana ingress is enabled, add Grafana hostname to DNS and access Grafana via browser.
8. If the storage class is not specified in `YOUR_VALUES_FILE.yaml`, set: `kubepromstack.prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName: prometheus` in the `YOUR_VALUES_FILE.yaml` file. **Note: The storage class must be deployed before the Helm chart.**
9. Enable Prometheus Monitors for Cognigy products in respective Helm Charts:
   - For [MongoDB Helm Chart](https://github.com/Cognigy/cognigy-mongodb-helm-chart/tree/master/charts/bitnami/mongodb) set `metrics.serviceMonitor.enabled: true` in `values.yaml` of MongoDB Helm Release.
   - For [Cognigy.AI Helm Chart](https://github.com/Cognigy/cognigy-ai-helm-chart) set `podMonitors.enabled: true`, `redisHa.metrics.serviceMonitor.enabled: true` and `redisPersistentHa.metrics.serviceMonitor.enabled: true` in `values.yaml` of Cognigy.AI Helm Release.
   - For [Live Agent Helm Chart](https://github.com/Cognigy/cognigy-live-agent-helm-chart) set `monitoring.enabled: true` in `values.yaml` of Cognigy LA Helm Release.
   - For [Voice Gateway Helm Chart](https://github.com/Cognigy/cognigy-vg-helm-chart) set `podMonitors.enabled: true` and `podMonitors.namespace: "monitoring"` in `values.yaml` of Cognigy VG Helm Release.
   - To enable additional `ServiceMonitor` for databases and backends included as dependencies in the Cognigy Helm Charts (AI, LA, VG) enable `serviceMonitor` according to the `values.yaml` of the respective Chart.

## Azure Load Balancer monitoring (Promitor)

The chart can optionally deploy [Promitor](https://promitor.io/) to pull Azure Monitor metrics for Azure Load Balancers into Prometheus.

### Prerequisites
1. Create an Azure Service Principal with **Reader** on the target subscription:
   ```shell
   az ad sp create-for-rbac \
     --name cognigy-monitoring-promitor \
     --role Reader \
     --scopes /subscriptions/<YOUR_SUBSCRIPTION_ID>
   ```
   Note the returned `appId`, `password`, and `tenant`. The `password` is shown only once.
2. Grant the SP **Monitoring Reader** on the same subscription (Reader alone returns empty metrics):
   ```shell
   az role assignment create \
     --assignee <APP_ID> \
     --role "Monitoring Reader" \
     --scope /subscriptions/<YOUR_SUBSCRIPTION_ID>
   ```
3. Create the SP-password Secret in the `monitoring` namespace of the target cluster.
   ```shell
   kubectl create secret generic promitor-azure-credentials \
     --namespace=monitoring \
     --from-literal=azure-app-key='<SP_APP_KEY_PASSWORD>'
   ```
   The Secret's name (`promitor-azure-credentials`) and data-key (`azure-app-key`) match the defaults in the chart's `promitorDiscovery.secrets` / `promitorScraper.secrets` reference block. If you use a different name or data-key, override both `promitorDiscovery.secrets.secretName` (and `promitorScraper.secrets.secretName`) — they must stay in lock-step.

### Enable in monitoring stack
1. In `YOUR_VALUES_FILE.yaml` (your copy of `values_prod.yaml`), edit the `promitorDiscovery` block:
   ```yaml
   promitorDiscovery:
     enabled: &promitorEnabled true                          # flag to enable/disable
     azureAuthentication:
       identity:
         id: &promitorAppId "<SP_APP_ID>"                    # Service Principal appId
     azureLandscape:
       tenantId: &promitorTenantId "<AAD_TENANT_ID>"         # AAD tenant
       subscriptions:
         - &promitorSubscriptionId "<SUBSCRIPTION_ID>"       # subscription that owns this AKS
   ```
2. Install / upgrade the Helm release.
   ```shell
   helm upgrade --install -n monitoring monitoring-stack \
     oci://cognigy.azurecr.io/helm/cognigy-monitoring \
     --version HELM_CHART_VERSION \
     --values YOUR_VALUES_FILE.yaml
   ```
3. Verify the agents:
   ```shell
   kubectl -n monitoring rollout status deploy/promitor-discovery
   kubectl -n monitoring rollout status deploy/promitor-scraper
   kubectl -n monitoring port-forward svc/promitor-scraper 8888:8888
   curl -s http://localhost:8888/metrics | grep '^azure_lb_' | head
   ```
4. In Prometheus, confirm the `promitor-scraper` target is **UP** under **Status → Targets**.

## Distributed Tracing (Grafana Alloy)

The chart can optionally deploy [Grafana Alloy](https://grafana.com/docs/alloy/latest/) as the
per-cluster OTLP edge collector for the regional Grafana Tempo tracing rollout. It receives OTLP
traces from product services, enriches them with Kubernetes and cluster identity, tail-samples
them, and forwards the result to the cluster's regional Tempo — buffering to a disk queue so a
Tempo outage doesn't drop spans while the pod is alive. That queue is pod-local (`emptyDir`), not
durable: it does not survive a pod restart, reschedule, or scale-down. See [Scaling](#scaling)
below.

Two subcharts are involved, both disabled by default:
- `alloy` — the vendored upstream chart. Owns the workload (Deployment, HPA, Services, RBAC,
  ServiceMonitor).
- `cognigy-alloy` — in-house. Owns only the rendered Alloy configuration (the ConfigMap).

### Prerequisites
1. `docker.io/grafana/alloy:v1.19.2` must be mirrored to `cognigy.azurecr.io/grafana-alloy:v1.19.2`
   (flat repository name, not upstream's `grafana/alloy` path) — every other image in this chart is
   pulled from Cognigy's registry, and this collector is no exception. The config reloader sidecar
   needs no separate mirror; it's pinned to the tag already pulled by the vendored
   kube-prometheus-stack (`v0.83.0`).
2. A regional Tempo OTLP gRPC endpoint reachable from the cluster.

### Enable in monitoring stack
1. In `YOUR_VALUES_FILE.yaml`, enable both subcharts and set the two required values:
   ```yaml
   alloy:
     enabled: true
   cognigy-alloy:
     enabled: true
     clusterName: "<your-flux-cluster-name>"        # e.g. "foo-corp-dev"
     tempo:
       endpoint: "<tempo-host>:4317"                # e.g. "tempo-prod-eu.internal:4317"
   ```
   All other collector behavior — sampling policies, batch sizes, queue sizing — has sane
   defaults in `cognigy-monitoring/charts/cognigy-alloy/values.yaml`; override there only if a
   cluster needs something different (e.g. a higher baseline sampling rate than the 10% default).
   That also includes `clusterAttribute` (default `"cluster"`), the resource attribute key
   `clusterName` is written to on every span — override it only to match a `tempo-query`
   `routing.clusterAttribute` (`resource.<this value>`) that was already deployed with a
   different key.
2. Install / upgrade the Helm release (see step 5 under [Installation](#installation)).
3. Verify the collector:
   ```shell
   kubectl -n monitoring rollout status deployment/cognigy-alloy
   kubectl -n monitoring logs -l app.kubernetes.io/name=alloy -c alloy --tail=200 | grep -i error
   ```
   A healthy pod logs no `error` lines beyond transient startup warnings on first boot (DNS for
   the clustering headless Service not yet populated resolves within the same second).
4. Send a test trace and confirm it reaches Tempo:
   ```shell
   kubectl -n monitoring exec -it deploy/some-test-client -- \
     telemetrygen traces --otlp-endpoint=cognigy-alloy:4317 --otlp-insecure --duration=5s
   ```
   At more than one replica, confirm the trace-ID load-balancing hop is spreading traffic:
   `otelcol_receiver_accepted_spans{component_id=~".*internal.*"}` should be non-zero on more than
   one pod.

### Authenticating to a remote Tempo

The `X-Scope-OrgID` tenant header above is always sent, but it's multi-tenancy routing, not
authentication. A **remote** Tempo cluster needs real credentials, and those must come from a
Kubernetes Secret — never from `values.yaml`. Set `cognigy-alloy.tempo.auth.type` to select the
mechanism, then wire the actual Secret into the vendored `alloy` chart's own generic knobs
(`extraEnv` / a Secret volume) using the **exact** env var names or mount path below — this chart's
template reads fixed names, it doesn't take a secret name as a value:

| `tempo.auth.type` | Secret keys (create the Secret yourself) | What to add to `YOUR_VALUES_FILE.yaml` |
|---|---|---|
| `basic` | `username`, `password` (matches `kubernetes.io/basic-auth`) | `alloy.alloy.extraEnv` with two `valueFrom.secretKeyRef` entries → env vars `TEMPO_AUTH_USERNAME`, `TEMPO_AUTH_PASSWORD` |
| `bearer` | `token` | `alloy.alloy.extraEnv` with one `valueFrom.secretKeyRef` → env var `TEMPO_AUTH_TOKEN` |
| `mtls` | `tls.crt`, `tls.key` (matches `kubernetes.io/tls`) | `alloy.controller.volumes.extra` (a Secret volume) + `alloy.alloy.mounts.extra` (mounted at `/etc/alloy-secrets/tempo-mtls`) |

Example for `basic`:
```yaml
cognigy-alloy:
  tempo:
    auth:
      type: basic

alloy:
  alloy:
    extraEnv:
      - name: TEMPO_AUTH_USERNAME
        valueFrom: { secretKeyRef: { name: tempo-remote-credentials, key: username } }
      - name: TEMPO_AUTH_PASSWORD
        valueFrom: { secretKeyRef: { name: tempo-remote-credentials, key: password } }
```
Example for `mtls`:
```yaml
cognigy-alloy:
  tempo:
    auth:
      type: mtls

alloy:
  controller:
    volumes:
      extra:
        # `extra` REPLACES the whole list — include alloy-data (the queue
        # volume already set in values.yaml) or you'll silently drop it.
        - name: alloy-data
          emptyDir: { sizeLimit: 10Gi }
        - name: tempo-mtls
          secret: { secretName: tempo-remote-client-cert }
  alloy:
    mounts:
      extra:
        - name: alloy-data
          mountPath: /var/lib/alloy
        - name: tempo-mtls
          mountPath: /etc/alloy-secrets/tempo-mtls
          readOnly: true
```
Server-CA verification is the separate, pre-existing `tempo.tls.caFile` knob — mTLS only adds the
*client* certificate.

**Helm cannot catch a mismatch here** — `cognigy-alloy.tempo.auth.type` and the `alloy.*` env/volume
wiring live in two different subcharts' values, invisible to each other at render time, the same
way `alloy.fullnameOverride` and `cognigy-alloy.alloyFullname` must be kept in sync manually.
Verified in a real cluster: if you enable `basic`/`bearer` but forget the matching `extraEnv`, the
collector does **not** start and silently send empty credentials — `otelcol.auth.basic`/`.bearer`
validate at config-load time and refuse to build with an empty value (`sys.env()` on an unset
variable is `""`, and the component then fails with `no credential source provided`), which is a
fatal config-load error for the whole collector — the pod goes into `CrashLoopBackOff`, loudly, not
a silent security hole. That's the safe failure mode; it's called out here so the crash makes
sense instead of looking like an unrelated bug.

**Also verified**: `basic`/`bearer` auth over `tempo.tls.insecure: true` fails outright with
`grpc: the credentials require transport level security` — gRPC's own guard against sending
credentials in cleartext. This is a non-issue against a real remote Tempo (which uses TLS anyway),
but it means `auth.type: basic|bearer` and `tempo.tls.insecure: true` cannot be combined, including
in test setups — use `insecureSkipVerify: true` against a self-signed endpoint instead of
`insecure: true` if you need to skip certificate validation while testing.

### Routing traces to a different destination

By default every trace goes to the one Tempo endpoint above. Some traces need to go somewhere
else instead — for example, internal application-level traces that should land on an in-cluster
OpenTelemetry-compatible collector rather than the shared platform Tempo. Add an entry to
`cognigy-alloy.routes` in `YOUR_VALUES_FILE.yaml`:
```yaml
cognigy-alloy:
  routes:
    - name: app_traces                                             # [a-z][a-z0-9_]*, not "default"
      match: 'resource.attributes["cognigy.trace.route"] == "app"'  # raw OTTL boolean expression
      tempo:
        endpoint: "app-otel-collector.cognigy-ai.svc.cluster.local:4317"
        tls: {insecure: true}
```
A trace matching a route's condition goes to that route's endpoint **instead of** the default
Tempo — never both. Routes are simpler than the default chain: everything that matches is kept
as-is (no tail-sampling) with an in-memory-only queue, not the disk-backed one.

`match` is a raw OTTL boolean expression, evaluated per-span (`context = "span"`) — it can
reference resource attributes like `k8s.namespace.name` or `cluster` (the attribute key configured
via `clusterAttribute`, default `"cluster"` — see below) via the `resource.`
prefix (both are already set on every span by the time routing happens), or span-level fields
directly. **A malformed expression is a collector-wide startup failure at the Alloy level, not a
`helm template` error** — always validate a new or changed route with `alloy fmt` (and ideally
`alloy run` against the rendered config) before rolling it out; see the plan / PR description for
the exact commands used to develop this feature.

### Scaling

The collector runs as a Deployment behind a CPU-based HPA, `alloy.controller.autoscaling.horizontal`,
default `minReplicas: 1` / `maxReplicas: 3` / `targetCPUUtilizationPercentage: 80` — override per
cluster, or set `enabled: false` and use `alloy.controller.replicas` for a fixed count.

Things worth knowing before enabling this in a non-loadtest cluster:
- `alloy.alloy.resources.requests.cpu` (200m) is the utilization denominator and has no CPU limit,
  so under real traffic the HPA behaves as an on/off switch to `maxReplicas` rather than a
  proportional scaler. This is expected to also trip the existing `HPAMaxReplicasReached` alert —
  that's a known, accepted consequence, not a bug.
- Each scale event reshuffles the trace-ID load-balancing ring for one `sampling.decisionWait`
  window, splitting in-flight traces across old and new ring members.
- Scale-down discards the departing replica's queue backlog (see the durability note above).
- `minReplicas: 1` means a node drain or pod eviction is a full trace outage until the replacement
  pod is ready — there's no PodDisruptionBudget. Move to `minReplicas: 2` + a PDB before relying on
  this in a non-loadtest cluster.

## Upgrading Chart

```console
helm upgrade -n monitoring monitoring-stack oci://cognigy.azurecr.io/helm/cognigy-monitoring --version HELM_CHART_VERSION --values YOUR_VALUES_FILE.yaml
```

### From 1.22.x to 1.23.x

This update includes breaking changes. Check [here](upgrade/upgrade-1.23.md) for detail instruction.

### From 1.30.x to 1.31.x

This update requires additional steps. Check [here](upgrade/upgrade-1.31.md) for detail instruction.

### From 1.31.x to 2026.1.x
Starting from this release all the images are pulled from the Cognigy container registry. Before deploying this release, create a [`docker-registry`](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/) type secret to pull the images from Cognigy container registry and name it as `cognigy-registry-token`. Provide your Cognigy container registry credentials.

```shell
kubectl create secret docker-registry cognigy-registry-token \
   --namespace=monitoring
   --docker-server=cognigy.azurecr.io \
   --docker-username=<your-username> \
   --docker-password=<your-password>
```

## Upgrading from legacy Monitoring Stack
To upgrade from our legacy Monitoring stack, check [upgrade from legacy stack](upgrade-from-legacy.md) guide.

## Uninstalling and Clean-up
To uninstall the monitoring stack execute following steps.
**IMPORTANT: all objects in monitoring namespace and Prometheus CRDs will be lost! If you have other objects in monitoring namespace created, make sure you have a corresponding backup!**

1. To remove the monitoring stack execute:
   ```shell
   helm uninstall -n monitoring monitoring-stack
   kubectl delete namespace monitoring
   kubectl delete MutatingWebhookConfiguration monitoring-stack-kubeproms-admission
   kubectl delete validatingwebhookconfigurations.admissionregistration.k8s.io monitoring-stack-kubeproms-admission
   ```
2. (Optionally): For a complete clean-up, delete kube-prometheus-stack CRDs:
   ```shell
   kubectl delete crd alertmanagerconfigs.monitoring.coreos.com
   kubectl delete crd alertmanagers.monitoring.coreos.com
   kubectl delete crd podmonitors.monitoring.coreos.com
   kubectl delete crd probes.monitoring.coreos.com
   kubectl delete crd prometheuses.monitoring.coreos.com
   kubectl delete crd prometheusrules.monitoring.coreos.com
   kubectl delete crd servicemonitors.monitoring.coreos.com
   kubectl delete crd thanosrulers.monitoring.coreos.com
   ```

