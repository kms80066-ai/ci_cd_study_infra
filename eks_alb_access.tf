# ========================================================
# nginx ALB -> EKS Worker Node / Pod
#
# ALB에서 nginx Pod로 전달되는 HTTP 80 허용
# EKS 기본 Cluster SG를 대상으로 설정
# ========================================================

resource "aws_vpc_security_group_ingress_rule" "nginx_alb_to_eks" {

  security_group_id = local.eks_cluster_security_group_id

  referenced_security_group_id = local.nginx_alb_security_group_id

  ip_protocol = "tcp"

  from_port = local.nginx_backend_port
  to_port   = local.nginx_backend_port

  description = "Allow nginx ALB to access EKS nginx pods"

  tags = {
    Name = "${local.tag_header}nginx-alb-to-eks"
  }
}
