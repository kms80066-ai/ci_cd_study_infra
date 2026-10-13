locals {
  name_prefix = var.name_prefix
  vpc_id      = var.vpc_id
  group_names = toset(["alb", "web", "db"])
}

