output "grafana_service_name" {
  description = "In-cluster Grafana service name"
  value       = "grafana"
}

output "grafana_url" {
  description = "Full in-cluster Grafana URL"
  value       = "http://grafana.${var.namespace}.svc.cluster.local:80"
}
