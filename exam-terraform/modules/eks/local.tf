locals {
  name_prefix        = var.name_prefix
  cluster_name       = var.cluster_name
  cluster_subnet_ids = var.cluster_subnet_ids
  node_instance_type = var.node_instance_type
  min_size           = var.min_size
  desired_size       = var.desired_size
  max_size           = var.max_size
}

