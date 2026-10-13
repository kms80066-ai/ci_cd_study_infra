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
}

module "web" {
  source             = "./modules/web"
  name_prefix        = local.tag_header
  vpc_id             = module.network.vpc_id
  public_subnet_ids  = module.network.public_subnet_ids
  private_subnet_ids = module.network.private_subnet_ids
  alb_sg_id          = module.security.alb_sg_id
  web_sg_id          = module.security.web_sg_id
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
}

module "eks" {
  source             = "./modules/eks"
  name_prefix        = local.tag_header
  cluster_name       = local.eks_cluster_name
  cluster_subnet_ids = module.network.cluster_subnet_ids
  node_instance_type = local.eks_node_type
  min_size           = local.eks_node_min
  desired_size       = local.eks_node_desired
  max_size           = local.eks_node_max
  depends_on         = [module.network]
}

# 10.13 Notion 4번 항목 중 CloudWatch 기본 대시보드/알람
# Grafana는 인증/사용 방식 미지정으로 여기서는 생성하지 않음
module "monitoring" {
  source             = "./modules/monitoring"
  name_prefix        = local.tag_header
  region             = local.region
  asg_name           = module.web.asg_name
  alb_arn_suffix     = module.web.alb_arn_suffix
  rds_identifier     = module.rds.db_identifier
}

