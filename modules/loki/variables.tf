variable "namespace" {
  type        = string
  description = "Kubernetes namespace to deploy into"
  default     = "observability"
}

variable "chart_version" {
  type        = string
  description = "Loki Helm chart version"
}

variable "s3_bucket_name" {
  type        = string
  description = "S3 bucket name for Loki chunks and index"
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
  default     = 30
}

variable "service_account_name" {
  type        = string
  description = "Kubernetes service account name for Loki"
  default     = "loki"
}

variable "promtail_enabled" {
  type        = bool
  description = "Deploy Promtail DaemonSet to collect Kubernetes pod logs"
  default     = true
}

variable "promtail_chart_version" {
  type        = string
  description = "Promtail Helm chart version"
  default     = "6.16.6"
}

variable "helm_values_override" {
  type        = any
  description = "Additional Helm values to merge (YAML string)"
  default     = ""
}
