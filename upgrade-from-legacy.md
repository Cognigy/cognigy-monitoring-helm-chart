# Upgrade from legacy Monitoring Stack
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
