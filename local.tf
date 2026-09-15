locals {
  # ========================================================
  # 이 프로젝트에서 직접 바꿀 기본 설정
  # ========================================================
  owner      = "std09"
  key_name   = "std09-keypair"
  region     = "ca-central-1"
  azs        = ["ca-central-1a", "ca-central-1b", "ca-central-1d"]
  vpc_cidr   = "10.0.0.0/16"
  tag_header = "${local.owner}-"

  cluster_name = "${local.owner}-eks-cluster"

  # 테스트 EC2
  test_ec2_subnet_key = "public1a"


  # ========================================================
  # 4. Auto Scaling Group
  # ========================================================

  asg_name = "${local.tag_header}cicd-asg"

  # AMI 제작용 EC2
  ami_builder_name          = "${local.tag_header}docker-ami-builder"
  ami_builder_subnet_key    = "private1a"
  ami_builder_instance_type = "t3.micro"

  # 실제 ASG EC2
  # nginx + FastAPI 2개 컨테이너 실습이므로 t3.micro 사용
  asg_instance_type = "t3.micro"

  asg_min_size         = 1
  asg_desired_capacity = 1
  asg_max_size         = 2

  # GitHub Actions에서 사용하는 ECR Repository
  ecr_repository_names = toset([
    "${local.owner}/nginx",
    "${local.owner}/fastapi"
  ])


  # ========================================================
  # AWS 조회 결과
  # ========================================================

  account_id = data.aws_caller_identity.current.account_id

  bucket_prefix = "bipa17-${local.owner}-cicd-${local.account_id}-${local.region}"

  ecr_registry = "${local.account_id}.dkr.ecr.${local.region}.amazonaws.com"


  # ========================================================
  # Subnet 9개
  # ========================================================

  subnet_map = merge([
    for idx, kind in ["public", "private", "cluster"] : {
      for i, az in local.azs : "${kind}${split("-", az)[2]}" => {
        type = kind
        az   = az
        cidr = cidrsubnet(local.vpc_cidr, 8, i + idx * 10 + 1)
      }
    }
  ]...)

  non_public_cidrs = [
    for subnet in local.subnet_map : subnet.cidr
    if subnet.type != "public"
  ]
  # ========================================================
  # 5. EKS
  # ========================================================

  eks_node_instance_type = "t3.small"

  eks_node_min_size     = 1
  eks_node_desired_size = 1
  eks_node_max_size     = 2
}
