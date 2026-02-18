# ──────────────────────────────────────────────
# SLI / SLO / Error Budget Rules
# Deployed as a local Helm chart to avoid
# kubernetes_manifest plan-time API requirement
# ──────────────────────────────────────────────
resource "helm_release" "slo_rules" {
  name      = "slo-rules"
  namespace = var.namespace
  chart     = "${path.module}/chart"

  set {
    name  = "namespace"
    value = var.namespace
  }
}
