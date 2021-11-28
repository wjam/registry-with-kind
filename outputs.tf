output "kubeconfig" {
  value       = kind_cluster.cluster.kubeconfig_path
  description = "Location for the Kubernetes config to connect to the cluster"
}
