# S3 Gateway Endpoint
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = local.vpc_id
  service_name      = local.s3_service_name
  vpc_endpoint_type = "Gateway"
  route_table_ids   = local.non_public_route_table_ids

  tags = {
    Name = "${local.tag_header}s3-endpoint"
  }
}

# ECR API / DKR Interface Endpoint
# 같은 Interface Endpoint에 같은 AZ의 서브넷을 두 개 넣을 수 없으므로
# Private Subnet 3개에 ENI를 만들고 Private DNS를 사용합니다.
resource "aws_vpc_endpoint" "ecr" {
  for_each = local.ecr_services

  vpc_id              = local.vpc_id
  service_name        = "com.amazonaws.${local.region}.${each.key}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = local.private_subnet_ids
  security_group_ids  = [local.endpoint_sg_id]
  private_dns_enabled = true

  tags = {
    Name = "${local.tag_header}${each.key}-endpoint"
  }
}
