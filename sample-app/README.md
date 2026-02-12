# Sample App (Python / Flask)

Demonstrates full OpenTelemetry instrumentation with **traces**, **metrics**, and **logs** flowing through the observability stack.

## Architecture

```
+---------------------------------------------------------+
|  sample-app (Flask)                                     |
|                                                         |
|  Endpoints          OTel Instrumentation                |
|  +--------------+   +-------------------------------+   |
|  | /healthz     |   | TracerProvider                |   |
|  | /api/products|   |   -> BatchSpanProcessor       |   |
|  | /api/users   |   |   -> OTLPSpanExporter (gRPC)  |   |
|  | /api/orders  |   |                               |   |
|  | /api/checkout|   | MeterProvider                 |   |
|  | /api/error   |   |   -> OTLPMetricExporter       |   |
|  +--------------+   |                               |   |
|                     | LoggerProvider                |   |
|  FlaskInstrumentor  |   -> OTLPLogExporter          |   |
|  (auto-instruments  +---------------+---------------+   |
|   all HTTP spans)                   |                   |
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

Every HTTP request is auto-instrumented by `FlaskInstrumentor`. Custom child spans simulate real-world operations:

| Endpoint | Custom Spans | Attributes |
|----------|-------------|------------|
| `/api/products` | `fetch-products-from-db` | `db.system`, `db.statement`, `db.rows_returned` |
| `/api/users` | `fetch-users-from-db` | `db.system`, `db.statement` |
| `/api/orders` | `validate-inventory`, `process-payment`, `send-confirmation` | `order.id`, `payment.amount`, `notification.type` |
| `/api/checkout` | `checkout-flow` → `validate-cart`, `apply-discounts`, `calculate-tax`, `charge-payment`, `create-shipment` | `checkout.total`, `discount.percent`, `tax.rate`, `shipment.tracking` |
| `/api/error` | `failing-operation` | `error=true`, records exception |

### Metrics

| Metric | Type | Labels |
|--------|------|--------|
| `app.request.count` | Counter | `endpoint`, `method` |
| `app.request.duration` | Histogram (ms) | `endpoint` |
| `app.orders.total` | Counter | `status` |
| `app.users.active` | UpDownCounter | — |

### Logs

Structured JSON logs via Python `logging` module, exported to Loki through the OTel log pipeline. Logs include `order_id`, `user`, `amount`, and other contextual fields.

## Endpoints

| Method | Path | Description | Failure Rate |
|--------|------|-------------|-------------|
| GET | `/healthz` | Health check | 0% |
| GET | `/api/products` | List products | 0% |
| GET | `/api/users` | List users | 0% |
| POST | `/api/orders` | Create order (multi-step) | 0% |
| POST | `/api/checkout` | Full checkout flow | ~5% (payment decline) |
| GET | `/api/error` | Always returns 500 | 100% |

## Files

```
sample-app/
├── app.py                  # Flask app with OTel instrumentation
├── requirements.txt        # Python dependencies
├── Dockerfile              # Python 3.12-slim image
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
| `OTEL_SERVICE_NAME` | `sample-app` | Service name in traces/metrics |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | `localhost:4317` | OTel Collector gRPC endpoint |
| `ENVIRONMENT` | `staging` | Deployment environment attribute |
| `PORT` | `8080` | HTTP listen port |

## Verify in Grafana

1. **Traces** (Tempo): query `{resource.service.name="sample-app"}`
2. **Metrics** (Prometheus): query `app_request_count_total{service_name="sample-app"}`
3. **Logs** (Loki): query `{app="sample-app"}`
