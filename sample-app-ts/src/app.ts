import express, { Request, Response, NextFunction } from "express";
import { trace, metrics, SpanStatusCode } from "@opentelemetry/api";
import winston from "winston";

// ---------------------------------------------------------------------------
// Logger (winston → stdout, picked up by Promtail)
// ---------------------------------------------------------------------------
const logger = winston.createLogger({
  level: "info",
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  defaultMeta: { service: process.env.OTEL_SERVICE_NAME || "sample-app-ts" },
  transports: [new winston.transports.Console()],
});

// ---------------------------------------------------------------------------
// OTel handles
// ---------------------------------------------------------------------------
const tracer = trace.getTracer("sample-app-ts");
const meter = metrics.getMeter("sample-app-ts");

const requestCounter = meter.createCounter("app.request.count", {
  description: "Total number of requests",
  unit: "1",
});

const requestDuration = meter.createHistogram("app.request.duration", {
  description: "Request duration in milliseconds",
  unit: "ms",
});

const orderTotal = meter.createCounter("app.orders.total", {
  description: "Total orders created",
  unit: "1",
});

const activeUsers = meter.createUpDownCounter("app.users.active", {
  description: "Currently active users",
  unit: "1",
});

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function rand(min: number, max: number): number {
  return Math.random() * (max - min) + min;
}

function randInt(min: number, max: number): number {
  return Math.floor(rand(min, max + 1));
}

function sample<T>(arr: T[], count: number): T[] {
  const shuffled = [...arr].sort(() => 0.5 - Math.random());
  return shuffled.slice(0, count);
}

// ---------------------------------------------------------------------------
// Simulated data
// ---------------------------------------------------------------------------
interface Product {
  id: number;
  name: string;
  price: number;
  category: string;
}

interface User {
  id: number;
  name: string;
  email: string;
  tier: string;
}

const PRODUCTS: Product[] = [
  { id: 1, name: "TypeScript Handbook", price: 39.99, category: "books" },
  { id: 2, name: "Mechanical Keyboard", price: 149.99, category: "electronics" },
  { id: 3, name: "Standing Desk", price: 499.99, category: "furniture" },
  { id: 4, name: "Noise Cancelling Headphones", price: 299.99, category: "electronics" },
  { id: 5, name: "Ergonomic Mouse", price: 79.99, category: "electronics" },
  { id: 6, name: "Monitor Light Bar", price: 59.99, category: "electronics" },
];

const USERS: User[] = [
  { id: 1, name: "Alice", email: "alice@example.com", tier: "premium" },
  { id: 2, name: "Bob", email: "bob@example.com", tier: "standard" },
  { id: 3, name: "Charlie", email: "charlie@example.com", tier: "premium" },
  { id: 4, name: "Diana", email: "diana@example.com", tier: "standard" },
];

// ---------------------------------------------------------------------------
// Express app
// ---------------------------------------------------------------------------
const app = express();
app.use(express.json());

// Health check
app.get("/healthz", (_req: Request, res: Response) => {
  res.json({ status: "ok", service: "sample-app-ts" });
});

// List products (with optional category filter)
app.get("/api/products", async (req: Request, res: Response) => {
  const start = Date.now();
  const category = req.query.category as string | undefined;
  requestCounter.add(1, { endpoint: "/api/products", method: "GET" });

  logger.info("Listing products", { category: category || "all" });

  const result = await tracer.startActiveSpan(
    "query-products-db",
    async (span) => {
      await sleep(rand(10, 50));
      span.setAttribute("db.system", "postgresql");
      span.setAttribute(
        "db.statement",
        category
          ? `SELECT * FROM products WHERE category = '${category}'`
          : "SELECT * FROM products"
      );

      const filtered = category
        ? PRODUCTS.filter((p) => p.category === category)
        : PRODUCTS;
      span.setAttribute("db.rows_returned", filtered.length);
      span.end();
      return filtered;
    }
  );

  requestDuration.record(Date.now() - start, { endpoint: "/api/products" });
  res.json(result);
});

