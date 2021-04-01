output "loadbalancer_ip" {
  value = digitalocean_loadbalancer.swarm.ip
}

output "swarm_tokens" {
  value     = data.external.tokens.result
  sensitive = true
}

output "manager_ips" {
  value = {
    for node in digitalocean_droplet.manager :
    node.name => node.ipv4_address
  }
}
