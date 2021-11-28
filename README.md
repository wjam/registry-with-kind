# registry-with-kind
Terraform that creates a [kind](https://kind.sigs.k8s.io/) Kubernetes cluster that has access to a local
[Docker registry](https://hub.docker.com/_/registry) to pull locally built images from. The images need to be tagged
with `localhost:5000` as the registry.

Note that this requires Docker running, so you may need to add yourself to the Docker group
```shell
sudo usermod -aG docker $(whoami)
```

Inspired by https://kind.sigs.k8s.io/docs/user/local-registry/ - note the comment about eventually being superseded by
https://github.com/kubernetes-sigs/kind/issues/1213.
