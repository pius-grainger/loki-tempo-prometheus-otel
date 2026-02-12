# Prometheus Module

Deploys [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) with the Grafana sub-chart disabled (we use a standalone Grafana module instead).

## Architecture

```
+------------------------------------------------+
|  kube-prometheus-stack                         |
|                                                |
|  +------------------+  +------------------+   |
|  |   Prometheus     |  |  Alertmanager    |   |
|  |  (StatefulSet)   |  |  (StatefulSet)   |   |
|  |                  |  +------------------+   |
|  |  - Scrapes all   |                         |
|  |    ServiceMonitors|  +------------------+  |
|  |  - Remote write  |  | kube-state-      |  |
|  |    receiver ON   |  | metrics          |  |
|  +--------^---------+  +------------------+  |
|           |                                    |
|           |             +------------------+   |
|    ServiceMonitors      | node-exporter    |   |
|    (auto-discover)      | (DaemonSet)      |   |
|                         +------------------+   |
+------------------------------------------------+
         ^
         |  remote write
         |
  +------+--------+
  | OTel Collector |
  +----------------+
```

## Key Configuration

- **Grafana sub-chart disabled** (managed separately)
- **`remoteWriteReceiver: true`** so OTel Collector can push metrics
- **`serviceMonitorSelectorNilUsesHelmValues: false`** to auto-scrape all ServiceMonitors
- **Alertmanager** included (toggleable)
- **node-exporter** DaemonSet for host-level metrics
- **kube-state-metrics** for Kubernetes object metrics

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `namespace` | string | `"observability"` | Kubernetes namespace |
| `chart_version` | string | (required) | kube-prometheus-stack chart version |
| `prometheus_retention` | string | `"15d"` | Data retention period |
| `prometheus_storage_size` | string | `"50Gi"` | PVC size for Prometheus TSDB |
| `alertmanager_enabled` | bool | `true` | Deploy Alertmanager |
| `helm_values_override` | any | `""` | Additional Helm values (YAML) |

## Outputs

| Name | Description |
|------|-------------|
| `prometheus_service_name` | Service name (`prometheus-kube-prometheus-prometheus`) |
| `prometheus_service_port` | Port (`9090`) |
| `prometheus_internal_url` | Full in-cluster URL |

## Usage

```hcl
module "prometheus" {
  source = "../../modules/prometheus"

  namespace              = "observability"
  chart_version          = "81.6.1"
  prometheus_retention    = "30d"
  prometheus_storage_size = "200Gi"
  alertmanager_enabled   = true
}
```
