# ========================================================
# 3. Public Route Table - 1개
# Public Subnet 3개가 함께 사용
# ========================================================
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${local.tag_header}public-rt"
  }
}

resource "aws_route_table_association" "public" {
  for_each = local.public_subnets

  subnet_id      = aws_subnet.this[each.key].id
  route_table_id = aws_route_table.public.id
}

# ========================================================
# 4. Private Route Table - AZ별 3개
# 각 Private Subnet이 자신의 AZ Route Table 사용
# ========================================================
resource "aws_route_table" "private" {
  for_each = toset(local.azs)

  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = {
    Name = "${local.tag_header}private-${each.key}-rt"
  }
}

resource "aws_route_table_association" "private" {
  for_each = local.private_subnets

  subnet_id      = aws_subnet.this[each.key].id
  route_table_id = aws_route_table.private[each.value.az].id
}

# ========================================================
# 5. Cluster Route Table - 1개
# Cluster Subnet 3개가 함께 사용
# ========================================================
resource "aws_route_table" "cluster" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = {
    Name = "${local.tag_header}cluster-rt"
  }
}

resource "aws_route_table_association" "cluster" {
  for_each = local.cluster_subnets

  subnet_id      = aws_subnet.this[each.key].id
  route_table_id = aws_route_table.cluster.id
}
