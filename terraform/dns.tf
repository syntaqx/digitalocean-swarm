resource "digitalocean_domain" "default" {
  name = var.domain
}

resource "digitalocean_record" "apex" {
  domain = digitalocean_domain.default.name
  type   = "A"
  name   = "@"
  value  = digitalocean_loadbalancer.swarm.ip
}

resource "digitalocean_record" "www" {
  domain = digitalocean_domain.default.name
  type   = "CNAME"
  name   = "www"
  value  = "@"
}

resource "digitalocean_record" "wildcard" {
  domain = digitalocean_domain.default.name
  type   = "CNAME"
  name   = "*"
  value  = "@"
}
