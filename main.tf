resource "kind_cluster" "cluster" {
  name            = "cluster"
  kubeconfig_path = "${path.module}/files/config"

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"
    containerd_config_patches = [
      <<-TOML
            [plugins."io.containerd.grpc.v1.cri".registry.mirrors."localhost:${local.registry_port}"]
                endpoint = ["http://${local.registry_name}:5000"]
            TOML
    ]

    node {
      role = "control-plane"

      kubeadm_config_patches = []
    }

    node {
      role = "worker"

      kubeadm_config_patches = [
        file("${path.module}/files/worker-ingress.yaml"),
      ]

      extra_port_mappings {
        // istio http2
        container_port = 30000
        host_port      = 80
      }
      extra_port_mappings {
        // istio https
        container_port = 30001
        host_port      = 443
      }
      extra_port_mappings {
        // istio status-port
        container_port = 30002
        host_port      = 15021
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
    internal = local.registry_port
    external = 5000
  }

  networks_advanced {
    name = "kind"
  }

  volumes {
    container_path = "/var/lib/registry"
    host_path = abspath("${path.module}/files/registry")
    read_only = false
  }

  depends_on = [kind_cluster.cluster]
}
