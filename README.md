![Cognigy.AI banner](https://raw.githubusercontent.com/Cognigy/kubernetes/main/docs/assets/cognigy-ai.png)

# Cognigy Monitoring Stack Helm Chart
This chart installs Cognigy Monitoring Stack which is based on [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)

## Prerequisites
- Kubernetes cluster running one or more of [Cognigy Products](https://github.com/orgs/Cognigy/repositories) 
- A Linux machine which has the access to the K8S cluster via kubectl
- [Helm](https://helm.sh/) v.3.8.0+


## Installation
1. To deploy a Helm Release for Monitoring Stack you need to create a separate file with Helm release values. You can use `values_prod.yaml` as a baseline, we recommend to start with it. Make a copy of `values_prod.yaml` into a new file and name it accordingly, we refer to it as `YOUR_VALUES_FILE.yaml` later in this document.
2. Set the essential parameters in `YOUR_VALUES_FILE.yaml`, see the comments inside the file.
3. Install Monitoring Stack Helm Release:
* Installing from Cognigy Container Registry (recommended), specify proper `HELM_CHART_VERSION` (check [CHANGELOG](CHANGELOG.md) for details) and `YOUR_VALUES_FILE.yaml`:
   * Login into Cognigy helm registry (provide your Cognigy Container Registry credentials):
   ```shell
   helm registry login cognigy.azurecr.io \
   --username <your-username> \
   --password <your-password>
   ```
   * Install Helm Chart into a separate `cognigy-ai` namespace:
   ```shell
   helm upgrade --install --create-namespace -n monitoring monitoring-stack oci://cognigy.azurecr.io/helm/cognigy-monitoring --version HELM_CHART_VERSION --values YOUR_VALUES_FILE.yaml
   ```
* Alternatively you can install it from the local chart (not recommended):
   ```shell
   helm upgrade --install --create-namespace -n monitoring monitoring-stack ./cognigy-monitoring --values YOUR_VALUES_FILE.yaml 
   ```
4. If Grafana ingress is disabled you can access the grafana directly by using kubectl port-forwarding: `kubectl port-forward svc/monitoring-stack-grafana 3000:80`. Then access Grafana via `http://localhost:3000`. Use Grafana credentials you have set in `YOUR_VALUES_FILE.yaml`
5. If Grafana ingress is enabled, add Grafana hostname to DNS and access Grafana via browser.

### Install Redis and MongoDB exporters

1. Install Redis exporters for Redis and Redis-Persistent deployments, replace `COGNIGY_AI_NAMESPACE` with the namespace in which Cognigy.AI product is installed: 
```shell
# redis
helm upgrade --install prom-exporter-redis ./misc/charts/prometheus-redis-exporter \
  -n [COGNIGY_AI_NAMESPACE] \
  -f redis-values.yaml

# redis-persistent
helm upgrade --install prom-exporter-redis-persistent ./misc/charts/prometheus-redis-exporter \
  -n [COGNIGY_AI_NAMESPACE] \
  -f redis-persistent-values.yaml
```
2. (Legacy single-pod MongoDB Installation only): If you do not have our [MongoDB Helm Chart](https://github.com/Cognigy/cognigy-mongodb-helm-chart/tree/master/charts/bitnami/mongodb) installed, or you still use deprecated [kustomize](https://github.com/Cognigy/kubernetes) installation, install MongoDB Helm Chart:
```shell
helm upgrade --install prom-exporter-mongodb ./misc/charts/prometheus-mongodb-exporter \
  -n ${COGNIGY_AI_NAMESPACE} \
  -f ./mongodb-values.yaml
```
3. To enable Prometheus exporter for [MongoDB Helm Chart](https://github.com/Cognigy/cognigy-mongodb-helm-chart/tree/master/charts/bitnami/mongodb) set `serviceMonitor.enabled: true` in `values.yaml` of
MongoDB Helm Chart. 


### Upgrade from legacy Monitoring Stack
To upgrade from our legacy Monitoring stack you need to completely remove previous installation by removing monitoring namespace and cleaning up the Prometheus CRDs. **Important: If you have other objects in monitoring namespace created, make sure you have a corresponding backup!**

1. Uninstall Redis-persistent, Redis and MongoDB exporters (if any), replace `COGNIGY_AI_NAMESPACE` with the namespace in which Cognigy.AI product is installed:
```shell
helm uninstall -n [COGNIGY_AI_NAMESPACE] prom-cognigy-redis-persistent
helm uninstall -n [COGNIGY_AI_NAMESPACE] prom-cognigy-redis
helm uninstall -n [COGNIGY_AI_NAMESPACE] prom-exporter-mongodb
```
2. (Flux controller environments only): If you use Flux to deploy Cognigy products you need to suspend Flux `HelmReleases` for MOngoDB, Cognigy.AI and/or Live Agent during the upgrade process to avoid reconciliation errors.
3. Uninstall legacy stack and clean up the CRDs:
```shell
## Uninstall Helm Charts for legacy prometheus stack
helm uninstall -n=monitoring prom-cadvisor
helm uninstall -n=monitoring prom
helm uninstall -n=monitoring prom-cognigy-dash
helm uninstall -n=monitoring prom-cognigy-monitor
kubectl delete namespace monitoring
## Remove cadvisor metrics service (if still present):  
kubectl delete -n=kube-system service prom-kube-prometheus-stack-kubelet 
## Check the name of MutatingWebhookConfiguration for the old prometheus stack 
kubectl get -A MutatingWebhookConfiguration
## Remove the related MutatingWebhookConfiguration e.g prom-kube-prometheus-stack-admission or monitoring-stack-kubeproms-admission
kubectl delete MutatingWebhookConfiguration prom-kube-prometheus-stack-admission
## Check the name of Validatingwebhookconfiguration for the old prometheus stack 
kubectl get -A ValidatingWebhookConfiguration
## Remove the related ValidatingWebhookConfiguration e.g prom-kube-prometheus-stack-admission or monitoring-stack-kubeproms-admission
kubectl delete validatingwebhookconfigurations.admissionregistration.k8s.io prom-kube-prometheus-stack-admission
## Remove other kube-prometheus-stack CRDs
kubectl delete crd alertmanagerconfigs.monitoring.coreos.com
kubectl delete crd alertmanagers.monitoring.coreos.com
kubectl delete crd podmonitors.monitoring.coreos.com
kubectl delete crd probes.monitoring.coreos.com
kubectl delete crd prometheuses.monitoring.coreos.com
kubectl delete crd prometheusrules.monitoring.coreos.com
kubectl delete crd servicemonitors.monitoring.coreos.com
kubectl delete crd thanosrulers.monitoring.coreos.com
```
4. Proceed with the [Installation](#Installation) section for installing the new monitoring stack 
5. (Flux controller environments only): Resume suspended `HelmReleases` for MongoDB, Cognigy.AI and/or Live Agent. Also, skip the next step as Flux will recreate PodMonitors automatically during `resume` operation. 
6. Since `PodMonitors` and `ServiceMonitors` Prometheus CRDs as well as `monitoring` namespace were deleted during clean-up of the legacy monitoring stack, you need to recreate `PodMonitors` for Cognigy.AI and/or Live Agent services. Trigger MongoDB, Cognigy.AI and/or Live Agent Helm releases updates by updating respective `values.yaml` files or reapply 
[pod-monitors](https://github.com/Cognigy/kubernetes/tree/main/core/manifests/pod-monitors) manifests for legacy Kustomize installation. Check that `PodMonitors` and/or `ServiceMonitors` are created in respective namespaces.
 
## Uninstalling and Clean-up
To uninstall the monitoring stack execute following steps.
**IMPORTANT: all objects in monitoring namespace and Prometheus CRDs will be lost! If you have other objects in monitoring namespace created, make sure you have a corresponding backup!**

1. Uninstall Redis-persistent, Redis and MongoDB exporters (if any), replace `COGNIGY_AI_NAMESPACE` with the namespace in which Cognigy.AI product is installed:
```shell
helm uninstall -n [COGNIGY_AI_NAMESPACE] prom-cognigy-redis-persistent
helm uninstall -n [COGNIGY_AI_NAMESPACE] prom-cognigy-redis
helm uninstall -n [COGNIGY_AI_NAMESPACE] prom-exporter-mongodb
```

2. To remove the monitoring stack execute:
```shell
helm uninstall -n monitoring monitoring-stack
kubectl delete namespace monitoring
kubectl delete MutatingWebhookConfiguration monitoring-stack-kubeproms-admission
kubectl delete validatingwebhookconfigurations.admissionregistration.k8s.io monitoring-stack-kubeproms-admission
```
3. (Optionally): For a Clean-up, delete kube-prometheus-stack CRDs: 
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

