import logging
import os
import random
import time

from flask import Flask, jsonify, request
from opentelemetry import trace, metrics
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.exporter.otlp.proto.grpc.metric_exporter import OTLPMetricExporter
from opentelemetry.exporter.otlp.proto.grpc._log_exporter import OTLPLogExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.metrics.export import PeriodicExportingMetricReader
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk._logs import LoggerProvider, LoggingHandler
from opentelemetry.sdk._logs.export import BatchLogRecordProcessor
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.semconv.resource import ResourceAttributes

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
SERVICE_NAME = os.getenv("OTEL_SERVICE_NAME", "sample-app")
OTEL_ENDPOINT = os.getenv("OTEL_EXPORTER_OTLP_ENDPOINT", "localhost:4317")

resource = Resource.create({
    ResourceAttributes.SERVICE_NAME: SERVICE_NAME,
    ResourceAttributes.SERVICE_VERSION: "1.0.0",
    ResourceAttributes.DEPLOYMENT_ENVIRONMENT: os.getenv("ENVIRONMENT", "staging"),
})

# ---------------------------------------------------------------------------
# Traces
# ---------------------------------------------------------------------------
tracer_provider = TracerProvider(resource=resource)
tracer_provider.add_span_processor(
    BatchSpanProcessor(OTLPSpanExporter(endpoint=OTEL_ENDPOINT, insecure=True))
)
trace.set_tracer_provider(tracer_provider)
tracer = trace.get_tracer(__name__)

# ---------------------------------------------------------------------------
# Metrics
# ---------------------------------------------------------------------------
metric_reader = PeriodicExportingMetricReader(
    OTLPMetricExporter(endpoint=OTEL_ENDPOINT, insecure=True),
    export_interval_millis=15000,
)
meter_provider = MeterProvider(resource=resource, metric_readers=[metric_reader])
metrics.set_meter_provider(meter_provider)
meter = metrics.get_meter(__name__)

request_counter = meter.create_counter(
    name="app.request.count",
    description="Total number of requests",
    unit="1",
)
request_duration = meter.create_histogram(
    name="app.request.duration",
    description="Request duration in milliseconds",
    unit="ms",
)
order_total = meter.create_counter(
    name="app.orders.total",
    description="Total orders created",
    unit="1",
)
active_users_gauge = meter.create_up_down_counter(
    name="app.users.active",
    description="Currently active users",
    unit="1",
)

# ---------------------------------------------------------------------------
# Logs
# ---------------------------------------------------------------------------
logger_provider = LoggerProvider(resource=resource)
logger_provider.add_log_record_processor(
    BatchLogRecordProcessor(OTLPLogExporter(endpoint=OTEL_ENDPOINT, insecure=True))
)
handler = LoggingHandler(level=logging.DEBUG, logger_provider=logger_provider)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(SERVICE_NAME)
logger.addHandler(handler)

# ---------------------------------------------------------------------------
# Flask app
# ---------------------------------------------------------------------------
app = Flask(__name__)
FlaskInstrumentor().instrument_app(app)

# Simulated data
PRODUCTS = [
    {"id": 1, "name": "Widget A", "price": 29.99},
    {"id": 2, "name": "Widget B", "price": 49.99},
    {"id": 3, "name": "Gadget X", "price": 99.99},
    {"id": 4, "name": "Gadget Y", "price": 149.99},
    {"id": 5, "name": "Doohickey", "price": 9.99},
]

USERS = [
    {"id": 1, "name": "Alice", "email": "alice@example.com"},
    {"id": 2, "name": "Bob", "email": "bob@example.com"},
    {"id": 3, "name": "Charlie", "email": "charlie@example.com"},
]


@app.route("/healthz")
def healthz():
    return jsonify({"status": "ok"})


@app.route("/api/products")
def list_products():
    start = time.time()
    request_counter.add(1, {"endpoint": "/api/products", "method": "GET"})
    logger.info("Listing all products")

    with tracer.start_as_current_span("fetch-products-from-db") as span:
        # Simulate DB latency
        delay = random.uniform(0.01, 0.05)
        time.sleep(delay)
        span.set_attribute("db.system", "postgresql")
        span.set_attribute("db.statement", "SELECT * FROM products")
        span.set_attribute("db.rows_returned", len(PRODUCTS))

    duration_ms = (time.time() - start) * 1000
    request_duration.record(duration_ms, {"endpoint": "/api/products"})
    return jsonify(PRODUCTS)


@app.route("/api/users")
def list_users():
    start = time.time()
    request_counter.add(1, {"endpoint": "/api/users", "method": "GET"})
    active_users_gauge.add(random.randint(-1, 2))
    logger.info("Listing users", extra={"user_count": len(USERS)})

    with tracer.start_as_current_span("fetch-users-from-db") as span:
        delay = random.uniform(0.01, 0.08)
        time.sleep(delay)
        span.set_attribute("db.system", "postgresql")
        span.set_attribute("db.statement", "SELECT * FROM users")

    duration_ms = (time.time() - start) * 1000
    request_duration.record(duration_ms, {"endpoint": "/api/users"})
    return jsonify(USERS)


