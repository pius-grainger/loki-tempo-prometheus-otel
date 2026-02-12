output "prometheus_service_name" {
  description = "In-cluster Prometheus service name"
  value       = "prometheus-kube-prometheus-prometheus"
}

output "prometheus_service_port" {
  description = "Prometheus service port"
  value       = 9090
}

output "prometheus_internal_url" {
  description = "Full in-cluster Prometheus URL"
  value       = "http://prometheus-kube-prometheus-prometheus.${var.namespace}.svc.cluster.local:9090"
}
