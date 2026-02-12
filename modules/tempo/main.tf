# ──────────────────────────────────────────────
# S3 bucket for Tempo trace data
# ──────────────────────────────────────────────
module "tempo_bucket" {
  source = "../s3-bucket"

  bucket_name              = var.s3_bucket_name
  environment              = var.environment
  lifecycle_expiration_days = var.retention_days
  force_destroy            = var.environment != "production"

  tags = {
    Component = "tempo"
  }
}

# ──────────────────────────────────────────────
# IAM policy for S3 access
# ──────────────────────────────────────────────
data "aws_iam_policy_document" "tempo_s3" {
  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:ListBucket",
    ]
    resources = [
      module.tempo_bucket.bucket_arn,
      "${module.tempo_bucket.bucket_arn}/*",
    ]
  }
}

# ──────────────────────────────────────────────
# IRSA role for Tempo pods
# ──────────────────────────────────────────────
module "tempo_irsa" {
  source = "../irsa"

  role_name            = "${var.environment}-tempo-irsa"
  oidc_provider_arn    = var.oidc_provider_arn
  oidc_provider_url    = var.oidc_provider_url
  namespace            = var.namespace
  service_account_name = var.service_account_name
  policy_json          = data.aws_iam_policy_document.tempo_s3.json

  tags = {
    Component   = "tempo"
    Environment = var.environment
  }
}

# ──────────────────────────────────────────────
# Tempo Helm release
# ──────────────────────────────────────────────
resource "helm_release" "tempo" {
  name       = "tempo"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "tempo"
  version    = var.chart_version
  namespace  = var.namespace

  values = compact([
    templatefile("${path.module}/values.yaml.tpl", {
      s3_bucket_name               = module.tempo_bucket.bucket_id
      aws_region                   = var.aws_region
      irsa_role_arn                = module.tempo_irsa.role_arn
      service_account_name         = var.service_account_name
      trace_retention              = var.trace_retention
      prometheus_remote_write_url  = var.prometheus_remote_write_url
    }),
    var.helm_values_override != "" ? var.helm_values_override : null,
  ])

  timeout = 600
}
