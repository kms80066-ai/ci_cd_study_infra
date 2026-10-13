output "vpc_id" {
  value = module.network.vpc_id
}

output "subnet_ids" {
  value = module.network.subnet_ids
}

output "alb_url" {
  description = "이 주소로 Docker Nginx의 응답을 확인"
  value       = "http://${module.web.alb_dns_name}"
}

output "asg_name" {
  value = module.web.asg_name
}

output "rds_endpoint" {
  value = module.rds.db_endpoint
}

output "rds_master_secret_arn" {
  description = "RDS가 관리하는 Secrets Manager 비밀번호 ARN (비밀번호 자체 아님)"
  value       = module.rds.master_secret_arn
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "jumpbox_public_ip" {
  value = module.jumpbox.public_ip
}
output "jumpbox_public_dns" {
  value = module.jumpbox.public_dns
}
output "eks_node_group_name" {
  value = module.eks.node_group_name
}
