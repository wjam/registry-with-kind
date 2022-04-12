output "kubeconfig" {
  value       = abspath(kind_cluster.cluster.kubeconfig_path)
  description = "Location for the Kubernetes config to connect to the cluster"
}

output "ingress_ports" {
  value       = var.cluster_ports
  description = "Ports exposed by the cluster for ingress traffic"
}

output "registry_url" {
  value       = "localhost:${var.registry_port}"
  description = "URL to use to push images into cluster - e.g. docker tag gcr.io/google-samples/hello-app:1.0 <registry_url>/hello-app:1.0; docker push <registry_url>/hello-app:1.0"
}
