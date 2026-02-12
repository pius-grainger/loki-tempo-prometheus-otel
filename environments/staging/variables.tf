variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "eu-west-2"
}

variable "eks_cluster_name" {
  type        = string
  description = "Name of the EKS cluster to create"
  default     = "myorg-staging-obs"
}

variable "grafana_admin_password" {
  type        = string
  sensitive   = true
  description = "Grafana admin password"
}
