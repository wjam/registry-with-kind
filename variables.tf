terraform {
  required_providers {
    kind = {
      source = "kyma-incubator/kind"
      version = "=0.0.11"
    }
    docker = {
      source = "kreuzwerker/docker"
      version = "~> 2.0"
    }
  }
}

locals {
  registry_port = 5000
  registry_name = "kind-registry"
}
