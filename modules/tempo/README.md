# Tempo Module

Deploys [Grafana Tempo](https://grafana.com/oss/tempo/) in monolithic mode with S3 backend storage and IRSA for AWS authentication.

## Architecture

```
+---------------------------------------------------------------+
|  Tempo Module                                                 |
|                                                               |
|  +------------------+        +------------------+             |
|  | OTel Collector   | OTLP   |    Tempo         |             |
|  | (traces)         | -----> | (StatefulSet)    |             |
|  +------------------+ :4317  |                  |             |
|                              | - Distributor    |             |
|  +------------------+        | - Ingester       |             |
|  | Grafana          | :3200  | - Querier        |             |
|  | (query traces)   | -----> | - Compactor      |             |
|  +------------------+        +--------+---------+             |
|                                       |                       |
|                                       | IRSA                  |
|                              +--------v---------+             |
|                              |   S3 Bucket      |             |
|                              |   (trace blocks) |             |
|                              +------------------+             |
|                                                               |
|                              +------------------+             |
|                              | Metrics Generator| ----+       |
|                              | (span metrics)   |     |       |
|                              +------------------+     |       |
|                                                       v       |
|                                                 Prometheus    |
|                                              (remote write)   |
|                                                               |
|  Internal modules used:                                       |
|  +-------------+  +-------------+                             |
|  | s3-bucket   |  | irsa        |                             |
|  +-------------+  +-------------+                             |
+---------------------------------------------------------------+
```

## Data Flow

```
App ──> OTel Collector ──OTLP──> Tempo ──> S3 (storage)
Grafana ──HTTP :3200──> Tempo ──> S3 (query)
Tempo Metrics Generator ──remote write──> Prometheus (span metrics)
```

## What It Creates

- **S3 Bucket** (via `s3-bucket` module) for trace block storage
- **IRSA Role** (via `irsa` module) for pod-level S3 access
- **Tempo Helm Release** in monolithic mode (1 replica)
- **ServiceMonitor** so Prometheus scrapes Tempo's internal metrics
- **Metrics Generator** that derives RED metrics from traces and pushes to Prometheus

## Key Configuration

- **Monolithic mode**: all components in one pod
- **OTLP receivers**: gRPC on `:4317`, HTTP on `:4318`
- **HTTP API**: `:3200` (used by Grafana datasource)
- **Metrics generator**: creates `traces_spanmetrics_*` in Prometheus

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `namespace` | string | `"observability"` | Kubernetes namespace |
| `chart_version` | string | (required) | Tempo Helm chart version |
| `s3_bucket_name` | string | (required) | S3 bucket for trace blocks |
| `aws_region` | string | (required) | AWS region |
| `oidc_provider_arn` | string | (required) | EKS OIDC provider ARN |
| `oidc_provider_url` | string | (required) | EKS OIDC provider URL |
| `environment` | string | (required) | Environment name |
| `retention_days` | number | `14` | S3 lifecycle expiration |
| `trace_retention` | string | `"168h"` | Tempo trace retention |
| `prometheus_remote_write_url` | string | `""` | Prometheus remote write URL |
| `helm_values_override` | any | `""` | Additional Helm values |

## Outputs

| Name | Description |
|------|-------------|
| `tempo_service_name` | Service name |
| `tempo_internal_url` | Full in-cluster URL (`:3200`) |
| `tempo_otlp_grpc_endpoint` | OTLP gRPC endpoint (`:4317`) |
| `s3_bucket_name` | S3 bucket name |
| `irsa_role_arn` | IAM role ARN |

## Usage

```hcl
module "tempo" {
  source = "../../modules/tempo"

  namespace                   = "observability"
  chart_version               = "1.24.4"
  s3_bucket_name              = "myorg-staging-tempo-traces"
  aws_region                  = "eu-west-2"
  oidc_provider_arn           = module.eks.oidc_provider_arn
  oidc_provider_url           = module.eks.oidc_provider_url
  environment                 = "staging"
  retention_days              = 14
  prometheus_remote_write_url = "${module.prometheus.prometheus_internal_url}/api/v1/write"
}
```
