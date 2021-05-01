terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

resource "digitalocean_kubernetes_cluster" "cluster01" {
  name    = "cluster01"
  region  = "nyc1"
  version = var.k8s_version
  node_pool {
    name       = "cluster01"
    size       = var.pool_size
    auto_scale = true
    min_nodes  = var.min_nodes
    max_nodes  = var.max_nodes
  }
}

resource "null_resource" "ingress-nginx" {
  count = var.ingress_nginx == true ? 1 : 0
  provisioner "local-exec" {
    command = "KUBECONFIG=$PWD/cluster01.yaml kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.46.0/deploy/static/provider/do/deploy.yaml"
  }
  depends_on = [
    null_resource.kubeconfig,
  ]
}

resource "null_resource" "kubeconfig" {
  provisioner "local-exec" {
    command = "echo '${digitalocean_kubernetes_cluster.cluster01.kube_config[0].raw_config}' | tee cluster01.yaml"
  }
  depends_on = [
    digitalocean_kubernetes_cluster.cluster01,
  ]
}

resource "null_resource" "destroy-kubeconfig" {
  provisioner "local-exec" {
    when    = destroy
    command = "rm -f $PWD/cluster01.yaml"
  }
}