@app.route("/api/orders", methods=["POST"])
def create_order():
    start = time.time()
    request_counter.add(1, {"endpoint": "/api/orders", "method": "POST"})

    user = random.choice(USERS)
    items = random.sample(PRODUCTS, k=random.randint(1, 3))
    total = sum(p["price"] for p in items)
    order_id = random.randint(10000, 99999)

    current_span = trace.get_current_span()
    current_span.set_attribute("order.id", order_id)
    current_span.set_attribute("order.user_id", user["id"])
    current_span.set_attribute("order.total", total)
    current_span.set_attribute("order.items_count", len(items))

    logger.info(
        "Creating order",
        extra={"order_id": order_id, "user": user["name"], "total": total},
    )

    # Step 1: validate inventory
    with tracer.start_as_current_span("validate-inventory") as span:
        time.sleep(random.uniform(0.01, 0.03))
        span.set_attribute("inventory.items_checked", len(items))
        logger.info("Inventory validated", extra={"order_id": order_id})

    # Step 2: process payment
    with tracer.start_as_current_span("process-payment") as span:
        delay = random.uniform(0.05, 0.2)
        time.sleep(delay)
        span.set_attribute("payment.amount", total)
        span.set_attribute("payment.method", "credit_card")
        span.set_attribute("payment.duration_ms", delay * 1000)

        # Simulate occasional slow payments
        if delay > 0.15:
            logger.warning(
                "Slow payment processing detected",
                extra={"order_id": order_id, "duration_ms": delay * 1000},
            )

        logger.info("Payment processed", extra={"order_id": order_id, "amount": total})

    # Step 3: send confirmation
    with tracer.start_as_current_span("send-confirmation") as span:
        time.sleep(random.uniform(0.01, 0.04))
        span.set_attribute("notification.type", "email")
        span.set_attribute("notification.recipient", user["email"])
        logger.info(
            "Order confirmation sent",
            extra={"order_id": order_id, "email": user["email"]},
        )

    order_total.add(1, {"status": "completed"})
    duration_ms = (time.time() - start) * 1000
    request_duration.record(duration_ms, {"endpoint": "/api/orders"})

    return jsonify({
        "order_id": order_id,
        "user": user["name"],
        "items": [p["name"] for p in items],
        "total": total,
        "status": "completed",
    }), 201


@app.route("/api/checkout", methods=["POST"])
def checkout():
    """Full checkout flow — calls multiple internal spans."""
    start = time.time()
    request_counter.add(1, {"endpoint": "/api/checkout", "method": "POST"})

    user = random.choice(USERS)
    cart = random.sample(PRODUCTS, k=random.randint(1, 4))
    total = sum(p["price"] for p in cart)

    logger.info("Checkout started", extra={"user": user["name"], "cart_size": len(cart)})

    with tracer.start_as_current_span("checkout-flow") as checkout_span:
        checkout_span.set_attribute("checkout.user_id", user["id"])
        checkout_span.set_attribute("checkout.total", total)

        # Cart validation
        with tracer.start_as_current_span("validate-cart"):
            time.sleep(random.uniform(0.005, 0.02))

        # Apply discounts
        with tracer.start_as_current_span("apply-discounts") as span:
            discount = random.choice([0, 0, 0, 5, 10, 15])
            if discount > 0:
                total = total * (1 - discount / 100)
                span.set_attribute("discount.percent", discount)
                logger.info("Discount applied", extra={"discount": discount})
            time.sleep(random.uniform(0.005, 0.01))

        # Calculate tax
        with tracer.start_as_current_span("calculate-tax") as span:
            tax = total * 0.2
            span.set_attribute("tax.rate", 0.2)
            span.set_attribute("tax.amount", tax)
            time.sleep(random.uniform(0.005, 0.01))

        # Process payment
        with tracer.start_as_current_span("charge-payment") as span:
            time.sleep(random.uniform(0.05, 0.3))
            span.set_attribute("payment.total", total + tax)

            # Simulate occasional payment failure
            if random.random() < 0.05:
                span.set_attribute("error", True)
                logger.error(
                    "Payment failed",
                    extra={"user": user["name"], "amount": total + tax},
                )
                duration_ms = (time.time() - start) * 1000
                request_duration.record(duration_ms, {"endpoint": "/api/checkout"})
                return jsonify({"error": "Payment declined"}), 402

        # Create shipment
        with tracer.start_as_current_span("create-shipment") as span:
            tracking = f"TRK-{random.randint(100000, 999999)}"
            span.set_attribute("shipment.tracking", tracking)
            time.sleep(random.uniform(0.01, 0.05))
            logger.info("Shipment created", extra={"tracking": tracking})

    order_total.add(1, {"status": "completed"})
    duration_ms = (time.time() - start) * 1000
    request_duration.record(duration_ms, {"endpoint": "/api/checkout"})

    logger.info("Checkout completed", extra={"user": user["name"], "total": total + tax})

    return jsonify({
        "user": user["name"],
        "items": [p["name"] for p in cart],
        "subtotal": round(total, 2),
        "tax": round(tax, 2),
        "total": round(total + tax, 2),
        "status": "completed",
    }), 201


@app.route("/api/error")
def simulate_error():
    """Endpoint that always raises an error — useful for testing error tracking."""
    request_counter.add(1, {"endpoint": "/api/error", "method": "GET"})
    logger.error("Simulated application error", extra={"error_type": "test"})

    with tracer.start_as_current_span("failing-operation") as span:
        span.set_attribute("error", True)
        span.record_exception(ValueError("Something went wrong"))
        raise ValueError("Simulated error for observability testing")


@app.errorhandler(ValueError)
def handle_value_error(e):
    logger.exception("Unhandled ValueError")
    return jsonify({"error": str(e)}), 500


if __name__ == "__main__":
    port = int(os.getenv("PORT", "8080"))
    logger.info(f"Starting {SERVICE_NAME} on port {port}")
    app.run(host="0.0.0.0", port=port)
