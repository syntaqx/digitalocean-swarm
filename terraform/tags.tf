resource "digitalocean_tag" "swarm" {
  name = "swarm"
}

resource "digitalocean_tag" "manager" {
  name = "swarm-role:manager"
}

resource "digitalocean_tag" "worker" {
  name = "swarm-role:worker"
}

resource "digitalocean_tag" "project" {
  name = format("project:%s-%s", var.project_name, terraform.workspace)
}
