# Sample App (TypeScript / Express)

Demonstrates full OpenTelemetry instrumentation with **traces**, **metrics**, and **logs** flowing through the observability stack. TypeScript counterpart to the Python sample-app.

## Architecture

```
+---------------------------------------------------------+
|  sample-app-ts (Express)                                |
|                                                         |
|  Endpoints          OTel Instrumentation                |
|  +--------------+   +-------------------------------+   |
|  | /healthz     |   | NodeSDK (tracing.ts)          |   |
|  | /api/products|   |   loaded via --require         |   |
|  | /api/users   |   |                               |   |
|  | /api/orders  |   | OTLPTraceExporter   (gRPC)    |   |
|  | /api/checkout|   | OTLPMetricExporter  (gRPC)    |   |
|  | /api/error   |   | OTLPLogExporter     (gRPC)    |   |
|  +--------------+   |                               |   |
|                     | HttpInstrumentation            |   |
|  Winston logger     | ExpressInstrumentation         |   |
|  (JSON to stdout,   +---------------+---------------+   |
|   picked up by                      |                   |
|   Promtail)                         |                   |
+-----------------------------------------+---------------+
                                          |
                                          v OTLP gRPC :4317
                                   +------+-------+
                                   | OTel Collector|
                                   +------+-------+
                                          |
                        +-----------------+-----------------+
                        v                 v                 v
                   Prometheus           Loki             Tempo
                   (metrics)           (logs)           (traces)
```

## Telemetry Signals

### Traces

HTTP requests are auto-instrumented by `HttpInstrumentation` and `ExpressInstrumentation`. Custom child spans simulate real-world operations:

| Endpoint | Custom Spans | Attributes |
|----------|-------------|------------|
| `/api/products` | `query-products-db` | `db.system`, `db.statement`, `db.rows_returned` |
| `/api/users` | `query-users-db` | `db.system`, `db.statement`, `db.rows_returned` |
| `/api/orders` | `validate-inventory`, `process-payment`, `send-notification` | `order.id`, `payment.amount`, `notification.type` |
| `/api/checkout` | `checkout-flow` → `validate-cart`, `apply-discounts`, `calculate-tax`, `charge-payment`, `create-shipment` | `checkout.user_tier`, `discount.percent`, `tax.rate`, `shipment.tracking` |
| `/api/error` | `failing-operation` | `error=true`, records exception |

### Metrics

| Metric | Type | Labels |
|--------|------|--------|
| `app.request.count` | Counter | `endpoint`, `method` |
| `app.request.duration` | Histogram (ms) | `endpoint` |
| `app.orders.total` | Counter | `status` |
| `app.users.active` | UpDownCounter | — |

### Logs

Structured JSON logs via **Winston** to stdout. Picked up by **Promtail** DaemonSet and shipped to Loki. Logs include contextual fields like `order_id`, `user`, `tracking`, `tier`.

## Endpoints

| Method | Path | Description | Failure Rate |
|--------|------|-------------|-------------|
| GET | `/healthz` | Health check | 0% |
| GET | `/api/products` | List products (supports `?category=` filter) | 0% |
| GET | `/api/users` | List users | 0% |
| POST | `/api/orders` | Create order (multi-step) | 0% |
| POST | `/api/checkout` | Full checkout flow with tier-based discounts | ~5% (payment decline) |
| GET | `/api/error` | Always returns 500 | 100% |

## Key Differences from Python App

| Feature | Python (sample-app) | TypeScript (sample-app-ts) |
|---------|--------------------|-----------------------------|
| Framework | Flask | Express |
| OTel setup | Inline in app.py | Separate `tracing.ts` loaded via `--require` |
| Auto-instrumentation | `FlaskInstrumentor` | `HttpInstrumentation` + `ExpressInstrumentation` |
| Logging | Python `logging` + OTel LogExporter | Winston (JSON to stdout) + Promtail |
| Extra features | — | Category filter, user tiers, tier-based discounts |

## Files

```
sample-app-ts/
├── src/
│   ├── tracing.ts          # OTel SDK init (loaded before app via --require)
│   └── app.ts              # Express app with custom spans and metrics
├── package.json            # Dependencies
├── tsconfig.json           # TypeScript config
├── Dockerfile              # Multi-stage build (node:22-slim)
├── deploy.sh               # Build, push to ECR, deploy to EKS
└── k8s/
    ├── deployment.yaml     # 2 replicas, OTLP env vars, probes
    ├── service.yaml        # ClusterIP on port 80 -> 8080
    └── loadgen-cronjob.yaml# CronJob: 20 iterations/min across all endpoints
```

## Deploy

```bash
# Full build + deploy
./deploy.sh

# Skip Docker build (just apply k8s manifests)
./deploy.sh --skip-build

# Override AWS region
./deploy.sh --region us-east-1
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `OTEL_SERVICE_NAME` | `sample-app-ts` | Service name in traces/metrics |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | `localhost:4317` | OTel Collector gRPC endpoint |
| `ENVIRONMENT` | `staging` | Deployment environment attribute |
| `PORT` | `8080` | HTTP listen port |

## Verify in Grafana

1. **Traces** (Tempo): query `{resource.service.name="sample-app-ts"}`
2. **Metrics** (Prometheus): query `app_request_count_total{service_name="sample-app-ts"}`
3. **Logs** (Loki): query `{app="sample-app-ts"}`

## Local Development

```bash
npm install
npm run dev
```
