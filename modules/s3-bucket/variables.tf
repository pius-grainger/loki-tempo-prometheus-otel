variable "bucket_name" {
  type        = string
  description = "Full name for the S3 bucket"
}

variable "environment" {
  type        = string
  description = "Environment name (staging, production)"
}

variable "lifecycle_expiration_days" {
  type        = number
  description = "Number of days before objects expire"
  default     = 30
}

variable "force_destroy" {
  type        = bool
  description = "Allow bucket deletion with contents (use true only for non-production)"
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "Additional tags to apply to the bucket"
  default     = {}
}
