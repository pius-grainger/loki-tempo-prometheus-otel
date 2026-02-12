variable "namespace" {
  type        = string
  description = "Kubernetes namespace to deploy into"
  default     = "observability"
}

variable "chart_version" {
  type        = string
  description = "Tempo Helm chart version"
}

variable "s3_bucket_name" {
  type        = string
  description = "S3 bucket name for Tempo trace data"
}

variable "aws_region" {
  type        = string
  description = "AWS region for the S3 bucket"
}

variable "oidc_provider_arn" {
  type        = string
  description = "ARN of the EKS cluster OIDC provider"
}

variable "oidc_provider_url" {
  type        = string
  description = "URL of the OIDC provider (without https://)"
}

variable "environment" {
  type        = string
  description = "Environment name (staging, production)"
}

variable "retention_days" {
  type        = number
  description = "S3 object lifecycle expiration in days"
  default     = 14
}

variable "trace_retention" {
  type        = string
  description = "How long Tempo keeps traces (e.g. 72h)"
  default     = "72h"
}

variable "prometheus_remote_write_url" {
  type        = string
  description = "Prometheus remote write URL for metrics generator"
  default     = ""
}

variable "service_account_name" {
  type        = string
  description = "Kubernetes service account name for Tempo"
  default     = "tempo"
}

variable "helm_values_override" {
  type        = any
  description = "Additional Helm values to merge (YAML string)"
  default     = ""
}
