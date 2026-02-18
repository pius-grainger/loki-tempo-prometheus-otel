# SLO Module

Deploys Prometheus recording rules and alerting rules that define **SLIs**, **SLOs**, and **Error Budgets** for all services in the observability stack. Rules are split into separate files for application/infrastructure services and PostgreSQL.

## Architecture

```
+---------------------------------------------------------------+
|  Helm Release: slo-rules (local chart)                        |
|                                                               |
|  PrometheusRule: sli-recording-rules                          |
|    App + Infra SLI ratios and error budgets                   |
|                                                               |
|  PrometheusRule: slo-alerting-rules                           |
|    App + Infra burn rate alerts                               |
|                                                               |
|  PrometheusRule: postgres-recording-rules                     |
|    PostgreSQL SLI ratios and error budgets                    |
|                                                               |
|  PrometheusRule: postgres-alerting-rules                      |
|    PostgreSQL burn rate alerts                                |
+---------------------------------------------------------------+

Raw Metrics ──> Recording Rules ──> SLI Ratios ──> Error Budgets
                                                        |
                                              Alerting Rules
                                          (multi-window burn rate)
```

## SLO Definitions

### Application Services

| Service | SLI | SLO Target | Error Budget (30d) | Measurement |
|---------|-----|------------|-------------------|-------------|
| sample-app | Availability | 99.9% | 43.2 min | Non-5xx / Total HTTP requests |
| sample-app-ts | Availability | 99.9% | 43.2 min | Non-5xx / Total HTTP requests |

### Infrastructure Services

| Service | SLI | SLO Target | Error Budget (30d) | Measurement |
|---------|-----|------------|-------------------|-------------|
| OTel Collector | Trace pipeline | 99.9% | 43.2 min | Exported spans / Received spans |
| OTel Collector | Metric pipeline | 99.9% | 43.2 min | Exported points / Received points |
| OTel Collector | Log pipeline | 99.5% | 3.6 hr | Exported records / Received records |
| Loki | Ingestion | 99.5% | 3.6 hr | Non-5xx push requests / Total push requests |
| Tempo | Ingestion | 99.5% | 3.6 hr | Non-5xx push requests / Total push requests |

### PostgreSQL

| Service | SLI | SLO Target | Error Budget (30d) | Measurement |
|---------|-----|------------|-------------------|-------------|
| PostgreSQL | Availability | 99.9% | 43.2 min | avg_over_time(pg_up) |
| PostgreSQL | Transaction success | 99.9% | 43.2 min | Commits / (Commits + Rollbacks) |
| PostgreSQL | Connection headroom | 99.5% | 3.6 hr | 1 - (active / max_connections) |

## Recording Rules

### SLI Ratios (calculated at 30s intervals)

| Metric | Windows | Description |
|--------|---------|-------------|
| `sli:app_availability:ratio_rate{5m,30m,1h}` | 5m, 30m, 1h | Success ratio for HTTP requests per app |
| `sli:otel_traces_success:ratio_rate{5m,1h}` | 5m, 1h | Trace pipeline success ratio |
| `sli:otel_metrics_success:ratio_rate{5m,1h}` | 5m, 1h | Metric pipeline success ratio |
| `sli:otel_logs_success:ratio_rate{5m,1h}` | 5m, 1h | Log pipeline success ratio |
| `sli:loki_write_success:ratio_rate{5m,1h}` | 5m, 1h | Loki ingestion success ratio |
| `sli:tempo_write_success:ratio_rate{5m,1h}` | 5m, 1h | Tempo ingestion success ratio |
| `sli:postgres_availability:ratio_rate{5m,30m,1h}` | 5m, 30m, 1h | PostgreSQL reachability (pg_up) |
| `sli:postgres_txn_success:ratio_rate{5m,1h}` | 5m, 1h | Transaction success ratio |
| `sli:postgres_connection_headroom:ratio_rate{5m,1h}` | 5m, 1h | Connection headroom ratio |

### Error Budget (calculated at 1m intervals)

| Metric | Description |
|--------|-------------|
| `slo:error_budget_remaining:ratio` | Remaining error budget as a ratio (1.0 = full, 0 = exhausted, negative = over-budget) |

## Alerting Rules (Multi-Window Burn Rate)

| Alert | Severity | Condition | Meaning |
|-------|----------|-----------|---------|
| `SLOHighErrorBurnRate` | critical | 5m AND 1h both < 98.56% | 14.4x burn rate; budget exhausted in < 2 days |
| `SLOModerateErrorBurnRate` | warning | 30m AND 1h both < 99.8% | 2x burn rate; budget exhausted in ~10 days |
| `SLOErrorBudgetExhausted` | critical | budget <= 0 for 5m | 100% of error budget consumed |
| `SLOErrorBudgetLow` | warning | 0 < budget < 20% for 15m | > 80% of error budget consumed |

App/infra and PostgreSQL alerts are in separate PrometheusRule resources but use the same alert names and thresholds.

## Grafana Dashboards

The **SLO - Error Budget Overview** dashboard (`slo-overview`) displays:

- **SLO Summary Table** -- all services with current error budget remaining (color-coded)
- **Error Budget Over Time** -- trend line showing budget consumption
- **Per-Service SLI Panels** -- 5m and 1h availability ratios with SLO threshold lines
- **PostgreSQL SLI Panels** -- availability and transaction success SLIs
- **Active SLO Alerts** -- firing alerts table

The **PostgreSQL Overview** dashboard (`postgres-overview`) provides detailed PostgreSQL metrics (deployed via the grafana module).

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `namespace` | string | `"observability"` | Kubernetes namespace |

## Usage

```hcl
module "slo" {
  source = "../../modules/slo"

  namespace = "observability"

  depends_on = [module.prometheus]
}
```

## Why Multi-Window Burn Rate?

Single-threshold alerts are either too noisy (short window) or too slow (long window). The multi-window approach from Google's SRE book uses two windows simultaneously:

```
Fast window (5m)  AND  Slow window (1h)  = Alert fires
  catches spikes         confirms trend      only if real
```

This reduces false positives while still catching real incidents quickly.

## Why Separate App and Postgres Rules?

PostgreSQL SLIs use different metrics (pg_up, pg_stat_database_*) and job selectors (`job=~".*postgres-exporter"`) than application services. Splitting into separate PrometheusRule resources keeps each file focused and avoids complex multi-service selector logic in alert expressions.
