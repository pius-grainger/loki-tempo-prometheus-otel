variable "namespace" {
  type        = string
  description = "Kubernetes namespace to deploy into"
  default     = "observability"
}

variable "chart_version" {
  type        = string
  description = "kube-prometheus-stack Helm chart version"
}

variable "prometheus_retention" {
  type        = string
  description = "Data retention period (e.g. 15d)"
  default     = "15d"
}

variable "prometheus_storage_size" {
  type        = string
  description = "PVC size for Prometheus data (e.g. 50Gi)"
  default     = "50Gi"
}

variable "alertmanager_enabled" {
  type        = bool
  description = "Whether to deploy Alertmanager"
  default     = true
}

variable "helm_values_override" {
  type        = any
  description = "Additional Helm values to merge (YAML string)"
  default     = ""
}
