# Loki Module

Deploys [Grafana Loki](https://grafana.com/oss/loki/) in single-binary mode with S3 backend storage, IRSA for AWS authentication, and Promtail for Kubernetes log collection.

## Architecture

```
+---------------------------------------------------------------+
|  Loki Module                                                  |
|                                                               |
|  +------------------+        +------------------+             |
|  |    Promtail      | -----> |   Loki Gateway   |             |
|  |   (DaemonSet)    | push   |    (nginx)       |             |
|  |                  |        +--------+---------+             |
|  | Reads pod logs   |                 |                       |
|  | from /var/log/   |        +--------v---------+             |
|  +------------------+        |  Loki Single     |             |
|                              |  Binary          |             |
|  +------------------+        |  (StatefulSet)   |             |
|  | OTel Collector   | -----> |                  |             |
|  | (app logs)       | push   +--------+---------+             |
|  +------------------+                 |                       |
|                                       | IRSA                  |
|                              +--------v---------+             |
|                              |   S3 Bucket      |             |
|                              |   (chunks+index) |             |
|                              +------------------+             |
|                                                               |
|  Internal modules used:                                       |
|  +-------------+  +-------------+                             |
|  | s3-bucket   |  | irsa        |                             |
|  +-------------+  +-------------+                             |
+---------------------------------------------------------------+
```

## Data Flow

```
K8s Pod Logs ──> Promtail (DaemonSet) ──> Loki Gateway ──> Loki ──> S3
App Logs ──> OTel Collector ──> Loki Gateway ──> Loki ──> S3
Grafana ──> Loki Gateway ──> Loki ──> S3 (query)
```

## What It Creates

- **S3 Bucket** (via `s3-bucket` module) for chunks and index storage
- **IRSA Role** (via `irsa` module) for pod-level S3 access
- **Loki Helm Release** in single-binary mode (1 replica)
- **Loki Gateway** (nginx reverse proxy)
- **Promtail Helm Release** (DaemonSet) that collects all pod logs
- **ServiceMonitor** so Prometheus scrapes Loki's internal metrics

## Key Configuration

- **Single-binary mode**: all components in one pod (simple, migrates to scalable later)
- **TSDB store** with v13 schema, 24h index period
- **Minio disabled**: uses real S3 via IRSA
- **Promtail**: enabled by default, ships logs to Loki gateway

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `namespace` | string | `"observability"` | Kubernetes namespace |
| `chart_version` | string | (required) | Loki Helm chart version |
| `s3_bucket_name` | string | (required) | S3 bucket name for chunks |
| `aws_region` | string | (required) | AWS region |
| `oidc_provider_arn` | string | (required) | EKS OIDC provider ARN |
| `oidc_provider_url` | string | (required) | EKS OIDC provider URL |
| `environment` | string | (required) | Environment name |
| `retention_days` | number | `30` | S3 lifecycle expiration |
| `service_account_name` | string | `"loki"` | K8s service account name |
| `promtail_enabled` | bool | `true` | Deploy Promtail DaemonSet |
| `promtail_chart_version` | string | `"6.16.6"` | Promtail chart version |
| `helm_values_override` | any | `""` | Additional Helm values |

## Outputs

| Name | Description |
|------|-------------|
| `loki_service_name` | Gateway service name |
| `loki_internal_url` | Full in-cluster URL (via gateway) |
| `loki_write_url` | Push API endpoint for log ingestion |
| `s3_bucket_name` | S3 bucket name |
| `irsa_role_arn` | IAM role ARN |

## Usage

```hcl
module "loki" {
  source = "../../modules/loki"

  namespace         = "observability"
  chart_version     = "6.52.0"
  s3_bucket_name    = "myorg-staging-loki-chunks"
  aws_region        = "eu-west-2"
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
  environment       = "staging"
  retention_days    = 30
}
```
