resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.chart_version
  namespace  = var.namespace

  values = compact([
    templatefile("${path.module}/values.yaml.tpl", {
      prometheus_retention    = var.prometheus_retention
      prometheus_storage_size = var.prometheus_storage_size
      alertmanager_enabled    = var.alertmanager_enabled
    }),
    var.helm_values_override != "" ? var.helm_values_override : null,
  ])

  # CRDs are large; install them with the chart
  skip_crds = false

  timeout = 600
}