// List users
app.get("/api/users", async (_req: Request, res: Response) => {
  const start = Date.now();
  requestCounter.add(1, { endpoint: "/api/users", method: "GET" });
  activeUsers.add(randInt(-1, 2));

  logger.info("Listing users", { user_count: USERS.length });

  await tracer.startActiveSpan("query-users-db", async (span) => {
    await sleep(rand(10, 80));
    span.setAttribute("db.system", "postgresql");
    span.setAttribute("db.statement", "SELECT * FROM users");
    span.setAttribute("db.rows_returned", USERS.length);
    span.end();
  });

  requestDuration.record(Date.now() - start, { endpoint: "/api/users" });
  res.json(USERS);
});

// Create order
app.post("/api/orders", async (_req: Request, res: Response) => {
  const start = Date.now();
  requestCounter.add(1, { endpoint: "/api/orders", method: "POST" });

  const user = USERS[randInt(0, USERS.length - 1)];
  const items = sample(PRODUCTS, randInt(1, 3));
  const total = items.reduce((sum, p) => sum + p.price, 0);
  const orderId = randInt(10000, 99999);

  const currentSpan = trace.getActiveSpan();
  if (currentSpan) {
    currentSpan.setAttribute("order.id", orderId);
    currentSpan.setAttribute("order.user_id", user.id);
    currentSpan.setAttribute("order.total", total);
    currentSpan.setAttribute("order.items_count", items.length);
  }

  logger.info("Creating order", {
    order_id: orderId,
    user: user.name,
    total,
  });

  // Step 1: validate inventory
  await tracer.startActiveSpan("validate-inventory", async (span) => {
    await sleep(rand(10, 30));
    span.setAttribute("inventory.items_checked", items.length);
    span.setAttribute("inventory.all_available", true);
    logger.info("Inventory validated", { order_id: orderId });
    span.end();
  });

  // Step 2: process payment
  await tracer.startActiveSpan("process-payment", async (span) => {
    const delay = rand(50, 200);
    await sleep(delay);
    span.setAttribute("payment.amount", total);
    span.setAttribute("payment.method", "credit_card");
    span.setAttribute("payment.duration_ms", delay);

    if (delay > 150) {
      logger.warn("Slow payment processing detected", {
        order_id: orderId,
        duration_ms: Math.round(delay),
      });
    }
    logger.info("Payment processed", { order_id: orderId, amount: total });
    span.end();
  });

  // Step 3: send confirmation
  await tracer.startActiveSpan("send-notification", async (span) => {
    await sleep(rand(10, 40));
    span.setAttribute("notification.type", "email");
    span.setAttribute("notification.recipient", user.email);
    logger.info("Order confirmation sent", {
      order_id: orderId,
      email: user.email,
    });
    span.end();
  });

  orderTotal.add(1, { status: "completed" });
  requestDuration.record(Date.now() - start, { endpoint: "/api/orders" });

  res.status(201).json({
    order_id: orderId,
    user: user.name,
    items: items.map((p) => p.name),
    total: Math.round(total * 100) / 100,
    status: "completed",
  });
});

