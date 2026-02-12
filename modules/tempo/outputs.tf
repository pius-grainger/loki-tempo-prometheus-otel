output "tempo_service_name" {
  description = "In-cluster Tempo service name"
  value       = "tempo"
}

output "tempo_internal_url" {
  description = "Full in-cluster Tempo URL"
  value       = "http://tempo.${var.namespace}.svc.cluster.local:3200"
}

output "tempo_otlp_grpc_endpoint" {
  description = "Tempo OTLP gRPC endpoint (host:port)"
  value       = "tempo.${var.namespace}.svc.cluster.local:4317"
}

output "tempo_otlp_http_endpoint" {
  description = "Tempo OTLP HTTP endpoint"
  value       = "http://tempo.${var.namespace}.svc.cluster.local:4318"
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket created for Tempo"
  value       = module.tempo_bucket.bucket_id
}

output "irsa_role_arn" {
  description = "IAM role ARN used by Tempo pods"
  value       = module.tempo_irsa.role_arn
}
