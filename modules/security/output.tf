output "ssh_sg_id" { value = aws_security_group.this["ssh"].id }
output "internal_ssh_sg_id" { value = aws_security_group.this["internal-ssh"].id }
output "external_alb_sg_id" { value = aws_security_group.this["external-alb"].id }
output "internal_web_sg_id" { value = aws_security_group.this["internal-alb"].id }
output "endpoint_sg_id" { value = aws_security_group.this["endpoint"].id }
output "efs_sg_id" { value = aws_security_group.this["efs"].id }
output "cluster_sg_id" {
  value = aws_security_group.this["cluster"].id
}

output "eks_node_sg_id" {
  value = aws_security_group.this["eks-node"].id
}
