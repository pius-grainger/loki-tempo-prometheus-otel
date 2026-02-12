resource "helm_release" "otel_collector" {
  name       = "otel-collector"
  repository = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart      = "opentelemetry-collector"
  version    = var.chart_version
  namespace  = var.namespace

  values = compact([
    templatefile("${path.module}/values.yaml.tpl", {
      mode                        = var.mode
      tempo_otlp_grpc_endpoint    = var.tempo_otlp_grpc_endpoint
      prometheus_remote_write_url = var.prometheus_remote_write_url
      loki_push_url               = var.loki_push_url
      cluster_name                = var.cluster_name
    }),
    var.helm_values_override != "" ? var.helm_values_override : null,
  ])

  timeout = 600
}
