# ──────────────────────────────────────────────
# Zalando Postgres Operator
# ──────────────────────────────────────────────
resource "helm_release" "postgres_operator" {
  name       = "postgres-operator"
  repository = "https://opensource.zalando.com/postgres-operator/charts/postgres-operator"
  chart      = "postgres-operator"
  version    = var.chart_version
  namespace  = var.namespace

  values = compact([
    templatefile("${path.module}/values.yaml.tpl", {
      namespace = var.namespace
    }),
    var.helm_values_override != "" ? var.helm_values_override : null,
  ])

  skip_crds = false
  timeout   = 600
}

# ──────────────────────────────────────────────
# PostgreSQL Cluster + PodMonitor (local chart)
# Avoids kubernetes_manifest plan-time API issue
# ──────────────────────────────────────────────
resource "helm_release" "postgres_cluster" {
  name      = "postgres-cluster"
  namespace = var.namespace
  chart     = "${path.module}/chart"

  set {
    name  = "namespace"
    value = var.namespace
  }

  set {
    name  = "teamId"
    value = var.team_id
  }

  set {
    name  = "clusterName"
    value = "${var.team_id}-${var.cluster_name}"
  }

  set {
    name  = "numberOfInstances"
    value = var.number_of_instances
  }

  set {
    name  = "pgVersion"
    value = var.pg_version
  }

  set {
    name  = "volumeSize"
    value = var.volume_size
  }

  set {
    name  = "cpuRequest"
    value = var.cpu_request
  }

  set {
    name  = "memoryRequest"
    value = var.memory_request
  }

  set {
    name  = "cpuLimit"
    value = var.cpu_limit
  }

  set {
    name  = "memoryLimit"
    value = var.memory_limit
  }

  depends_on = [helm_release.postgres_operator]
}
