# Observability Platform

End-to-end observability stack deployed on AWS EKS via Terraform. Collects metrics, logs, and traces with full cross-linking in Grafana. Includes SLI/SLO definitions and error budget tracking for all services.

## Architecture

```
                          +-----------+
                          |  Grafana  |
                          | (Explore) |
                          +-----+-----+
                                |
              +-----------------+-----------------+
              |                 |                 |
        +-----v-----+    +-----v-----+    +------v----+
        | Prometheus |    |   Loki    |    |   Tempo   |
        | (metrics)  |    |  (logs)   |    | (traces)  |
        +-----^-----+    +-----^-----+    +-----^-----+
              |                 |                |
              |     +-----------+-------+        |
              |     |                   |        |
              +-----+ OTel Collector   +--------+
              |     | (OTLP gateway)   |
              |     +--------^---------+
              |              |
              |         OTLP (gRPC/HTTP)
              |              |
              |     +--------+--------+
              |     | Applications    |
              |     | (sample-app,    |
              |     |  sample-app-ts) |
              |     +-----------------+
              |
        +-----+-------+     +----------+
        | ServiceMonitors|   | Promtail |---> Loki
        | PodMonitors    |   | (DaemonSet)
        +----------------+   +----------+
              ^                    |
              |              K8s pod logs
     +--------+--------+
     | Postgres Operator|
     | (Zalando)        |
     | + postgres_exporter
     +------------------+
```

## Data Flow

| Signal  | Path |
|---------|------|
| Metrics | App --> OTel Collector --> Prometheus <-- Grafana |
| Metrics | PostgreSQL --> postgres_exporter --> Prometheus <-- Grafana |
| Logs    | App --> OTel Collector --> Loki <-- Grafana |
| Logs    | K8s pods --> Promtail --> Loki <-- Grafana |
| Traces  | App --> OTel Collector --> Tempo <-- Grafana |

## Directory Structure

```
observability/
├── modules/
│   ├── eks/                # EKS cluster + VPC + OIDC + EBS CSI
│   ├── s3-bucket/          # Reusable S3 bucket (encryption, lifecycle)
│   ├── irsa/               # IAM Role for Service Accounts
│   ├── prometheus/         # kube-prometheus-stack (Grafana disabled)
│   ├── loki/               # Loki + S3 backend + IRSA + Promtail
│   ├── tempo/              # Tempo + S3 backend + IRSA
│   ├── grafana/            # Standalone Grafana + dashboards
│   ├── otel-collector/     # OTel Collector (contrib image)
│   ├── postgres-operator/  # Zalando Postgres Operator + cluster
│   └── slo/                # SLI recording rules + SLO alerting rules
├── environments/
│   ├── staging/            # Staging EKS cluster composition
│   └── production/         # Production (larger nodes, longer retention)
├── sample-app/             # Python demo app with OTel instrumentation
├── sample-app-ts/          # TypeScript demo app with OTel instrumentation
└── scripts/
    └── bootstrap-state.sh
```

## Quick Start

```bash
# 1. Deploy infrastructure
cd environments/staging
terraform init
TF_VAR_grafana_admin_password="changeme" terraform apply

# 2. Deploy sample app (builds, pushes to ECR, deploys to EKS)
cd ../../sample-app
./deploy.sh

# 3. Access Grafana
kubectl port-forward svc/grafana 3000:80 -n observability
# Open http://localhost:3000 (admin / changeme)
```

## Modules

| Module | Description | Docs |
|--------|-------------|------|
| [eks](modules/eks/) | EKS cluster with VPC, OIDC, spot nodes, EBS CSI | [README](modules/eks/README.md) |
| [s3-bucket](modules/s3-bucket/) | Encrypted S3 bucket with lifecycle rules | [README](modules/s3-bucket/README.md) |
| [irsa](modules/irsa/) | IAM Roles for K8s Service Accounts | [README](modules/irsa/README.md) |
| [prometheus](modules/prometheus/) | kube-prometheus-stack with remote write | [README](modules/prometheus/README.md) |
| [loki](modules/loki/) | Loki single-binary + Promtail + S3 | [README](modules/loki/README.md) |
| [tempo](modules/tempo/) | Tempo monolithic + S3 | [README](modules/tempo/README.md) |
| [grafana](modules/grafana/) | Grafana with auto-provisioned datasources + dashboards | [README](modules/grafana/README.md) |
| [otel-collector](modules/otel-collector/) | OTel Collector with 3 pipelines | [README](modules/otel-collector/README.md) |
| [postgres-operator](modules/postgres-operator/) | Zalando Postgres Operator + cluster + exporter | [README](modules/postgres-operator/README.md) |
| [slo](modules/slo/) | SLI/SLO recording rules + burn rate alerts | [README](modules/slo/README.md) |

## Dashboards

Seven dashboards are auto-provisioned via ConfigMap sidecar:

| Dashboard | Description |
|-----------|-------------|
| Kubernetes Cluster Overview | Cluster CPU/memory, pods by namespace, restarts |
| Node Exporter - Nodes | Per-node CPU, memory, disk, network, load |
| Loki - Logs Overview | Log volume, error/warning rates, recent errors |
| Tempo - Traces Overview | Spans/sec, query latency, recent traces |
| OpenTelemetry Collector | Accepted/refused signals, exporter stats, CPU/memory |
| SLO - Error Budget Overview | Error budgets, SLI ratios, burn rate alerts for all services |
| PostgreSQL Overview | pg_up, connections, transactions, cache hit ratio, SLIs |

## Environment Differences

| Setting | Staging | Production |
|---------|---------|------------|
| Instance types | t3/t3a/t2/m5/m5a.xlarge | t3/t3a/t2/m5/m5a.xlarge |
| Capacity type | SPOT | SPOT |
| Node count | 2 (max 4) | 2 (max 4) |
| Prometheus retention | 15d | 30d |
| Prometheus storage | 50Gi | 200Gi |
| Loki retention | 30d | 90d |
| Tempo retention | 14d | 30d |
| PostgreSQL instances | 1 (standalone) | 2 (HA with Patroni) |
| PostgreSQL storage | 5Gi | 20Gi |
| Grafana ingress | disabled | enabled |
| S3 force_destroy | true | false |
