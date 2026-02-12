output "loki_service_name" {
  description = "In-cluster Loki gateway service name"
  value       = "loki-gateway"
}

output "loki_internal_url" {
  description = "Full in-cluster Loki URL (via gateway)"
  value       = "http://loki-gateway.${var.namespace}.svc.cluster.local:80"
}

output "loki_write_url" {
  description = "Loki push API endpoint for log ingestion"
  value       = "http://loki-gateway.${var.namespace}.svc.cluster.local:80/loki/api/v1/push"
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket created for Loki"
  value       = module.loki_bucket.bucket_id
}

output "irsa_role_arn" {
  description = "IAM role ARN used by Loki pods"
  value       = module.loki_irsa.role_arn
}
