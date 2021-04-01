variable "project_name" {
  description = "The name (or name prefix) of the project and its resources"
  default     = "sandbox"
}

variable "region" {
  description = "The region to deploy resources to"
  default     = "nyc3"
}

variable "authorized_keys" {
  description = "SSH fingerprints globally authorized"
  type        = list(string)
  default     = []
}

variable "deploy_keys" {
  description = "SSH fingerprints authorized for non-root deploy access"
  type        = list(string)
  default     = []
}

variable "vpc_cidr_block" {
  description = "The VPC CIDR address range"
  default     = "172.31.0.0/16"
}

variable "domain" {
  description = "The root domain name (including subdomain) to use for DNS records"
  default     = "syntaqx.io"
}

variable "swarm_manager_count" {
  description = "The number of nodes to run as swarm managers"
  default     = 2
}

variable "swarm_worker_count" {
  description = "The number of nodes to run as swarm workers"
  default     = 0
}

variable "ssh_trusted_sources" {
  description = "Restricts SSH connections to only trusted sources, all others will be denied"
  default     = ["0.0.0.0/0"]
}
