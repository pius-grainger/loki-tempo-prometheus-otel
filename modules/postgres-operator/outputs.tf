output "cluster_name" {
  value       = "${var.team_id}-${var.cluster_name}"
  description = "Full name of the PostgreSQL cluster"
}

output "cluster_service" {
  value       = "${var.team_id}-${var.cluster_name}.${var.namespace}.svc.cluster.local"
  description = "Internal DNS name of the PostgreSQL master service"
}

output "cluster_port" {
  value       = 5432
  description = "PostgreSQL service port"
}
