locals {
  name_prefix      = var.name_prefix
  vpc_id           = var.vpc_id
  vpc_cidr         = var.vpc_cidr
  ssh_allowed_cidr = var.ssh_allowed_cidr
  group_names      = toset(["alb", "web", "db", "jumpbox", "eks-node"])
  web_ports        = toset([80, 443])
}
