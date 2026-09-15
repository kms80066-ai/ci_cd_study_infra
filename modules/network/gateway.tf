# ========================================================
# 1. Internet Gateway
# ========================================================
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${local.tag_header}igw"
  }
}

# ========================================================
# 2. NAT Gateway + EIP
# ========================================================
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${local.tag_header}nat-eip"
  }
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.this[local.nat_subnet_key].id
  depends_on    = [aws_internet_gateway.this]

  tags = {
    Name = "${local.tag_header}nat-gw"
  }
}
