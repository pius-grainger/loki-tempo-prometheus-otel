import { NodeSDK } from "@opentelemetry/sdk-node";
import { OTLPTraceExporter } from "@opentelemetry/exporter-trace-otlp-grpc";
import { OTLPMetricExporter } from "@opentelemetry/exporter-metrics-otlp-grpc";
import { OTLPLogExporter } from "@opentelemetry/exporter-logs-otlp-grpc";
import { PeriodicExportingMetricReader } from "@opentelemetry/sdk-metrics";
import { BatchLogRecordProcessor } from "@opentelemetry/sdk-logs";
import { Resource } from "@opentelemetry/resources";
import {
  SEMRESATTRS_SERVICE_NAME,
  SEMRESATTRS_SERVICE_VERSION,
  SEMRESATTRS_DEPLOYMENT_ENVIRONMENT,
} from "@opentelemetry/semantic-conventions";
import { HttpInstrumentation } from "@opentelemetry/instrumentation-http";
import { ExpressInstrumentation } from "@opentelemetry/instrumentation-express";

const OTEL_ENDPOINT =
  process.env.OTEL_EXPORTER_OTLP_ENDPOINT || "localhost:4317";

const resource = new Resource({
  [SEMRESATTRS_SERVICE_NAME]: process.env.OTEL_SERVICE_NAME || "sample-app-ts",
  [SEMRESATTRS_SERVICE_VERSION]: "1.0.0",
  [SEMRESATTRS_DEPLOYMENT_ENVIRONMENT]: process.env.ENVIRONMENT || "staging",
});

const traceExporter = new OTLPTraceExporter({
  url: `http://${OTEL_ENDPOINT}`,
});

const metricReader = new PeriodicExportingMetricReader({
  exporter: new OTLPMetricExporter({
    url: `http://${OTEL_ENDPOINT}`,
  }),
  exportIntervalMillis: 15000,
});

const logExporter = new OTLPLogExporter({
  url: `http://${OTEL_ENDPOINT}`,
});

const logProcessor = new BatchLogRecordProcessor(logExporter);

const sdk = new NodeSDK({
  resource,
  traceExporter,
  metricReader: metricReader as any,
  logRecordProcessors: [logProcessor],
  instrumentations: [new HttpInstrumentation(), new ExpressInstrumentation()],
});

sdk.start();
console.log("[tracing] OpenTelemetry SDK initialized");

process.on("SIGTERM", () => {
  sdk
    .shutdown()
    .then(() => console.log("[tracing] SDK shut down"))
    .catch((err) => console.error("[tracing] Error shutting down SDK", err))
    .finally(() => process.exit(0));
});
