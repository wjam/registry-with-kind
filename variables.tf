terraform {
  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "=0.0.12"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 2.0"
    }
  }
}

variable "registry_port" {
  type        = number
  nullable    = true
  description = "Port number that the Docker registry should be exposed to outside of the cluster"
}

variable "cluster_ports" {
  type        = map(object({ host : number, container : number }))
  nullable    = false
  description = "Ports that should be exposed by the cluster for ingress traffic"
}

variable "workers" {
  type        = number
  description = "Number of worker nodes to have"
  default     = 2
  nullable    = false
}

locals {
  internal_registry_port = 5000
  registry_name          = "kind-registry"
}
