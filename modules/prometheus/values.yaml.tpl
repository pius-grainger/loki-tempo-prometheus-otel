# Disable bundled Grafana — deployed as a separate module
grafana:
  enabled: false

prometheus:
  prometheusSpec:
    retention: ${prometheus_retention}

    storageSpec:
      volumeClaimTemplate:
        spec:
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: ${prometheus_storage_size}

    # Accept remote-write from OpenTelemetry Collector
    enableRemoteWriteReceiver: true

    # Discover all ServiceMonitors/PodMonitors/Rules across the cluster
    serviceMonitorSelectorNilUsesHelmValues: false
    podMonitorSelectorNilUsesHelmValues: false
    ruleSelectorNilUsesHelmValues: false

alertmanager:
  enabled: ${alertmanager_enabled}
