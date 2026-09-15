# Security Group 자체와 Ingress Rule을 분리해서 관리합니다.
resource "aws_security_group" "this" {
  for_each = local.groups

  name        = "${local.tag_header}${each.key}-sg"
  description = "CI CD lab ${each.key}"
  vpc_id      = local.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.tag_header}${each.key}-sg"
  }
}

# Public SSH
resource "aws_security_group_rule" "public_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.this["ssh"].id
}

# Public SSH SG -> Internal SSH SG
resource "aws_security_group_rule" "internal_ssh" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.this["ssh"].id
  security_group_id        = aws_security_group.this["internal-ssh"].id
}

# 외부 Web: 80 / 443
resource "aws_security_group_rule" "external_web" {
  for_each = local.web_ports

  type              = "ingress"
  from_port         = tonumber(each.key)
  to_port           = tonumber(each.key)
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.this["external-alb"].id
}

# External ALB -> Internal ALB: 80 / 443
resource "aws_security_group_rule" "internal_web" {
  for_each = local.web_ports

  type                     = "ingress"
  from_port                = tonumber(each.key)
  to_port                  = tonumber(each.key)
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.this["external-alb"].id
  security_group_id        = aws_security_group.this["internal-alb"].id
}

resource "aws_security_group_rule" "internal_8000" {
  type              = "ingress"
  from_port         = 8000
  to_port           = 8000
  protocol          = "tcp"
  cidr_blocks       = [local.vpc_cidr]
  security_group_id = aws_security_group.this["internal-alb"].id
}

# Interface Endpoint HTTPS
resource "aws_security_group_rule" "endpoint_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = local.non_public_cidrs
  security_group_id = aws_security_group.this["endpoint"].id
}

# EFS NFS
resource "aws_security_group_rule" "efs_nfs" {
  for_each = local.efs_source_groups

  type                     = "ingress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.this[each.key].id
  security_group_id        = aws_security_group.this["efs"].id
}

# External ALB -> EKS Node
resource "aws_security_group_rule" "node_from_alb" {
  for_each = local.web_ports

  type                     = "ingress"
  from_port                = tonumber(each.key)
  to_port                  = tonumber(each.key)
  protocol                 = "tcp"
  security_group_id        = aws_security_group.this["eks-node"].id
  source_security_group_id = aws_security_group.this["external-alb"].id
}

# EKS Cluster -> Node: kubelet
resource "aws_security_group_rule" "node_from_cluster" {
  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  security_group_id        = aws_security_group.this["eks-node"].id
  source_security_group_id = aws_security_group.this["cluster"].id
}

# 같은 Node SG를 사용하는 노드끼리 전체 통신
resource "aws_security_group_rule" "node_self" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  self              = true
  security_group_id = aws_security_group.this["eks-node"].id
}

# EKS Node -> Cluster: Kubernetes API
resource "aws_security_group_rule" "cluster_from_node" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.this["cluster"].id
  source_security_group_id = aws_security_group.this["eks-node"].id
}

# PDF의 외부 API 접근 규칙
resource "aws_security_group_rule" "cluster_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.this["cluster"].id
}
