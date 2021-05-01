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

data "digitalocean_ssh_key" "ssh_key" {
  name = "ronaldo-nb"
}

resource "digitalocean_droplet" "rancher" {
  image              = "ubuntu-20-04-x64"
  name               = "rancher"
  region             = "nyc1"
  size               = "s-2vcpu-4gb"
  private_networking = true
  ssh_keys           = [data.digitalocean_ssh_key.ssh_key.id]
  connection {
    host        = self.ipv4_address
    user        = "root"
    type        = "ssh"
    private_key = file("~/.ssh/id_rsa")
    timeout     = "5m"
  }
  provisioner "remote-exec" {
    inline = [
      "export PATH=$PATH:/usr/bin",
      "curl https://releases.rancher.com/install-docker/19.03.sh | sh",
      "docker volume create rancher",
      "docker run -d --restart=unless-stopped -p 80:80 -p 443:443 -v rancher:/var/lib/rancher --privileged rancher/rancher:latest"
    ]
  }
}

data "external" "myipaddr" {
  program = ["bash", "-c", "curl -s 'https://ipinfo.io/json'"]
}

output "my_public_ip" {
  value = data.external.myipaddr.result.ip
}

output "ip_rancher" {
  value = digitalocean_droplet.rancher.*.ipv4_address
}

