module "k8s" {
  source = "../../."

  cluster_ports = {
    http : {
      host : var.http_port
      container : 30000
    }
  }
  registry_port = null
}

variable "http_port" {
  type = number
}

output "kubeconfig" {
  value = module.k8s.kubeconfig
}
