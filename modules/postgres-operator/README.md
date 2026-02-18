# Postgres Operator Module

Deploys the [Zalando Postgres Operator](https://github.com/zalando/postgres-operator) and a minimal PostgreSQL cluster with a `postgres_exporter` sidecar for Prometheus metrics.

## Architecture

```
+--------------------------------------------------+
|  Helm Release: postgres-operator                  |
|                                                   |
|  Zalando Postgres Operator                        |
|  - Watches namespace for postgresql CRDs          |
|  - Manages Spilo (Patroni + PostgreSQL) pods      |
|  - Handles failover, backups, user management     |
+--------------------------------------------------+

+--------------------------------------------------+
|  Helm Release: postgres-cluster (local chart)     |
|                                                   |
|  postgresql CRD (acid.zalan.do/v1)                |
|  +--------------------------------------------+  |
|  | Pod: observability-obs-postgres-0           |  |
|  |                                             |  |
|  |  +------------------+  +------------------+ |  |
|  |  | Spilo (PG 16)    |  | postgres_exporter| |  |
|  |  | :5432            |  | :9187 /metrics   | |  |
|  |  +------------------+  +------------------+ |  |
|  +--------------------------------------------+  |
|                                                   |
|  PodMonitor                                       |
|  - Scrapes :9187/metrics every 15s                |
|  - Label: team=observability                      |
+--------------------------------------------------+
```

## Exposed Metrics

The `postgres_exporter` sidecar exposes standard PostgreSQL metrics:

| Metric | Type | Description |
|--------|------|-------------|
| `pg_up` | gauge | Whether PostgreSQL is reachable (1=up, 0=down) |
| `pg_stat_activity_count` | gauge | Connections by state (active, idle, etc.) |
| `pg_settings_max_connections` | gauge | Max allowed connections |
| `pg_stat_database_xact_commit` | counter | Committed transactions per database |
| `pg_stat_database_xact_rollback` | counter | Rolled-back transactions per database |
| `pg_stat_database_blks_hit` | counter | Buffer cache hits |
| `pg_stat_database_blks_read` | counter | Disk block reads |
| `pg_stat_database_tup_fetched` | counter | Rows fetched |
| `pg_stat_database_tup_inserted` | counter | Rows inserted |
| `pg_stat_database_tup_updated` | counter | Rows updated |
| `pg_stat_database_tup_deleted` | counter | Rows deleted |
| `pg_stat_database_deadlocks` | counter | Deadlocks detected |
| `pg_stat_database_conflicts` | counter | Queries canceled due to conflicts |
| `pg_database_size_bytes` | gauge | Database size in bytes |

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `namespace` | string | `"observability"` | Kubernetes namespace |
| `chart_version` | string | `"1.13.0"` | Zalando operator Helm chart version |
| `team_id` | string | `"observability"` | Team ID prefix for cluster naming |
| `cluster_name` | string | `"obs-postgres"` | Cluster name suffix |
| `pg_version` | string | `"16"` | PostgreSQL major version |
| `number_of_instances` | number | `1` | Instances (1=standalone, 2+=HA) |
| `volume_size` | string | `"5Gi"` | PVC size for data |
| `cpu_request` | string | `"100m"` | CPU request |
| `memory_request` | string | `"256Mi"` | Memory request |
| `cpu_limit` | string | `"500m"` | CPU limit |
| `memory_limit` | string | `"512Mi"` | Memory limit |
| `helm_values_override` | string | `""` | Additional Helm values (YAML) |

## Outputs

| Name | Description |
|------|-------------|
| `cluster_name` | Full PostgreSQL cluster name |
| `cluster_service` | Internal DNS endpoint for the master |
| `cluster_port` | PostgreSQL service port (5432) |

## Usage

```hcl
module "postgres_operator" {
  source = "../../modules/postgres-operator"

  namespace           = "observability"
  number_of_instances = 1
  volume_size         = "5Gi"

  depends_on = [kubernetes_namespace.observability]
}
```

## Connecting to PostgreSQL

```bash
# Get the superuser password
kubectl get secret postgres.observability-obs-postgres.credentials.postgresql.acid.zalan.do \
  -n observability -o jsonpath='{.data.password}' | base64 -d

# Port-forward
kubectl port-forward svc/observability-obs-postgres 5432:5432 -n observability

# Connect
psql -h localhost -U postgres
```

## Grafana Dashboard

The **PostgreSQL Overview** dashboard (`postgres-overview`) displays:

- **Status row** — pg_up, version, active/max connections, database size, cache hit ratio
- **Connections** — by state (stacked), utilization % with 80% threshold
- **Transactions** — commits/s vs rollbacks/s, transaction success rate SLI
- **Tuple operations** — fetched, returned, inserted, updated, deleted per second
- **Storage** — cache hit ratio over time, database size by database
- **Health** — deadlocks/s, conflicts/s
- **SLI/SLO row** — availability, connection headroom, error budget remaining
