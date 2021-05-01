#Get Client IP Address for NSG
data "http" "clientip" {
  url = "https://ipv4.icanhazip.com/"
}

locals {
  ports = [22, 80, 443]
}

locals {
  protocols = ["udp", "tcp"]
}

resource "digitalocean_firewall" "terraform-firewall" {
  name        = "terraform-firewall"
  droplet_ids = [digitalocean_droplet.rancher.id]

  dynamic "inbound_rule" {
    for_each = local.ports
    content {
      protocol         = "tcp"
      port_range       = inbound_rule.value
      source_addresses = ["${chomp(data.http.clientip.body)}/32"]
    }
  }

  dynamic "outbound_rule" {
    for_each = local.protocols
    content {
      protocol              = outbound_rule.value
      port_range            = "all"
      destination_addresses = ["0.0.0.0/0", "::/0"]
    }
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

}


