# ──────────────────────────────────────────────
# S3 bucket for Loki chunks and index
# ──────────────────────────────────────────────
module "loki_bucket" {
  source = "../s3-bucket"

  bucket_name              = var.s3_bucket_name
  environment              = var.environment
  lifecycle_expiration_days = var.retention_days
  force_destroy            = var.environment != "production"

  tags = {
    Component = "loki"
  }
}

# ──────────────────────────────────────────────
# IAM policy for S3 access
# ──────────────────────────────────────────────
data "aws_iam_policy_document" "loki_s3" {
  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:ListBucket",
    ]
    resources = [
      module.loki_bucket.bucket_arn,
      "${module.loki_bucket.bucket_arn}/*",
    ]
  }
}

# ──────────────────────────────────────────────
# IRSA role for Loki pods
# ──────────────────────────────────────────────
module "loki_irsa" {
  source = "../irsa"

  role_name            = "${var.environment}-loki-irsa"
  oidc_provider_arn    = var.oidc_provider_arn
  oidc_provider_url    = var.oidc_provider_url
  namespace            = var.namespace
  service_account_name = var.service_account_name
  policy_json          = data.aws_iam_policy_document.loki_s3.json

  tags = {
    Component   = "loki"
    Environment = var.environment
  }
}

# ──────────────────────────────────────────────
# Loki Helm release
# ──────────────────────────────────────────────
resource "helm_release" "loki" {
  name       = "loki"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki"
  version    = var.chart_version
  namespace  = var.namespace

  values = compact([
    templatefile("${path.module}/values.yaml.tpl", {
      s3_bucket_name       = module.loki_bucket.bucket_id
      aws_region           = var.aws_region
      irsa_role_arn        = module.loki_irsa.role_arn
      service_account_name = var.service_account_name
    }),
    var.helm_values_override != "" ? var.helm_values_override : null,
  ])

  timeout = 600
}

# ──────────────────────────────────────────────
# Promtail — DaemonSet that ships pod logs to Loki
# ──────────────────────────────────────────────
resource "helm_release" "promtail" {
  count = var.promtail_enabled ? 1 : 0

  name       = "promtail"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "promtail"
  version    = var.promtail_chart_version
  namespace  = var.namespace

  values = [
    yamlencode({
      config = {
        clients = [
          {
            url = "http://loki-gateway.${var.namespace}.svc.cluster.local:80/loki/api/v1/push"
          }
        ]
      }
    })
  ]

  timeout = 300

  depends_on = [helm_release.loki]
}
