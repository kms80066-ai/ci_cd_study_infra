locals {
  # variable.tf로 들어온 값은 이 파일에서 한 번만 local 이름으로 받습니다.
  # 아래 실제 리소스 파일에서는 local.xxx를 사용합니다.
  vpc_cidr     = var.vpc_cidr
  tag_header   = var.tag_header
  azs          = var.azs
  subnet_map   = var.subnet_map
  cluster_name = var.cluster_name

  public_subnets = {
    for key, subnet in local.subnet_map : key => subnet
    if subnet.type == "public"
  }

  private_subnets = {
    for key, subnet in local.subnet_map : key => subnet
    if subnet.type == "private"
  }

  cluster_subnets = {
    for key, subnet in local.subnet_map : key => subnet
    if subnet.type == "cluster"
  }

  # NAT Gateway는 첫 번째 AZ의 Public Subnet에 배치
  nat_subnet_key = "public${split("-", local.azs[0])[2]}"
}