// Checkout flow
app.post("/api/checkout", async (_req: Request, res: Response) => {
  const start = Date.now();
  requestCounter.add(1, { endpoint: "/api/checkout", method: "POST" });

  const user = USERS[randInt(0, USERS.length - 1)];
  const cart = sample(PRODUCTS, randInt(1, 4));
  let subtotal = cart.reduce((sum, p) => sum + p.price, 0);

  logger.info("Checkout started", {
    user: user.name,
    cart_size: cart.length,
    tier: user.tier,
  });

  await tracer.startActiveSpan("checkout-flow", async (checkoutSpan) => {
    checkoutSpan.setAttribute("checkout.user_id", user.id);
    checkoutSpan.setAttribute("checkout.user_tier", user.tier);
    checkoutSpan.setAttribute("checkout.subtotal", subtotal);

    // Cart validation
    await tracer.startActiveSpan("validate-cart", async (span) => {
      await sleep(rand(5, 20));
      span.setAttribute("cart.items", cart.length);
      span.end();
    });

    // Apply tier discount
    await tracer.startActiveSpan("apply-discounts", async (span) => {
      const discount =
        user.tier === "premium"
          ? [10, 15, 20][randInt(0, 2)]
          : [0, 0, 0, 5][randInt(0, 3)];
      if (discount > 0) {
        subtotal = subtotal * (1 - discount / 100);
        span.setAttribute("discount.percent", discount);
        span.setAttribute("discount.reason", user.tier === "premium" ? "premium_tier" : "promo");
        logger.info("Discount applied", { discount, tier: user.tier });
      }
      await sleep(rand(5, 10));
      span.end();
    });

    // Calculate tax
    const tax = await tracer.startActiveSpan(
      "calculate-tax",
      async (span) => {
        const taxAmount = subtotal * 0.2;
        span.setAttribute("tax.rate", 0.2);
        span.setAttribute("tax.amount", taxAmount);
        await sleep(rand(5, 10));
        span.end();
        return taxAmount;
      }
    );

    // Charge payment
    const paymentOk = await tracer.startActiveSpan(
      "charge-payment",
      async (span) => {
        await sleep(rand(50, 300));
        span.setAttribute("payment.total", subtotal + tax);
        span.setAttribute("payment.currency", "USD");

        // 5% failure rate
        if (Math.random() < 0.05) {
          span.setStatus({
            code: SpanStatusCode.ERROR,
            message: "Payment declined",
          });
          span.setAttribute("error", true);
          logger.error("Payment failed", {
            user: user.name,
            amount: subtotal + tax,
          });
          span.end();
          return false;
        }
        span.end();
        return true;
      }
    );

    if (!paymentOk) {
      checkoutSpan.setStatus({
        code: SpanStatusCode.ERROR,
        message: "Checkout failed - payment declined",
      });
      checkoutSpan.end();
      requestDuration.record(Date.now() - start, {
        endpoint: "/api/checkout",
      });
      res.status(402).json({ error: "Payment declined" });
      return;
    }

    // Create shipment
    const tracking = await tracer.startActiveSpan(
      "create-shipment",
      async (span) => {
        const trackingId = `TRK-${randInt(100000, 999999)}`;
        span.setAttribute("shipment.tracking", trackingId);
        span.setAttribute("shipment.carrier", "express");
        await sleep(rand(10, 50));
        logger.info("Shipment created", { tracking: trackingId });
        span.end();
        return trackingId;
      }
    );

    checkoutSpan.end();

    orderTotal.add(1, { status: "completed" });
    requestDuration.record(Date.now() - start, { endpoint: "/api/checkout" });

    logger.info("Checkout completed", {
      user: user.name,
      total: subtotal + tax,
      tracking,
    });

    res.status(201).json({
      user: user.name,
      items: cart.map((p) => p.name),
      subtotal: Math.round(subtotal * 100) / 100,
      tax: Math.round(tax * 100) / 100,
      total: Math.round((subtotal + tax) * 100) / 100,
      tracking,
      status: "completed",
    });
  });
});

// Simulate error
app.get("/api/error", (_req: Request, res: Response) => {
  requestCounter.add(1, { endpoint: "/api/error", method: "GET" });
  logger.error("Simulated application error", { error_type: "test" });

  tracer.startActiveSpan("failing-operation", (span) => {
    span.setStatus({ code: SpanStatusCode.ERROR, message: "Simulated error" });
    span.recordException(new Error("Something went wrong in TypeScript app"));
    span.end();
  });

  res.status(500).json({ error: "Simulated error for observability testing" });
});

// Error handler
app.use((err: Error, _req: Request, res: Response, _next: NextFunction) => {
  logger.error("Unhandled error", { error: err.message, stack: err.stack });
  res.status(500).json({ error: err.message });
});

// ---------------------------------------------------------------------------
// Start
// ---------------------------------------------------------------------------
const port = parseInt(process.env.PORT || "8080", 10);
app.listen(port, "0.0.0.0", () => {
  logger.info(`sample-app-ts listening on port ${port}`);
});
