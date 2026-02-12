output "otlp_grpc_endpoint" {
  description = "Collector OTLP gRPC endpoint for applications"
  value       = "otel-collector-opentelemetry-collector.${var.namespace}.svc.cluster.local:4317"
}

output "otlp_http_endpoint" {
  description = "Collector OTLP HTTP endpoint for applications"
  value       = "http://otel-collector-opentelemetry-collector.${var.namespace}.svc.cluster.local:4318"
}
