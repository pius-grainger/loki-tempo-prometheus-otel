provider "aws" {
  region = var.aws_region
}

# ──────────────────────────────────────────────
# EKS Cluster (single-node demo)
# ──────────────────────────────────────────────
module "eks" {
  source = "../../modules/eks"

  cluster_name       = var.eks_cluster_name
  cluster_version    = "1.32"
  environment        = local.environment
  aws_region         = var.aws_region
  vpc_cidr           = "10.0.0.0/16"
  node_instance_types = ["t3.xlarge", "t3a.xlarge", "t2.xlarge", "m5.xlarge", "m5a.xlarge"]
  node_desired_count = 2
  node_min_count     = 1
  node_max_count     = 4
  node_disk_size     = 50
  capacity_type      = "SPOT"
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority)
  token                  = data.aws_eks_cluster_auth.this.token
}

locals {
  namespace   = "observability"
  environment = "staging"
}

# ──────────────────────────────────────────────
# Namespace
# ──────────────────────────────────────────────
resource "kubernetes_namespace" "observability" {
  metadata {
    name = local.namespace
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "environment"                  = local.environment
    }
  }

  depends_on = [module.eks]
}

# ──────────────────────────────────────────────
# Prometheus
# ──────────────────────────────────────────────
module "prometheus" {
  source = "../../modules/prometheus"

  namespace              = local.namespace
  chart_version          = "81.6.1"
  prometheus_retention   = "15d"
  prometheus_storage_size = "50Gi"
  alertmanager_enabled   = true

  depends_on = [kubernetes_namespace.observability]
}

# ──────────────────────────────────────────────
# Loki
# ──────────────────────────────────────────────
module "loki" {
  source = "../../modules/loki"

  namespace         = local.namespace
  chart_version     = "6.52.0"
  s3_bucket_name    = "myorg-staging-loki-chunks"
  aws_region        = var.aws_region
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
  environment       = local.environment
  retention_days    = 30

  depends_on = [kubernetes_namespace.observability]
}

# ──────────────────────────────────────────────
# Tempo
# ──────────────────────────────────────────────
module "tempo" {
  source = "../../modules/tempo"

  namespace                   = local.namespace
  chart_version               = "1.24.4"
  s3_bucket_name              = "myorg-staging-tempo-traces"
  aws_region                  = var.aws_region
  oidc_provider_arn           = module.eks.oidc_provider_arn
  oidc_provider_url           = module.eks.oidc_provider_url
  environment                 = local.environment
  retention_days              = 14
  prometheus_remote_write_url = "${module.prometheus.prometheus_internal_url}/api/v1/write"

  depends_on = [kubernetes_namespace.observability]
}

# ──────────────────────────────────────────────
# Grafana
# ──────────────────────────────────────────────
module "grafana" {
  source = "../../modules/grafana"

  namespace        = local.namespace
  chart_version    = "8.9.1"
  prometheus_url   = module.prometheus.prometheus_internal_url
  loki_url         = module.loki.loki_internal_url
  tempo_url        = module.tempo.tempo_internal_url
  admin_password   = var.grafana_admin_password
  ingress_enabled  = false
  persistence_size = "10Gi"

  depends_on = [
    module.prometheus,
    module.loki,
    module.tempo,
  ]
}

# ──────────────────────────────────────────────
# OpenTelemetry Collector
# ──────────────────────────────────────────────
module "otel_collector" {
  source = "../../modules/otel-collector"

  namespace                   = local.namespace
  chart_version               = "0.108.0"
  mode                        = "deployment"
  prometheus_remote_write_url = "${module.prometheus.prometheus_internal_url}/api/v1/write"
  loki_push_url               = module.loki.loki_write_url
  tempo_otlp_grpc_endpoint    = module.tempo.tempo_otlp_grpc_endpoint
  cluster_name                = module.eks.cluster_name

  depends_on = [
    module.prometheus,
    module.loki,
    module.tempo,
  ]
}
