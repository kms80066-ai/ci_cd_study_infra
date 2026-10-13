locals {
  name_prefix  = var.name_prefix
  vpc_cidr     = var.vpc_cidr
  cluster_name = var.cluster_name
  subnet_map   = var.subnet_map

  public_subnets  = { for k, s in local.subnet_map : k => s if s.kind == "public" }
  private_subnets = { for k, s in local.subnet_map : k => s if s.kind == "private" }
  cluster_subnets = { for k, s in local.subnet_map : k => s if s.kind == "cluster" }
}

