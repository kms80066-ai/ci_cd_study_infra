output "vpc_id" {
  value = module.network.vpc_id
}

output "subnet_ids" {
  value = module.network.subnet_ids
}

output "instance_public_ip" {
  value = module.compute.public_ip
}

output "efs_id" {
  value = module.storage.efs_id
}

output "website_url" {
  value = module.storage.website_url
}

output "logs_bucket" {
  value = module.storage.logs_bucket
}


# ========================================================
# 4. Auto Scaling
# ========================================================

output "docker_ami_id" {
  value = module.autoscaling.docker_ami_id
}

output "docker_ami_name" {
  value = module.autoscaling.docker_ami_name
}

output "ami_builder_instance_id" {
  value = module.autoscaling.builder_instance_id
}

output "asg_name" {
  value = module.autoscaling.asg_name
}

output "asg_alb_dns_name" {
  value = module.autoscaling.alb_dns_name
}

output "ecr_repository_urls" {
  value = module.autoscaling.ecr_repository_urls
}
# ========================================================
# 5. EKS
# ========================================================

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "eks_cluster_version" {
  value = module.eks.cluster_version
}

output "eks_node_group_name" {
  value = module.eks.node_group_name
}

output "eks_update_kubeconfig_command" {
  value = "aws eks update-kubeconfig --region ${local.region} --name ${module.eks.cluster_name}"
}
