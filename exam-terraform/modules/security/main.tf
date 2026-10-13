resource "aws_security_group" "this" {
  for_each    = local.group_names
  name        = "${local.name_prefix}-${each.key}-sg"
  description = "Terraform exam ${each.key}"
  vpc_id      = local.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.name_prefix}-${each.key}-sg" }
}

# Internet -> ALB (80)
resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.this["alb"].id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

# ALB -> EC2 Docker nginx (80)
resource "aws_vpc_security_group_ingress_rule" "web_http" {
  security_group_id            = aws_security_group.this["web"].id
  referenced_security_group_id = aws_security_group.this["alb"].id
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
}

# Future DB access only from web security group. No public MySQL ingress.
resource "aws_vpc_security_group_ingress_rule" "db_mysql" {
  security_group_id            = aws_security_group.this["db"].id
  referenced_security_group_id = aws_security_group.this["web"].id
  ip_protocol                  = "tcp"
  from_port                    = 3306
  to_port                      = 3306
}

