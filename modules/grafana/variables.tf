variable "namespace" {
  type        = string
  description = "Kubernetes namespace to deploy into"
  default     = "observability"
}

variable "chart_version" {
  type        = string
  description = "Grafana Helm chart version"
}

variable "prometheus_url" {
  type        = string
  description = "In-cluster Prometheus URL"
}

variable "loki_url" {
  type        = string
  description = "In-cluster Loki URL"
}

variable "tempo_url" {
  type        = string
  description = "In-cluster Tempo URL"
}

variable "admin_password" {
  type        = string
  description = "Grafana admin password"
  sensitive   = true
}

variable "ingress_enabled" {
  type        = bool
  description = "Whether to create an ingress resource"
  default     = false
}

variable "ingress_host" {
  type        = string
  description = "Hostname for the ingress resource"
  default     = ""
}

variable "persistence_enabled" {
  type        = bool
  description = "Enable persistent storage for Grafana"
  default     = true
}

variable "persistence_size" {
  type        = string
  description = "PVC size for Grafana data"
  default     = "10Gi"
}

variable "helm_values_override" {
  type        = any
  description = "Additional Helm values to merge (YAML string)"
  default     = ""
}
