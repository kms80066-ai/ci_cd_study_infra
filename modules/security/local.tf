locals {
  vpc_id           = var.vpc_id
  vpc_cidr         = var.vpc_cidr
  tag_header       = var.tag_header
  non_public_cidrs = var.non_public_cidrs

  groups = toset([
    "ssh",
    "internal-ssh",
    "external-alb",
    "internal-alb",
    "endpoint",
    "efs"
  ])

  web_ports         = toset(["80", "443"])
  efs_source_groups = toset(["internal-alb", "external-alb"])
}
