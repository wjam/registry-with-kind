resource "kind_cluster" "cluster" {
  name            = "cluster"
  kubeconfig_path = "${path.module}/files/config.yaml"

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"
    containerd_config_patches = [
      <<-TOML
            [plugins."io.containerd.grpc.v1.cri".registry.mirrors."localhost:${var.registry_port}"]
                endpoint = ["http://${local.registry_name}:${local.internal_registry_port}"]
            TOML
    ]

    node {
      role = "control-plane"

      kubeadm_config_patches = [
        yamlencode({ kind : "InitConfiguration", nodeRegistration : { kubeletExtraArgs : { node-labels : "ingress-ready=true" } } })
      ]

      dynamic "extra_port_mappings" {
        for_each = var.cluster_ports
        content {
          container_port = extra_port_mappings.value.container
          host_port      = extra_port_mappings.value.host
        }
      }
    }

    dynamic "node" {
      for_each = range(1, var.workers + 1)
      content {
        role = "worker"
      }
    }
  }

  wait_for_ready = true
}

data "docker_image" "image" {
  name = "registry:2"
}

resource "docker_container" "registry" {
  image   = data.docker_image.image.id
  name    = local.registry_name
  restart = "always"

  ports {
    internal = local.internal_registry_port
    external = var.registry_port
  }

  networks_advanced {
    name = "kind"
  }

  volumes {
    volume_name    = docker_volume.registry.name
    container_path = "/var/lib/registry"
    read_only      = false
  }

  depends_on = [kind_cluster.cluster]
}

# TODO this would stop pushed images from living longer than the cluster, but pollutes the Docker VM disk...
resource "docker_volume" "registry" {
  name = "${local.registry_name}-store"
}
