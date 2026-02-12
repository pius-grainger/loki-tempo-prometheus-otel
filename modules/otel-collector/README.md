# OpenTelemetry Collector Module

Deploys the [OpenTelemetry Collector](https://opentelemetry.io/docs/collector/) using the **contrib** image. Acts as a central gateway that receives OTLP telemetry from applications and fans it out to Prometheus, Loki, and Tempo.

## Architecture

```
+--------------------------------------------------------------+
|  OTel Collector (contrib image)                              |
|                                                              |
|  Receivers          Processors          Exporters            |
|  +--------+        +-----------+       +----------------+   |
|  |  OTLP  | -----> | memory    | ----> | otlp/tempo     |---+---> Tempo
|  | :4317  |  traces| limiter   |       +----------------+   |
|  | :4318  |        |           |       +----------------+   |
|  +--------+ -----> | batch     | ----> | prometheus     |---+---> Prometheus
|              metrics|           |       | remotewrite    |   |
|             ------> |           | ----> +----------------+   |
|              logs   | resource  |       +----------------+   |
|                     | (cluster  |  ---> | loki           |---+---> Loki
|                     |  name)    |       +----------------+   |
|                     +-----------+                            |
|                                                              |
|  ServiceMonitor (metrics on :8888) ─────────> Prometheus     |
+--------------------------------------------------------------+
```

## Pipeline Detail

```
┌─────────────────────────────────────────────────┐
│                  PIPELINES                       │
├──────────┬───────────────┬──────────────────────┤
│ Signal   │ Processors    │ Exporter             │
├──────────┼───────────────┼──────────────────────┤
│ traces   │ memory_limiter│ otlp/tempo (:4317)   │
│          │ batch         │                      │
├──────────┼───────────────┼──────────────────────┤
│ metrics  │ memory_limiter│ prometheusremotewrite │
│          │ batch         │ (/api/v1/write)      │
├──────────┼───────────────┼──────────────────────┤
│ logs     │ memory_limiter│ loki                 │
│          │ batch         │ (/loki/api/v1/push)  │
└──────────┴───────────────┴──────────────────────┘
```

## What It Creates

- **Helm Release** using `opentelemetry-collector` chart with contrib image
- **OTLP Receivers** on gRPC (`:4317`) and HTTP (`:4318`)
- **3 Export Pipelines** (traces, metrics, logs)
- **ServiceMonitor** on `:8888` for self-monitoring
- **Resource processor** that stamps `k8s.cluster.name` on all telemetry

## Why Contrib Image?

The default OTel Collector image does not include `loki` or `prometheusremotewrite` exporters. The **contrib** image (`otel/opentelemetry-collector-contrib`) includes all community exporters.

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `namespace` | string | `"observability"` | Kubernetes namespace |
| `chart_version` | string | (required) | OTel Collector chart version |
| `mode` | string | `"deployment"` | `deployment` or `daemonset` |
| `prometheus_remote_write_url` | string | (required) | Prometheus remote write URL |
| `loki_push_url` | string | (required) | Loki push API URL |
| `tempo_otlp_grpc_endpoint` | string | (required) | Tempo OTLP gRPC endpoint |
| `cluster_name` | string | `""` | Cluster name for resource attribute |
| `helm_values_override` | any | `""` | Additional Helm values |

## Outputs

| Name | Description |
|------|-------------|
| `otlp_grpc_endpoint` | OTLP gRPC endpoint for applications |
| `otlp_http_endpoint` | OTLP HTTP endpoint for applications |

## Usage

```hcl
module "otel_collector" {
  source = "../../modules/otel-collector"

  namespace                   = "observability"
  chart_version               = "0.108.0"
  mode                        = "deployment"
  prometheus_remote_write_url = "${module.prometheus.prometheus_internal_url}/api/v1/write"
  loki_push_url               = module.loki.loki_write_url
  tempo_otlp_grpc_endpoint    = module.tempo.tempo_otlp_grpc_endpoint
  cluster_name                = module.eks.cluster_name
}
```

## Instrumenting Applications

Point your app's OTLP exporter at the collector:

```bash
# Environment variables
OTEL_EXPORTER_OTLP_ENDPOINT=otel-collector-opentelemetry-collector.observability.svc.cluster.local:4317
```
