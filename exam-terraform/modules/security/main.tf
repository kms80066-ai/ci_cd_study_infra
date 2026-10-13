# SG와 인바운드 룰을 분리해서 관리
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

# Internet -> ALB: 현재 HTTP Listener는 80만 설정.
# HTTPS 443 인바운드는 나중에 인증서/443 Listener 연결용.
resource "aws_vpc_security_group_ingress_rule" "alb_web" {
  for_each          = local.web_ports
  security_group_id = aws_security_group.this["alb"].id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = each.value
  to_port           = each.value
}

# ALB -> ASG EC2: HTTP/HTTPS. ALB 이외에서는 직접 웹 접속 차단.
resource "aws_vpc_security_group_ingress_rule" "web_from_alb" {
  for_each                     = local.web_ports
  security_group_id            = aws_security_group.this["web"].id
  referenced_security_group_id = aws_security_group.this["alb"].id
  ip_protocol                  = "tcp"
  from_port                    = each.value
  to_port                      = each.value
}

# Public jumpbox SSH: 기본 VPC CIDR만 허용. 외부 Ubuntu에서 SSH하려면 로컬 설정을 내 공인IP/32로 변경.
# SSH 포트만 공인IP /32로 열고 HTTP/HTTPS는 내부망에서만 접근.
resource "aws_vpc_security_group_ingress_rule" "jumpbox_ssh" {
  security_group_id = aws_security_group.this["jumpbox"].id
  cidr_ipv4         = local.ssh_allowed_cidr
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "jumpbox_web" {
  for_each          = local.web_ports
  security_group_id = aws_security_group.this["jumpbox"].id
  cidr_ipv4         = local.vpc_cidr
  ip_protocol       = "tcp"
  from_port         = each.value
  to_port           = each.value
}

# Jumpbox -> Private web EC2 SSH
resource "aws_vpc_security_group_ingress_rule" "web_from_jumpbox_ssh" {
  security_group_id            = aws_security_group.this["web"].id
  referenced_security_group_id = aws_security_group.this["jumpbox"].id
  ip_protocol                  = "tcp"
  from_port                    = 22
  to_port                      = 22
}

# Jumpbox -> EKS worker SSH
resource "aws_vpc_security_group_ingress_rule" "node_from_jumpbox_ssh" {
  security_group_id            = aws_security_group.this["eks-node"].id
  referenced_security_group_id = aws_security_group.this["jumpbox"].id
  ip_protocol                  = "tcp"
  from_port                    = 22
  to_port                      = 22
}

# EKS 노드 HTTP/HTTPS: VPC 내 접근만 허용 (아직 EKS용 ALB/Ingress 미배포)
resource "aws_vpc_security_group_ingress_rule" "eks_node_web" {
  for_each          = local.web_ports
  security_group_id = aws_security_group.this["eks-node"].id
  cidr_ipv4         = local.vpc_cidr
  ip_protocol       = "tcp"
  from_port         = each.value
  to_port           = each.value
}

# 이전 EKS 실습의 노드 간 통신(self-all) 규칙을 새 모듈에도 반영
resource "aws_vpc_security_group_ingress_rule" "eks_node_self" {
  security_group_id            = aws_security_group.this["eks-node"].id
  referenced_security_group_id = aws_security_group.this["eks-node"].id
  ip_protocol                  = "-1"
}

# EKS control-plane -> kubelet 10250 은 EKS 모듈에서 클러스터 SG를 참조하여 생성

# MySQL: DB 인바운드는 3306만, web 및 jumpbox에서 접근 허용.
# DB 자체에는 SSH/HTTP/HTTPS를 열지 않음.
resource "aws_vpc_security_group_ingress_rule" "db_mysql" {
  for_each                     = toset(["web", "jumpbox"])
  security_group_id            = aws_security_group.this["db"].id
  referenced_security_group_id = aws_security_group.this[each.key].id
  ip_protocol                  = "tcp"
  from_port                    = 3306
  to_port                      = 3306
}
