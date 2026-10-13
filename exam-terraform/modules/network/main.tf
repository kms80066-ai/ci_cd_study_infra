resource "aws_vpc" "this" {
  cidr_block           = local.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "${local.name_prefix}-vpc" }
}

resource "aws_subnet" "this" {
  for_each = local.subnet_map

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = each.value.kind == "public"

  tags = merge(
    { Name = "${local.name_prefix}-${each.key}", Tier = each.value.kind },
    each.value.kind == "public" ? { "kubernetes.io/role/elb" = "1" } : {},
    each.value.kind == "cluster" ? { "kubernetes.io/role/internal-elb" = "1" } : {},
    each.value.kind != "private" ? { "kubernetes.io/cluster/${local.cluster_name}" = "shared" } : {}
  )
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${local.name_prefix}-igw" }
}

# 교육/실습용: NAT Gateway 1개를 모든 private 계열에서 공유
resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = { Name = "${local.name_prefix}-nat-eip" }
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.this["public_a"].id
  depends_on    = [aws_internet_gateway.this]
  tags          = { Name = "${local.name_prefix}-nat" }
}

# Route table 3개: Public 1, Private 1, Cluster 1
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
  tags = { Name = "${local.name_prefix}-public-rt" }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }
  tags = { Name = "${local.name_prefix}-private-rt" }
}

resource "aws_route_table" "cluster" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }
  tags = { Name = "${local.name_prefix}-cluster-rt" }
}

resource "aws_route_table_association" "public" {
  for_each       = local.public_subnets
  subnet_id      = aws_subnet.this[each.key].id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "private" {
  for_each       = local.private_subnets
  subnet_id      = aws_subnet.this[each.key].id
  route_table_id = aws_route_table.private.id
}
resource "aws_route_table_association" "cluster" {
  for_each       = local.cluster_subnets
  subnet_id      = aws_subnet.this[each.key].id
  route_table_id = aws_route_table.cluster.id
}

