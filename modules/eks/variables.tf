variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster"
}

variable "cluster_version" {
  type        = string
  description = "Kubernetes version for EKS"
  default     = "1.32"
}

variable "environment" {
  type        = string
  description = "Environment name (staging, production)"
}

variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "node_instance_types" {
  type        = list(string)
  description = "List of EC2 instance types for the node group (multiple types recommended for SPOT)"
  default     = ["t3.xlarge"]
}

variable "node_desired_count" {
  type        = number
  description = "Desired number of nodes"
  default     = 1
}

variable "node_min_count" {
  type        = number
  description = "Minimum number of nodes"
  default     = 1
}

variable "node_max_count" {
  type        = number
  description = "Maximum number of nodes"
  default     = 2
}

variable "node_disk_size" {
  type        = number
  description = "Disk size in GB for each node"
  default     = 50
}

variable "capacity_type" {
  type        = string
  description = "Capacity type for the node group (ON_DEMAND or SPOT)"
  default     = "ON_DEMAND"
}

variable "tags" {
  type        = map(string)
  description = "Additional tags"
  default     = {}
}
