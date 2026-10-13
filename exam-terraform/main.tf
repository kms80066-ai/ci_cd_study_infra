module "network" {
  source       = "./modules/network"
  name_prefix  = local.tag_header
  vpc_cidr     = local.vpc_cidr
  subnet_map   = local.subnet_map
  cluster_name = local.eks_cluster_name
}

module "security" {
  source      = "./modules/security"
  name_prefix = local.tag_header
  vpc_id      = module.network.vpc_id
  vpc_cidr    = local.vpc_cidr
  ssh_allowed_cidr = local.ssh_allowed_cidr
}

module "web" {
  source             = "./modules/web"
  name_prefix        = local.tag_header
  vpc_id             = module.network.vpc_id
  public_subnet_ids  = module.network.public_subnet_ids
  private_subnet_ids = module.network.private_subnet_ids
  alb_sg_id          = module.security.alb_sg_id
  web_sg_id          = module.security.web_sg_id
  key_name           = local.key_name
  instance_type      = local.web_instance_type
  volume_size        = local.web_volume_size
  min_size           = local.web_min_size
  desired_size       = local.web_desired_size
  max_size           = local.web_max_size
  depends_on         = [module.network]
}

module "rds" {
  source             = "./modules/rds"
  name_prefix        = local.tag_header
  private_subnet_ids = module.network.private_subnet_ids
  db_sg_id           = module.security.db_sg_id
  instance_class     = local.db_instance_class
  db_name            = local.db_name
  db_username        = local.db_username
  multi_az           = local.db_multi_az
}

module "eks" {
  source             = "./modules/eks"
  name_prefix        = local.tag_header
  cluster_name       = local.eks_cluster_name
  cluster_subnet_ids = module.network.cluster_subnet_ids
  node_sg_id         = module.security.eks_node_sg_id
  key_name           = local.key_name
  node_instance_type = local.eks_node_type
  min_size           = local.eks_node_min
  desired_size       = local.eks_node_desired
  max_size           = local.eks_node_max
  depends_on         = [module.network]
}

# 별도의 Public Jumpbox (AL2023 + SSM + SSH Key)
module "jumpbox" {
  source             = "./modules/jumpbox"
  name_prefix        = local.tag_header
  public_subnet_id   = module.network.subnet_ids["public_a"]
  sg_id              = module.security.jumpbox_sg_id
  key_name           = local.key_name
  instance_type      = local.jumpbox_instance_type
  volume_size        = local.jumpbox_volume_size
}
