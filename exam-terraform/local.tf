# 모든 기본 설정은 이 파일에서 관리 (local-first 방식)
locals {
  owner       = "std09"
  region      = "ca-central-1"
  tag_header  = "${local.owner}-exam"
  azs         = ["ca-central-1a", "ca-central-1b"]
  vpc_cidr    = "10.90.0.0/16"

  # Public 2 + Private 2 + Cluster Private 2 = 6개 서브넷
  subnet_map = {
    public_a  = { kind = "public",  az = local.azs[0], cidr = "10.90.1.0/24"  }
    public_b  = { kind = "public",  az = local.azs[1], cidr = "10.90.2.0/24"  }
    private_a = { kind = "private", az = local.azs[0], cidr = "10.90.11.0/24" }
    private_b = { kind = "private", az = local.azs[1], cidr = "10.90.12.0/24" }
    cluster_a = { kind = "cluster", az = local.azs[0], cidr = "10.90.21.0/24" }
    cluster_b = { kind = "cluster", az = local.azs[1], cidr = "10.90.22.0/24" }
  }

  # Nginx용 ASG: Amazon Linux 2023 + Docker + t3.micro + 10GiB
  web_instance_type = "t3.micro"
  web_volume_size   = 10
  web_min_size      = 1
  web_desired_size  = 1
  web_max_size      = 2

  # MySQL: DB 인스턴스만 생성, FastAPI/테이블/데이터 작업 없음
  db_instance_class = "db.t3.micro"
  db_name           = "studydb"
  db_username       = "admin"

  # EKS는 Nginx ASG와 별도로 생성
  eks_cluster_name = "${local.tag_header}-eks"
  eks_node_type    = "t3.small"
  eks_node_min     = 1
  eks_node_desired = 1
  eks_node_max     = 2
}

