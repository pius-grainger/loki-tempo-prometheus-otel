variable "namespace" {
  type        = string
  description = "Kubernetes namespace to deploy into"
  default     = "observability"
}

variable "chart_version" {
  type        = string
  description = "Zalando postgres-operator Helm chart version"
  default     = "1.13.0"
}

variable "team_id" {
  type        = string
  description = "Team ID prefix for the PostgreSQL cluster name"
  default     = "observability"
}

variable "cluster_name" {
  type        = string
  description = "Name suffix for the PostgreSQL cluster"
  default     = "obs-postgres"
}

variable "pg_version" {
  type        = string
  description = "PostgreSQL major version"
  default     = "16"
}

variable "number_of_instances" {
  type        = number
  description = "Number of PostgreSQL instances (1 = standalone, 2+ = HA)"
  default     = 1
}

variable "volume_size" {
  type        = string
  description = "PVC size for PostgreSQL data"
  default     = "5Gi"
}

variable "cpu_request" {
  type    = string
  default = "100m"
}

variable "memory_request" {
  type    = string
  default = "256Mi"
}

variable "cpu_limit" {
  type    = string
  default = "500m"
}

variable "memory_limit" {
  type    = string
  default = "512Mi"
}

variable "helm_values_override" {
  type        = string
  description = "Additional Helm values to merge (YAML string)"
  default     = ""
}
