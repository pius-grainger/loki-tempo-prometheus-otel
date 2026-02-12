# S3 Bucket Module

Reusable module that creates an encrypted S3 bucket with lifecycle rules and public access block. Used by Loki and Tempo for object storage.

## Architecture

```
+----------------------------------+
|  S3 Bucket                       |
|  +----------------------------+  |
|  | SSE-S3 Encryption (AES256) |  |
|  +----------------------------+  |
|  | Public Access Block (all)  |  |
|  +----------------------------+  |
|  | Lifecycle Rule             |  |
|  |   expire after N days      |  |
|  +----------------------------+  |
|  | Versioning (enabled)       |  |
|  +----------------------------+  |
+----------------------------------+
```

## What It Creates

- **S3 Bucket** with server-side encryption (AES256)
- **Public access block** on all four settings
- **Lifecycle rule** to expire objects after configurable days
- **Versioning** enabled for data protection

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `bucket_name` | string | (required) | Full name for the S3 bucket |
| `environment` | string | (required) | Environment name |
| `lifecycle_expiration_days` | number | `30` | Days before objects expire |
| `force_destroy` | bool | `false` | Allow bucket deletion with contents |
| `tags` | map(string) | `{}` | Additional tags |

## Outputs

| Name | Description |
|------|-------------|
| `bucket_id` | Bucket name |
| `bucket_arn` | Bucket ARN (for IAM policies) |
| `bucket_region` | Bucket region |

## Usage

```hcl
module "loki_bucket" {
  source = "../s3-bucket"

  bucket_name              = "myorg-staging-loki-chunks"
  environment              = "staging"
  lifecycle_expiration_days = 30
  force_destroy            = true
}
```
