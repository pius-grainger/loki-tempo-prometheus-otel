resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  version    = var.chart_version
  namespace  = var.namespace

  values = compact([
    templatefile("${path.module}/values.yaml.tpl", {
      admin_password      = var.admin_password
      prometheus_url      = var.prometheus_url
      loki_url            = var.loki_url
      tempo_url           = var.tempo_url
      persistence_enabled = var.persistence_enabled
      persistence_size    = var.persistence_size
      ingress_enabled     = var.ingress_enabled
      ingress_host        = var.ingress_host
    }),
    var.helm_values_override != "" ? var.helm_values_override : null,
  ])

  timeout = 600
}
