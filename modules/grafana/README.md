# Grafana Module

Deploys standalone [Grafana](https://grafana.com/oss/grafana/) with auto-provisioned datasources (Prometheus, Loki, Tempo) and dashboards via ConfigMap sidecar.

## Architecture

```
+----------------------------------------------------------------+
|  Grafana Module                                                |
|                                                                |
|  +---------------------+     +---------------------------+    |
|  |  Grafana             |     | Dashboard Sidecar         |    |
|  |  (Deployment)        |     | watches ConfigMaps with   |    |
|  |                      |     | label: grafana_dashboard=1|    |
|  |  Datasources:        |     +---------------------------+    |
|  |  +----------------+  |                                      |
|  |  | Prometheus     |<-------> prometheus:9090                |
|  |  +----------------+  |                                      |
|  |  | Loki           |<-------> loki-gateway:80                |
|  |  +----------------+  |                                      |
|  |  | Tempo          |<-------> tempo:3200                     |
|  |  +----------------+  |                                      |
|  +---------------------+     +---------------------------+    |
|                               | ConfigMaps (dashboards)  |    |
|                               |  - kubernetes-cluster    |    |
|                               |  - node-exporter         |    |
|                               |  - loki-overview         |    |
|                               |  - tempo-overview        |    |
|                               |  - otel-collector        |    |
|                               +---------------------------+    |
+----------------------------------------------------------------+
```

## Cross-Linking

All three datasources are wired for seamless navigation:

```
Loki log line ──(traceID regex)──> Tempo trace view
Tempo trace ──(tracesToLogsV2)──> Loki log search
Tempo trace ──(tracesToMetrics)──> Prometheus metrics
Tempo ──(serviceMap)──> Prometheus service graph
```

## What It Creates

- **Grafana Helm Release** with persistent storage
- **3 Auto-provisioned Datasources** with full cross-linking
- **5 Dashboard ConfigMaps** auto-loaded by the sidecar
- **Ingress** (optional, for production)

## Dashboards

Dashboards are stored as JSON files in `dashboards/` and automatically provisioned:

| File | Dashboard | Key Panels |
|------|-----------|------------|
| `kubernetes-cluster.json` | Kubernetes Cluster Overview | CPU, memory, pods, network, restarts |
| `node-exporter.json` | Node Exporter - Nodes | Per-node CPU, memory, disk, network |
| `loki-overview.json` | Loki - Logs Overview | Log volume, errors, Loki health |
| `tempo-overview.json` | Tempo - Traces Overview | Spans/sec, latency, recent traces |
| `otel-collector.json` | OpenTelemetry Collector | Pipeline throughput, CPU, memory |

To add a new dashboard, drop a `.json` file in `dashboards/` and run `terraform apply`.

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `namespace` | string | `"observability"` | Kubernetes namespace |
| `chart_version` | string | (required) | Grafana Helm chart version |
| `prometheus_url` | string | (required) | Prometheus in-cluster URL |
| `loki_url` | string | (required) | Loki in-cluster URL |
| `tempo_url` | string | (required) | Tempo in-cluster URL |
| `admin_password` | string | (required, sensitive) | Grafana admin password |
| `ingress_enabled` | bool | `false` | Enable ingress |
| `ingress_host` | string | `""` | Ingress hostname |
| `persistence_enabled` | bool | `true` | Enable PVC |
| `persistence_size` | string | `"10Gi"` | PVC size |
| `helm_values_override` | any | `""` | Additional Helm values |

## Outputs

| Name | Description |
|------|-------------|
| `grafana_service_name` | Service name |
| `grafana_url` | Full in-cluster URL |

## Usage

```hcl
module "grafana" {
  source = "../../modules/grafana"

  namespace      = "observability"
  chart_version  = "8.9.1"
  prometheus_url = module.prometheus.prometheus_internal_url
  loki_url       = module.loki.loki_internal_url
  tempo_url      = module.tempo.tempo_internal_url
  admin_password = var.grafana_admin_password
}
```
