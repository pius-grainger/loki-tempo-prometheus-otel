locals {
  dashboard_files = fileset("${path.module}/dashboards", "*.json")

  dashboards = {
    for f in local.dashboard_files :
    trimsuffix(f, ".json") => file("${path.module}/dashboards/${f}")
  }
}

resource "kubernetes_config_map" "grafana_dashboards" {
  for_each = local.dashboards

  metadata {
    name      = "grafana-dashboard-${each.key}"
    namespace = var.namespace

    labels = {
      grafana_dashboard              = "1"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  data = {
    "${each.key}.json" = each.value
  }

  depends_on = [helm_release.grafana]
}
