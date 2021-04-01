resource "tls_private_key" "provisioner" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "random_string" "prefix" {
  length  = 16
  special = false
}

# resource "local_file" "swarm_private_key" {
#   filename          = format("%s/%s-%s-%s", var.tmpdir, random_string.prefix.result, var.name, var.workspace)
#   sensitive_content = tls_private_key.generated.private_key_pem
# }

# resource "local_file" "swarm_public_key" {
#   filename          = format("%s/%s-%s-%s.pub", var.tmpdir, random_string.prefix.result, var.name, var.workspace)
#   sensitive_content = tls_private_key.generated.public_key_openssh
# }
