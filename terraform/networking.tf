resource "digitalocean_firewall" "swarm-internal-fw" {
  name = format("%s-swarm-internal-fw", var.project_name)
  tags = [digitalocean_tag.project.id]

  outbound_rule {
    protocol         = "tcp"
    port_range       = "2377"
    destination_tags = [digitalocean_tag.project.id]
  }

  # for container network discovery
  outbound_rule {
    protocol         = "tcp"
    port_range       = "7946"
    destination_tags = [digitalocean_tag.project.id]
  }

  # UDP for the container overlay network.
  outbound_rule {
    protocol         = "udp"
    port_range       = "4789"
    destination_tags = [digitalocean_tag.project.id]
  }

  # for container network discovery.
  outbound_rule {
    protocol         = "udp"
    port_range       = "7946"
    destination_tags = [digitalocean_tag.project.id]
  }

  inbound_rule {
    protocol    = "tcp"
    port_range  = "2377"
    source_tags = [digitalocean_tag.project.id]
  }

  # for container network discovery
  inbound_rule {
    protocol    = "tcp"
    port_range  = "7946"
    source_tags = [digitalocean_tag.project.id]
  }

  # UDP for the container overlay network.
  inbound_rule {
    protocol    = "udp"
    port_range  = "4789"
    source_tags = [digitalocean_tag.project.id]
  }

  # for container network discovery.
  inbound_rule {
    protocol    = "udp"
    port_range  = "7946"
    source_tags = [digitalocean_tag.project.id]
  }
}

# remember there is a 50 rule limit
resource "digitalocean_firewall" "swarm-external-fw" {
  name = "${var.project_name}-swarm-external-fw"
  tags = [digitalocean_tag.project.id]

  # http/https connections
  outbound_rule {
    protocol              = "tcp"
    port_range            = "80"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
  outbound_rule {
    protocol              = "tcp"
    port_range            = "443"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  # DNS lookups
  outbound_rule {
    protocol              = "udp"
    port_range            = "53"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
  outbound_rule {
    protocol              = "tcp"
    port_range            = "53"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  # NTP
  outbound_rule {
    protocol              = "udp"
    port_range            = "123"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  # http/https connections
  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
}

resource "digitalocean_firewall" "swarm-ssh-fw" {
  name = "${var.project_name}-swarm-ssh-fw"
  tags = [digitalocean_tag.project.id]

  # git/ssh connection
  outbound_rule {
    protocol              = "tcp"
    port_range            = "22"
    destination_addresses = var.ssh_trusted_sources
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = var.ssh_trusted_sources
  }
}
