module "k8s" {
  source = "../../."

  cluster_ports = {
    http : {
      host : var.http_port
      container : 30000
    }
  }
  registry_port = var.registry_port
}

variable "registry_port" {
  type = number
}

variable "http_port" {
  type = number
}

output "registry_url" {
  value = module.k8s.registry_url
}

output "kubeconfig" {
  value = module.k8s.kubeconfig
}

output "ingress_ports" {
  value = module.k8s.ingress_ports
}
