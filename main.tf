# ========================================================
# Root Module
# local.tf의 설정값을 각 모듈에 전달하고,
# 모듈 output을 다음 모듈 input으로 연결합니다.
# ========================================================

module "network" {
  source = "./modules/network"

  azs          = local.azs
  vpc_cidr     = local.vpc_cidr
  tag_header   = local.tag_header
  subnet_map   = local.subnet_map
  cluster_name = local.cluster_name
}

module "security" {
  source = "./modules/security"

  vpc_id           = module.network.vpc_id
  vpc_cidr         = local.vpc_cidr
  tag_header       = local.tag_header
  non_public_cidrs = local.non_public_cidrs
}

module "endpoints" {
  source = "./modules/endpoints"

  region                     = local.region
  vpc_id                     = module.network.vpc_id
  tag_header                 = local.tag_header
  private_subnet_ids         = module.network.private_subnet_ids
  non_public_route_table_ids = module.network.non_public_route_table_ids
  endpoint_sg_id             = module.security.endpoint_sg_id
}

module "storage" {
  source = "./modules/storage"

  bucket_prefix   = local.bucket_prefix
  tag_header      = local.tag_header
  private_subnets = module.network.private_subnets_by_az
  efs_sg_id       = module.security.efs_sg_id
}

module "compute" {
  source = "./modules/compute"

  name = "${local.tag_header}lab-ec2"

  # EC2 위치를 바꾸고 싶으면 local.tf의 test_ec2_subnet_key만 수정
  subnet_id          = module.network.subnet_ids[local.test_ec2_subnet_key]
  security_group_ids = [module.security.external_alb_sg_id, module.security.ssh_sg_id]
  key_name           = local.key_name
  efs_dns_name       = module.storage.efs_dns_name

  # User Data 실행 전에 Network와 EFS Mount Target이 준비되도록 대기
  depends_on = [module.network, module.storage]
}

# ========================================================
# 다음 수업의 4 / 5 / 6번도 같은 방식으로 아래에 module 블록을 추가합니다.
# 설정값은 local.tf에 먼저 정의하고, 필요한 기존 리소스 값은 module.xxx output으로 연결합니다.
# ========================================================
# ========================================================
# 4. Auto Scaling Group
#
# AL2023 EC2 생성
# → Docker AMI 생성
# → Launch Template
# → ALB / Target Group
# → ASG
# ========================================================

module "autoscaling" {
  source = "./modules/autoscaling"

  name         = local.asg_name
  builder_name = local.ami_builder_name

  region = local.region
  vpc_id = module.network.vpc_id

  # ========================================================
  # AMI Builder
  # ========================================================

  builder_subnet_id = module.network.subnet_ids[
    local.ami_builder_subnet_key
  ]

  builder_instance_type = local.ami_builder_instance_type

  # ========================================================
  # ALB / ASG
  # ========================================================

  public_subnet_ids  = module.network.public_subnet_ids
  private_subnet_ids = module.network.private_subnet_ids

  alb_security_group_id = module.security.external_alb_sg_id

  # 기존 internal-alb SG:
  # external-alb-sg → 80/443 허용
  instance_security_group_ids = [
    module.security.internal_web_sg_id
  ]

  asg_instance_type = local.asg_instance_type

  min_size         = local.asg_min_size
  desired_capacity = local.asg_desired_capacity
  max_size         = local.asg_max_size

  # ========================================================
  # CI/CD
  # ========================================================

  website_bucket = module.storage.website_bucket

  ecr_registry         = local.ecr_registry
  ecr_repository_names = local.ecr_repository_names

  depends_on = [
    module.network,
    module.security,
    module.storage,
    module.endpoints
  ]
}
# ========================================================
# 5. EKS
# ========================================================

module "eks" {
  source = "./modules/eks"

  cluster_name = local.cluster_name
  tag_header   = local.tag_header

  # EKS Control Plane에서 사용할 Cluster Subnet
  cluster_subnet_ids = module.network.cluster_subnet_ids

  # Worker Node도 Cluster Subnet에 생성
  node_subnet_ids = module.network.cluster_subnet_ids

  cluster_security_group_id = module.security.cluster_sg_id
  node_security_group_id    = module.security.eks_node_sg_id

  node_instance_type = local.eks_node_instance_type

  min_size     = local.eks_node_min_size
  desired_size = local.eks_node_desired_size
  max_size     = local.eks_node_max_size

  depends_on = [
    module.network,
    module.security,
    module.endpoints
  ]
}
