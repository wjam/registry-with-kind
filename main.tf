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
  }

  wait_for_ready = true
}

resource "docker_container" "registry" {
  image   = "registry:2"
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
  }

  depends_on = [kind_cluster.cluster]
}
