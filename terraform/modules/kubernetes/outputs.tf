# Name of the Kubernetes namespace all CNB workloads run in.
output "namespace" {
  description = "Kubernetes namespace for all CNB workloads on the Pi cluster"
  value       = kubernetes_namespace.cnb.metadata[0].name
}

# ClusterIP Service name for the banking backend — resolvable within the cluster via DNS.
output "banking_service_name" {
  description = "Kubernetes Service name for the banking backend"
  value       = kubernetes_service.banking.metadata[0].name
}

# ClusterIP Service name for the trading backend.
output "trading_service_name" {
  description = "Kubernetes Service name for the trading backend"
  value       = kubernetes_service.trading.metadata[0].name
}

# Headless Service name for the banking PostgreSQL StatefulSet.
output "banking_db_service_name" {
  description = "Kubernetes Service name for the banking database"
  value       = kubernetes_service.banking_db.metadata[0].name
}

# Headless Service name for the trading PostgreSQL StatefulSet.
output "trading_db_service_name" {
  description = "Kubernetes Service name for the trading database"
  value       = kubernetes_service.trading_db.metadata[0].name
}
