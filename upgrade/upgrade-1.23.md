## From 1.22.x to 1.23.x

1. This version upgrades Prometheus-Operator to v0.74.0. Run these commands to update the CRDs before applying the upgrade.

   ```console
   kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.74.0/example/prometheus-operator-crd/monitoring.coreos.com_alertmanagerconfigs.yaml
   kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.74.0/example/prometheus-operator-crd/monitoring.coreos.com_alertmanagers.yaml
   kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.74.0/example/prometheus-operator-crd/monitoring.coreos.com_podmonitors.yaml
   kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.74.0/example/prometheus-operator-crd/monitoring.coreos.com_probes.yaml
   kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.74.0/example/prometheus-operator-crd/monitoring.coreos.com_prometheusagents.yaml
   kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.74.0/example/prometheus-operator-crd/monitoring.coreos.com_prometheuses.yaml
   kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.74.0/example/prometheus-operator-crd/monitoring.coreos.com_prometheusrules.yaml
   kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.74.0/example/prometheus-operator-crd/monitoring.coreos.com_scrapeconfigs.yaml
   kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.74.0/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml
   kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.74.0/example/prometheus-operator-crd/monitoring.coreos.com_thanosrulers.yaml
   ```

2. The dependency chart `kube-prometheus-stack` allows defining image registry at the global level using `global.imageRegistry` or per container image. For all images, registry and repository are split into two variables `image.registry` and `image.repository`. The defaults have not changed but if you were using a custom image, you will have to override the registry of said custom container image before you upgrade.

   For instance, the prometheus-config-reloader used to be configured as follows:

   ```yaml
   kubepromstack:
     prometheusOperator:
       prometheusConfigReloader:
         image:
           repository: quay.io/prometheus-operator/prometheus-config-reloader
           tag: v0.60.1
           sha: ""
   ```

   But it now moved to:

   ```yaml
   kubepromstack:
     prometheusOperator:
       prometheusConfigReloader:
         image:
           registry: quay.io
           repository: prometheus-operator/prometheus-config-reloader
           tag: v0.60.1
           sha: ""
   ```

3. The dependency chart `kube-prometheus-stack` introduces the ability to choose between usage of existing secrets or creation of new secret objects for Thanos configuration. If you were setting:

    - `kubepromstack.thanosRuler.thanosRulerSpec.alertmanagersConfig` or
    - `kubepromstack.thanosRuler.thanosRulerSpec.objectStorageConfig` or
    - `kubepromstack.thanosRuler.thanosRulerSpec.queryConfig` or
    - `kubepromstack.prometheus.prometheusSpec.thanos.objectStorageConfig`

    You will have to set `existingSecret` or `secret` based on your requirements.

    For instance, the `kubepromstack.prometheus.prometheusSpec.thanos.objectStorageConfig` used to be configured as follows:

    ```yaml
    kubepromstack:
      prometheus:
        prometheusSpec:
          thanos:
            objectStorageConfig:
              name: thanos-objstore-config
              key: thanos.yaml
    ```

    This configuration has now changed to:

    ```yaml
    kubepromstack:
      prometheus:
        prometheusSpec:
          thanos:
            objectStorageConfig:
              existingSecret:
                name: thanos-objstore-config
                key: thanos.yaml
    ```


For further detail check the [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/blob/kube-prometheus-stack-59.1.0/charts/kube-prometheus-stack/README.md) documentation.
