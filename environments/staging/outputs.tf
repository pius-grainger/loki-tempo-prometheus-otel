output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "kubeconfig_command" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.aws_region}"
}

output "prometheus_url" {
  description = "In-cluster Prometheus URL"
  value       = module.prometheus.prometheus_internal_url
}

output "loki_url" {
  description = "In-cluster Loki URL"
  value       = module.loki.loki_internal_url
}

output "tempo_url" {
  description = "In-cluster Tempo URL"
  value       = module.tempo.tempo_internal_url
}

output "grafana_url" {
  description = "In-cluster Grafana URL"
  value       = module.grafana.grafana_url
}

output "otel_collector_grpc_endpoint" {
  description = "OTLP gRPC endpoint for applications to send telemetry"
  value       = module.otel_collector.otlp_grpc_endpoint
}

output "otel_collector_http_endpoint" {
  description = "OTLP HTTP endpoint for applications to send telemetry"
  value       = module.otel_collector.otlp_http_endpoint
}

output "loki_s3_bucket" {
  description = "S3 bucket used by Loki"
  value       = module.loki.s3_bucket_name
}

output "tempo_s3_bucket" {
  description = "S3 bucket used by Tempo"
  value       = module.tempo.s3_bucket_name
}
