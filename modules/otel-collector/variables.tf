variable "namespace" {
  type        = string
  description = "Kubernetes namespace to deploy into"
  default     = "observability"
}

variable "chart_version" {
  type        = string
  description = "OpenTelemetry Collector Helm chart version"
}

variable "mode" {
  type        = string
  description = "Deployment mode: deployment or daemonset"
  default     = "deployment"
}

variable "prometheus_remote_write_url" {
  type        = string
  description = "Prometheus remote write endpoint URL"
}

variable "loki_push_url" {
  type        = string
  description = "Loki push API endpoint URL"
}

variable "tempo_otlp_grpc_endpoint" {
  type        = string
  description = "Tempo OTLP gRPC endpoint (host:port)"
}

variable "cluster_name" {
  type        = string
  description = "Kubernetes cluster name to attach as resource attribute"
  default     = ""
}

variable "helm_values_override" {
  type        = any
  description = "Additional Helm values to merge (YAML string)"
  default     = ""
}
