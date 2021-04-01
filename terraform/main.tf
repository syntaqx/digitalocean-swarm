provider "digitalocean" {
  # export DIGITALOCEAN_ACCESS_TOKEN, DIGITALOCEAN_TOKEN
}

resource "digitalocean_ssh_key" "provisioner" {
  name       = format("%s-%s", var.project_name, terraform.workspace)
  public_key = tls_private_key.provisioner.public_key_openssh
}

resource "digitalocean_project" "default" {
  name        = format("%s-%s", var.project_name, terraform.workspace)
  description = "A project to represent development resources."
  purpose     = "Web Application"
  environment = "Development"
}

# The following resource types can be associated with a project:
# - Database Clusters
# - Domains
# - Droplets
# - Floating IP
# - Load Balancers
# - Spaces Bucket
# - Volume
resource "digitalocean_project_resources" "default" {
  project = digitalocean_project.default.id
  resources = concat([
    digitalocean_domain.default.urn,
    digitalocean_loadbalancer.swarm.urn,
    ],
    digitalocean_droplet.manager[*].urn,
  )
}

resource "digitalocean_vpc" "default" {
  name     = format("%s-%s-%s", var.project_name, terraform.workspace, var.region)
  region   = var.region
  ip_range = var.vpc_cidr_block
}

resource "digitalocean_loadbalancer" "swarm" {
  name     = format("%s-%s-swarm-%s", var.project_name, terraform.workspace, var.region)
  region   = var.region
  vpc_uuid = digitalocean_vpc.default.id

  forwarding_rule {
    entry_port      = 80
    entry_protocol  = "http"
    target_port     = 80
    target_protocol = "http"
  }

  forwarding_rule {
    entry_port      = 443
    entry_protocol  = "https"
    target_port     = 443
    target_protocol = "https"
    tls_passthrough = true
  }

  redirect_http_to_https = true
  enable_proxy_protocol  = true

  healthcheck {
    port     = 22
    protocol = "tcp"
  }

  droplet_tag = digitalocean_tag.project.id
}

resource "digitalocean_droplet" "manager" {
  count  = var.swarm_manager_count
  name   = format("%s-%s-%s-manager%d", var.project_name, terraform.workspace, var.region, count.index + 1)
  region = var.region
  size   = "s-1vcpu-1gb"
  image  = "docker-20-04"

  user_data = file("${path.module}/scripts/cloud-init.yaml")
  ssh_keys  = distinct(concat(var.authorized_keys, [digitalocean_ssh_key.provisioner.id]))
  tags = [
    digitalocean_tag.project.id,
    digitalocean_tag.manager.id,
    digitalocean_tag.swarm.id,
  ]

  backups            = false
  monitoring         = true
  private_networking = true
  ipv6               = true
  vpc_uuid           = digitalocean_vpc.default.id

  connection {
    host        = self.ipv4_address
    user        = "root"
    private_key = tls_private_key.provisioner.private_key_pem
    timeout     = "10m"
  }

  # Prevent the resource from being completed until cloud-init has bootstrapped
  provisioner "remote-exec" {
    on_failure = continue
    inline = [
      "echo 'Waiting for cloud-init to complete...'",
      "tail -f /var/log/cloud-init-output.log &", # /var/log/cloud-init.log
      "cloud-init status --wait > /dev/null",
    ]
  }
}

locals {
  leader = element(digitalocean_droplet.manager, 0)
}

resource "null_resource" "swarm_init" {
  triggers = {
    swarm_leader_id = local.leader.id
  }

  connection {
    type        = "ssh"
    host        = local.leader.ipv4_address
    user        = "root"
    private_key = tls_private_key.provisioner.private_key_pem
    timeout     = "10m"
  }

  provisioner "remote-exec" {
    on_failure = continue
    inline     = ["docker swarm init --advertise-addr ${local.leader.ipv4_address_private}"]
  }
}

data "external" "tokens" {
  depends_on = [null_resource.swarm_init]
  program    = ["bash", "${path.module}/scripts/swarm-join-tokens.sh"]
  query = {
    host        = local.leader.ipv4_address
    user        = "root"
    private_key = tls_private_key.provisioner.private_key_pem
  }
}

resource "null_resource" "manager_join" {
  triggers = {
    swarm_manager_ids = join(",", digitalocean_droplet.manager.*.id)
  }

  count = length(digitalocean_droplet.manager) - 1

  connection {
    host        = element(digitalocean_droplet.manager.*.ipv4_address, count.index + 1)
    user        = "root"
    private_key = tls_private_key.provisioner.private_key_pem
  }

  provisioner "remote-exec" {
    on_failure = continue
    inline = [
      format(
        "docker swarm join --advertise-addr %s --token %s %s",
        element(digitalocean_droplet.manager.*.ipv4_address_private, count.index + 1),
        data.external.tokens.result.manager,
        local.leader.ipv4_address_private,
      )
    ]
  }
}
