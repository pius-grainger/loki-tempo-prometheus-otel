variable "role_name" {
  type        = string
  description = "Name for the IAM role"
}

variable "oidc_provider_arn" {
  type        = string
  description = "ARN of the EKS cluster OIDC provider"
}

variable "oidc_provider_url" {
  type        = string
  description = "URL of the OIDC provider (without https://)"
}

variable "namespace" {
  type        = string
  description = "Kubernetes namespace for the service account"
}

variable "service_account_name" {
  type        = string
  description = "Kubernetes service account name"
}

variable "policy_json" {
  type        = string
  description = "JSON IAM policy document to attach to the role"
}

variable "tags" {
  type        = map(string)
  description = "Additional tags to apply to the IAM role"
  default     = {}
}
